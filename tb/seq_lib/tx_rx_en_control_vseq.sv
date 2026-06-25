class tx_rx_en_control_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(tx_rx_en_control_vseq)

    function new(string name = "tx_rx_en_control_vseq");
        super.new(name);
    endfunction

    task automatic check_dummy_mosi_frame();
        wait (cfg.spi_cfg.vif.spi_cs_n === 1'b0);
        repeat (8) begin
            @(posedge cfg.spi_cfg.vif.spi_sclk);
            if (cfg.spi_cfg.vif.spi_mosi !== 1'b0) begin
                `uvm_error(get_type_name(), "MOSI was not zero during dummy transmit frame")
            end
        end
    endtask

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;

        set_clkdiv(8'd1);

        // {tx_en, rx_en}=2'b11: normal full-duplex transfer.
        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        rsp_q.push_back(8'h5a);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'ha5);
        start_transfer();
        wait_for_done();
        pop_rx_byte(rx_byte);
        if (rx_byte !== 8'h5a) begin
            `uvm_error(get_type_name(),
                       $sformatf("Full-duplex RX mismatch exp=0x5a act=0x%02h", rx_byte))
        end
        check_reg_value("RXFIFO empty after full-duplex pop", ral().rxfifo_lvl, 32'h0);
        clear_irq(5'b1_1001);

        // {tx_en, rx_en}=2'b01: send one dummy 0x00 frame and receive data.
        // cont=1 must not auto-continue in receive-only mode.
        cfg_spi_mode(1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1);
        rsp_q.delete();
        rsp_q.push_back(8'hc3);
        start_spi_responses_async(rsp_q, 1'b1, 1'b0, 1'b1);
        fork
            check_dummy_mosi_frame();
            start_transfer();
        join
        wait_for_cs_release();
        wait_for_rx_level(1);
        check_reg_value("TXFIFO remains empty in receive-only mode", ral().txfifo_lvl, 32'h0);
        check_reg_value("RXFIFO has one receive-only byte", ral().rxfifo_lvl, 32'h1);
        pop_rx_byte(rx_byte);
        if (rx_byte !== 8'hc3) begin
            `uvm_error(get_type_name(),
                       $sformatf("Receive-only RX mismatch exp=0xc3 act=0x%02h", rx_byte))
        end
        clear_irq(5'b1_1001);

        // {tx_en, rx_en}=2'b10: transmit normally without writing RX FIFO.
        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1);
        push_tx_byte(8'h3c);
        start_transfer();
        wait_for_done();
        check_reg_value("RXFIFO remains empty in transmit-only mode", ral().rxfifo_lvl, 32'h0);
        check_reg_value("TXFIFO drains in transmit-only mode", ral().txfifo_lvl, 32'h0);
        clear_irq(5'b1_1001);

        // {tx_en, rx_en}=2'b00: start is ignored without underflow or SPI activity.
        cfg_spi_mode(1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
        start_transfer();
        repeat (16) begin
            @(posedge cfg.apb_cfg.vif.pclk);
            if (cfg.spi_cfg.vif.spi_cs_n !== 1'b1) begin
                `uvm_error(get_type_name(), "CS asserted while both tx_en and rx_en were disabled")
            end
        end
        check_reg_bits("STATUS after disabled TX/RX start", ral().status,
                       (32'd1 << STATUS_BUSY_BIT) |
                       (32'd1 << STATUS_CS_ACTIVE_BIT) |
                       (32'd1 << STATUS_DONE_PENDING_BIT) |
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT) |
                       (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT),
                       '0);
        check_reg_bits("IRQ_RAW after disabled TX/RX start", ral().irq_raw,
                       (32'd1 << IRQ_DONE_BIT) |
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT) |
                       (32'd1 << IRQ_RX_OVERFLOW_BIT),
                       '0);
        check_reg_value("TXFIFO empty with TX/RX disabled", ral().txfifo_lvl, 32'h0);
        check_reg_value("RXFIFO empty with TX/RX disabled", ral().rxfifo_lvl, 32'h0);
    endtask
endclass
