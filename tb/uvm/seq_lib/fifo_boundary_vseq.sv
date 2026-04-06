class fifo_boundary_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(fifo_boundary_vseq)

    function new(string name = "fifo_boundary_vseq");
        super.new(name);
    endfunction

    task automatic check_reg(string reg_name, bit [11:0] addr, bit [31:0] exp_data);
        bit [31:0] act_data;

        apb_read_reg(addr, act_data);
        if (act_data !== exp_data) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s mismatch exp=0x%08h act=0x%08h", reg_name, exp_data, act_data))
        end
    endtask

    task automatic check_bits(string reg_name, bit [11:0] addr, bit [31:0] mask, bit [31:0] exp_masked);
        bit [31:0] act_data;

        apb_read_reg(addr, act_data);
        if ((act_data & mask) !== exp_masked) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s masked mismatch mask=0x%08h exp=0x%08h act=0x%08h",
                                 reg_name, mask, exp_masked, act_data & mask))
        end
    endtask

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;

        cfg_spi_mode(1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd1);
        set_irq_enable(5'b1_1111);

        for (int idx = 0; idx < 8; idx++) begin
            push_tx_byte(byte'(8'ha0 + idx));
        end
        check_reg("TXFIFO level full", REG_TXFIFO_LVL_ADDR, 32'h0000_0008);
        check_bits("STATUS tx full", REG_STATUS_ADDR,
                   (32'd1 << STATUS_TX_EMPTY_BIT) | (32'd1 << STATUS_TX_FULL_BIT),
                   (32'd1 << STATUS_TX_FULL_BIT));

        push_tx_byte(8'hff);
        check_reg("TXFIFO level saturates on overflow write", REG_TXFIFO_LVL_ADDR, 32'h0000_0008);

        rsp_q.delete();
        for (int idx = 0; idx < 8; idx++) begin
            rsp_q.push_back(byte'(8'h10 + idx));
        end
        start_spi_responses_async(rsp_q, 1'b1);
        start_transfer();
        wait_for_rx_level(8);

        check_reg("TXFIFO empty after drain", REG_TXFIFO_LVL_ADDR, 32'h0000_0000);
        check_reg("RXFIFO level full", REG_RXFIFO_LVL_ADDR, 32'h0000_0008);
        check_bits("STATUS rx full", REG_STATUS_ADDR,
                   (32'd1 << STATUS_RX_EMPTY_BIT) | (32'd1 << STATUS_RX_FULL_BIT),
                   (32'd1 << STATUS_RX_FULL_BIT));

        clear_irq(5'b0_0001);

        rsp_q.delete();
        rsp_q.push_back(8'hee);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'h5a);
        start_transfer();
        wait_for_done();

        check_reg("RXFIFO remains full after overflow", REG_RXFIFO_LVL_ADDR, 32'h0000_0008);
        check_bits("IRQ raw overflow", REG_IRQ_RAW_ADDR,
                   (32'd1 << IRQ_RX_OVERFLOW_BIT) | (32'd1 << IRQ_RX_NOT_EMPTY_BIT),
                   (32'd1 << IRQ_RX_OVERFLOW_BIT) | (32'd1 << IRQ_RX_NOT_EMPTY_BIT));
        check_bits("STATUS overflow pending", REG_STATUS_ADDR,
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

        check_reg("RXFIFO empty after drain", REG_RXFIFO_LVL_ADDR, 32'h0000_0000);
        clear_irq(5'b1_0001);

        start_transfer();
        wait_for_done();
        check_bits("IRQ raw underflow", REG_IRQ_RAW_ADDR,
                   (32'd1 << IRQ_TX_UNDERFLOW_BIT),
                   (32'd1 << IRQ_TX_UNDERFLOW_BIT));
        check_bits("STATUS underflow pending", REG_STATUS_ADDR,
                   (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT),
                   (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT));
        clear_irq(5'b0_1000);
    endtask
endclass
