class irq_stress_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(irq_stress_vseq)

    function new(string name = "irq_stress_vseq");
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

    task automatic check_masked(string reg_name, bit [11:0] addr, bit [31:0] mask, bit [31:0] exp_masked);
        bit [31:0] act_data;

        apb_read_reg(addr, act_data);
        if ((act_data & mask) !== exp_masked) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s masked mismatch mask=0x%08h exp=0x%08h act=0x%08h",
                                 reg_name, mask, exp_masked, act_data & mask))
        end
    endtask

    task automatic fill_rx_fifo_to_full();
        byte unsigned rsp_q[$];

        rsp_q.delete();
        for (int idx = 0; idx < 8; idx++) begin
            rsp_q.push_back(byte'(8'h50 + idx));
            push_tx_byte(byte'(8'ha0 + idx));
        end

        start_spi_responses_async(rsp_q, 1'b1);
        start_transfer();
        wait_for_rx_level(8);
        wait_for_done();
    endtask

    task automatic drain_rx_fifo(int unsigned count);
        byte unsigned rx_byte;

        repeat (count) begin
            pop_rx_byte(rx_byte);
        end
    endtask

    task body();
        byte unsigned rsp_q[$];
        bit [31:0]   sticky_mask;
        bit [31:0]   level_mask;
        bit [31:0]   all_irq_mask;

        sticky_mask = (32'd1 << IRQ_DONE_BIT) |
                      (32'd1 << IRQ_TX_UNDERFLOW_BIT) |
                      (32'd1 << IRQ_RX_OVERFLOW_BIT);
        level_mask  = (32'd1 << IRQ_TX_EMPTY_BIT) |
                      (32'd1 << IRQ_RX_NOT_EMPTY_BIT);
        all_irq_mask = sticky_mask | level_mask;

        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        set_clkdiv(8'd2);

        set_irq_enable(5'b0_0000);
        check_reg("IRQ_STATUS masked off at reset", REG_IRQ_STATUS_ADDR, 32'h0000_0000);
        check_masked("IRQ_RAW reset level bit", REG_IRQ_RAW_ADDR, level_mask, (32'd1 << IRQ_TX_EMPTY_BIT));

        set_irq_enable(5'b0_0010);
        check_masked("IRQ_STATUS tx_empty enable", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));

        clear_irq(5'b0_0010);
        check_masked("Level clear does not clear tx_empty", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));
        check_masked("Level clear does not clear masked tx_empty", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));

        push_tx_byte(8'h11);
        check_masked("TX write removes tx_empty level", REG_IRQ_RAW_ADDR, all_irq_mask, '0);
        check_masked("TX write removes masked tx_empty", REG_IRQ_STATUS_ADDR, all_irq_mask, '0);

        rsp_q.delete();
        rsp_q.push_back(8'h81);
        set_irq_enable(5'b1_1111);
        start_spi_responses_async(rsp_q);
        start_transfer();
        wait_for_done();

        check_masked("Done transfer combined IRQ_RAW", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_DONE_BIT) |
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_RX_NOT_EMPTY_BIT));
        check_masked("Done transfer combined IRQ_STATUS", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_DONE_BIT) |
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_RX_NOT_EMPTY_BIT));

        clear_irq(5'b0_0001);
        check_masked("Clear sticky done only", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_RX_NOT_EMPTY_BIT));
        check_masked("Done cleared from STATUS only", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_RX_NOT_EMPTY_BIT));

        set_irq_enable(5'b0_0100);
        check_masked("Mask transition to rx_not_empty only", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_RX_NOT_EMPTY_BIT));

        drain_rx_fifo(1);
        check_masked("RX pop drops rx_not_empty", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));
        check_masked("RX pop masked status clears", REG_IRQ_STATUS_ADDR, all_irq_mask, '0);

        set_irq_enable(5'b1_1111);
        start_transfer();
        wait_for_done();
        check_masked("Underflow sets sticky IRQ", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_TX_UNDERFLOW_BIT));
        check_masked("Underflow visible in masked status", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_TX_UNDERFLOW_BIT));

        clear_irq(5'b0_1000);
        check_masked("Underflow clear leaves level IRQ", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));

        fill_rx_fifo_to_full();
        check_masked("Full RX after burst", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_DONE_BIT) |
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_RX_NOT_EMPTY_BIT));

        rsp_q.delete();
        rsp_q.push_back(8'hf1);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'h21);
        start_transfer();
        wait_for_done();

        check_masked("Overflow plus existing level IRQs", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_DONE_BIT) |
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_RX_NOT_EMPTY_BIT) |
                     (32'd1 << IRQ_RX_OVERFLOW_BIT));
        check_masked("Overflow pending in STATUS", REG_STATUS_ADDR,
                     (32'd1 << STATUS_DONE_PENDING_BIT) |
                     (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT) |
                     (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT),
                     (32'd1 << STATUS_DONE_PENDING_BIT) |
                     (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT));

        set_irq_enable(5'b1_0000);
        check_masked("Masked status selects overflow only", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_RX_OVERFLOW_BIT));

        clear_irq(5'b1_1001);
        check_masked("Clear sticky overflow and done", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT) |
                     (32'd1 << IRQ_RX_NOT_EMPTY_BIT));
        check_masked("Masked status after sticky clear", REG_IRQ_STATUS_ADDR, all_irq_mask, '0);

        drain_rx_fifo(8);
        check_masked("Drain RX leaves tx_empty only", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));

        set_irq_enable(5'b0_0010);
        check_masked("tx_empty still level-high after RX drain", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));

        apb_write_reg(REG_CTRL_ADDR, ctrl_mirror | (32'd1 << CTRL_SOFT_RESET_BIT));
        check_reg("IRQ_EN preserved across soft reset", REG_IRQ_EN_ADDR, 32'h0000_0002);
        check_masked("Soft reset clears sticky and RX-not-empty", REG_IRQ_RAW_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));
        check_masked("Soft reset masked status reflects preserved enable", REG_IRQ_STATUS_ADDR, all_irq_mask,
                     (32'd1 << IRQ_TX_EMPTY_BIT));
        check_masked("Soft reset clears STATUS pending bits", REG_STATUS_ADDR,
                     (32'd1 << STATUS_DONE_PENDING_BIT) |
                     (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT) |
                     (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT),
                     '0);
    endtask
endclass
