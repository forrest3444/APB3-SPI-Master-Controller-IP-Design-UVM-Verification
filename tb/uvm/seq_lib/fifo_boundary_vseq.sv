class fifo_boundary_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(fifo_boundary_vseq)

    function new(string name = "fifo_boundary_vseq");
        super.new(name);
    endfunction

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;
        int unsigned  max_pclk_cycles;

        cfg_spi_mode(1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd1);
        set_irq_enable(5'b1_1111);

        for (int idx = 0; idx < 8; idx++) begin
            push_tx_byte(byte'(8'ha0 + idx));
        end
        check_reg_value("TXFIFO level full", ral().txfifo_lvl, 32'h0000_0008);
        check_reg_bits("STATUS tx full", ral().status,
                       (32'd1 << STATUS_TX_EMPTY_BIT) | (32'd1 << STATUS_TX_FULL_BIT),
                       (32'd1 << STATUS_TX_FULL_BIT));

        push_tx_byte(8'hff);
        check_reg_value("TXFIFO level saturates on overflow write", ral().txfifo_lvl, 32'h0000_0008);

        rsp_q.delete();
        for (int idx = 0; idx < 8; idx++) begin
            rsp_q.push_back(byte'(8'h10 + idx));
        end
        start_spi_responses_async(rsp_q, 1'b1);
        max_pclk_cycles = (8 * 24) + 64;
        start_transfer();
        wait_for_transfer_idle(8, max_pclk_cycles);

        check_reg_value("TXFIFO empty after drain", ral().txfifo_lvl, 32'h0000_0000);
        check_reg_value("RXFIFO level full", ral().rxfifo_lvl, 32'h0000_0008);
        check_reg_bits("STATUS rx full", ral().status,
                       (32'd1 << STATUS_RX_EMPTY_BIT) | (32'd1 << STATUS_RX_FULL_BIT),
                       (32'd1 << STATUS_RX_FULL_BIT));

        clear_irq(5'b0_0001);

        rsp_q.delete();
        rsp_q.push_back(8'hee);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'h5a);
        start_transfer();
        wait_for_done();

        check_reg_value("RXFIFO remains full after overflow", ral().rxfifo_lvl, 32'h0000_0008);
        check_reg_bits("IRQ raw overflow", ral().irq_raw,
                       (32'd1 << IRQ_RX_OVERFLOW_BIT) | (32'd1 << IRQ_RX_NOT_EMPTY_BIT),
                       (32'd1 << IRQ_RX_OVERFLOW_BIT) | (32'd1 << IRQ_RX_NOT_EMPTY_BIT));
        check_reg_bits("STATUS overflow pending", ral().status,
                       (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT),
                       (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT));

        for (int idx = 0; idx < 8; idx++) begin
            pop_rx_byte(rx_byte);
            if (rx_byte !== byte'(8'h10 + idx)) begin
                `uvm_error(get_type_name(),
                           $sformatf("RX FIFO order mismatch idx=%0d exp=0x%02h act=0x%02h",
                                     idx, byte'(8'h10 + idx), rx_byte))
            end
        end

        check_reg_value("RXFIFO empty after drain", ral().rxfifo_lvl, 32'h0000_0000);
        clear_irq(5'b1_0001);

        start_transfer();
        wait_for_done();
        check_reg_bits("IRQ raw underflow", ral().irq_raw,
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT),
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT));
        check_reg_bits("STATUS underflow pending", ral().status,
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT),
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT));
        clear_irq(5'b0_1000);
    endtask
endclass
