class start_rejection_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(start_rejection_vseq)

    function new(string name = "start_rejection_vseq");
        super.new(name);
    endfunction

    task automatic check_no_cs_activity(string scenario, int unsigned cycles = 16);
        repeat (cycles) begin
            @(posedge cfg.apb_cfg.vif.pclk);
            if (cfg.spi_cfg.vif.spi_cs_n !== 1'b1) begin
                `uvm_error(get_type_name(),
                           $sformatf("CS asserted during rejected start: %s", scenario))
            end
        end
    endtask

    task automatic check_no_event(string scenario);
        check_reg_bits($sformatf("%s STATUS", scenario), ral().status,
                       (32'd1 << STATUS_BUSY_BIT) |
                       (32'd1 << STATUS_CS_ACTIVE_BIT) |
                       (32'd1 << STATUS_DONE_PENDING_BIT) |
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT) |
                       (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT),
                       '0);
        check_reg_bits($sformatf("%s IRQ_RAW", scenario), ral().irq_raw,
                       (32'd1 << IRQ_DONE_BIT) |
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT) |
                       (32'd1 << IRQ_RX_OVERFLOW_BIT),
                       '0);
    endtask

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;

        set_clkdiv(8'd4);

        // Disabled controller: start is ignored and the queued byte is retained.
        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0);
        push_tx_byte(8'ha5);
        start_transfer();
        check_no_cs_activity("enable=0");
        check_no_event("enable=0");
        check_reg_value("TXFIFO retained after disabled start", ral().txfifo_lvl, 32'h1);

        // The same queued byte starts normally once enable is set.
        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        rsp_q.push_back(8'h51);
        start_spi_responses_async(rsp_q);
        start_transfer();
        wait_for_done();
        pop_rx_byte(rx_byte);
        if (rx_byte !== 8'h51) begin
            `uvm_error(get_type_name(),
                       $sformatf("Accepted-start RX mismatch exp=0x51 act=0x%02h", rx_byte))
        end
        check_reg_value("TXFIFO drained after accepted start", ral().txfifo_lvl, 32'h0);
        clear_irq(5'b1_1001);

        // Empty TX FIFO with TX enabled: reject start and latch underflow.
        start_transfer();
        wait_for_done();
        if (cfg.spi_cfg.vif.spi_cs_n !== 1'b1) begin
            `uvm_error(get_type_name(), "CS asserted for TX-underflow start")
        end
        check_reg_bits("TX-empty start STATUS", ral().status,
                       (32'd1 << STATUS_BUSY_BIT) |
                       (32'd1 << STATUS_CS_ACTIVE_BIT) |
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT),
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT));
        check_reg_bits("TX-empty start IRQ_RAW", ral().irq_raw,
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT),
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT));
        clear_irq(5'b0_1000);

        // Both datapaths disabled: reject without underflow.
        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
        start_transfer();
        check_no_cs_activity("tx_en=0 rx_en=0");
        check_no_event("tx_en=0 rx_en=0");

        // A start issued during SHIFT is ignored; it must not consume the next
        // TX byte or create an extra frame.
        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        rsp_q.delete();
        rsp_q.push_back(8'h61);
        rsp_q.push_back(8'h62);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'hb1);
        push_tx_byte(8'hb2);
        start_transfer();
        wait_for_cs_assert();
        @(posedge cfg.spi_cfg.vif.spi_sclk);
        start_transfer();
        wait_for_cs_release();
        wait_for_rx_level(1);
        check_reg_value("Busy start does not consume next TX byte", ral().txfifo_lvl, 32'h1);
        pop_rx_byte(rx_byte);
        if (rx_byte !== 8'h61) begin
            `uvm_error(get_type_name(),
                       $sformatf("First busy-start RX mismatch exp=0x61 act=0x%02h", rx_byte))
        end
        clear_irq(5'b1_1001);

        start_transfer();
        wait_for_done();
        pop_rx_byte(rx_byte);
        if (rx_byte !== 8'h62) begin
            `uvm_error(get_type_name(),
                       $sformatf("Second busy-start RX mismatch exp=0x62 act=0x%02h", rx_byte))
        end
        check_reg_value("Second TX byte drains only after idle start", ral().txfifo_lvl, 32'h0);
        clear_irq(5'b1_1001);

        // Simultaneous start and software reset: reset wins and no frame starts.
        push_tx_byte(8'hc7);
        bus_write_reg(ral().ctrl,
                      ctrl_mirror |
                      (32'd1 << CTRL_START_BIT) |
                      (32'd1 << CTRL_SOFT_RESET_BIT));
        check_no_cs_activity("start plus soft_reset");
        check_no_event("start plus soft_reset");
        check_reg_value("TXFIFO cleared by reset-priority command", ral().txfifo_lvl, 32'h0);
        check_reg_value("RXFIFO cleared by reset-priority command", ral().rxfifo_lvl, 32'h0);
    endtask
endclass
