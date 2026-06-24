class soft_reset_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(soft_reset_vseq)

    function new(string name = "soft_reset_vseq");
        super.new(name);
    endfunction

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;

        cfg_spi_mode(1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd8);
        set_irq_enable(5'b1_1111);

        start_transfer();
        wait_for_done();
        check_reg_bits("Underflow before soft reset", ral().irq_raw,
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT),
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT));

        rsp_q.delete();
        rsp_q.push_back(8'h41);
        start_spi_responses_async(rsp_q, 1'b1);
        push_tx_byte(8'hc1);
        push_tx_byte(8'hc2);
        push_tx_byte(8'hc3);
        start_transfer();

        wait (cfg.spi_cfg.vif.spi_cs_n === 1'b0);
        @(cfg.spi_cfg.vif.spi_sclk);
        write_reg(ral().ctrl, ctrl_mirror | (32'd1 << CTRL_SOFT_RESET_BIT));
        @(posedge cfg.apb_cfg.vif.pclk);

        check_reg_value("CTRL preserves programmed mode after soft reset", ral().ctrl, ctrl_mirror);
        check_reg_value("TXFIFO cleared by soft reset", ral().txfifo_lvl, 32'h0000_0000);
        check_reg_value("RXFIFO cleared by soft reset", ral().rxfifo_lvl, 32'h0000_0000);
        check_reg_bits("STATUS cleared by soft reset", ral().status,
                       (32'd1 << STATUS_BUSY_BIT) |
                       (32'd1 << STATUS_TX_EMPTY_BIT) |
                       (32'd1 << STATUS_RX_EMPTY_BIT) |
                       (32'd1 << STATUS_CS_ACTIVE_BIT) |
                       (32'd1 << STATUS_DONE_PENDING_BIT) |
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT) |
                       (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT),
                       (32'd1 << STATUS_TX_EMPTY_BIT) |
                       (32'd1 << STATUS_RX_EMPTY_BIT));
        check_reg_bits("IRQ raw cleared by soft reset", ral().irq_raw,
                       (32'd1 << IRQ_DONE_BIT) |
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT) |
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT) |
                       (32'd1 << IRQ_RX_OVERFLOW_BIT),
                       (32'd1 << IRQ_TX_EMPTY_BIT));

        if (cfg.spi_cfg.vif.spi_cs_n !== 1'b1) begin
            `uvm_error(get_type_name(), "CS remained asserted after soft reset")
        end

        rsp_q.delete();
        rsp_q.push_back(8'h5c);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'h3c);
        start_transfer();
        wait_for_done();
        pop_rx_byte(rx_byte);
        if (rx_byte !== 8'h5c) begin
            `uvm_error(get_type_name(),
                       $sformatf("Post-soft-reset transfer mismatch exp=0x5c act=0x%02h", rx_byte))
        end

        clear_irq(5'b1_1101);
    endtask
endclass
