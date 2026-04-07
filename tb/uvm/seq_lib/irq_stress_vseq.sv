class irq_stress_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(irq_stress_vseq)

    function new(string name = "irq_stress_vseq");
        super.new(name);
    endfunction

    task automatic fill_rx_fifo_to_full();
        byte unsigned rsp_q[$];
        int unsigned  max_pclk_cycles;
        bit [31:0]    saved_ctrl;

        rsp_q.delete();
        for (int idx = 0; idx < 8; idx++) begin
            rsp_q.push_back(byte'(8'h50 + idx));
            push_tx_byte(byte'(8'ha0 + idx));
        end

        saved_ctrl = ctrl_mirror;
        ctrl_mirror[CTRL_CONT_BIT] = 1'b1;
        write_reg(ral().ctrl, ctrl_mirror);

        start_spi_responses_async(rsp_q, 1'b1);
        max_pclk_cycles = (2 * 8 * 24) + 64;
        start_transfer();
        wait_for_transfer_idle(8, max_pclk_cycles);

        ctrl_mirror = saved_ctrl;
        write_reg(ral().ctrl, ctrl_mirror);
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
        int unsigned overflow_wait_cycles;

        sticky_mask = (32'd1 << IRQ_DONE_BIT) |
                      (32'd1 << IRQ_TX_UNDERFLOW_BIT) |
                      (32'd1 << IRQ_RX_OVERFLOW_BIT);
        level_mask  = (32'd1 << IRQ_TX_EMPTY_BIT) |
                      (32'd1 << IRQ_RX_NOT_EMPTY_BIT);
        all_irq_mask = sticky_mask | level_mask;
        overflow_wait_cycles = (2 * 24) + 64;

        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        set_clkdiv(8'd2);

        set_irq_enable(5'b0_0000);
        check_reg_value("IRQ_STATUS masked off at reset", ral().irq_status, 32'h0000_0000);
        check_reg_bits("IRQ_RAW reset level bit", ral().irq_raw, level_mask, (32'd1 << IRQ_TX_EMPTY_BIT));

        set_irq_enable(5'b0_0010);
        check_reg_bits("IRQ_STATUS tx_empty enable", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));

        clear_irq(5'b0_0010);
        check_reg_bits("Level clear does not clear tx_empty", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));
        check_reg_bits("Level clear does not clear masked tx_empty", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));

        push_tx_byte(8'h11);
        check_reg_bits("TX write removes tx_empty level", ral().irq_raw, all_irq_mask, '0);
        check_reg_bits("TX write removes masked tx_empty", ral().irq_status, all_irq_mask, '0);

        rsp_q.delete();
        rsp_q.push_back(8'h81);
        set_irq_enable(5'b1_1111);
        start_spi_responses_async(rsp_q);
        start_transfer();
        wait_for_done();

        check_reg_bits("Done transfer combined IRQ_RAW", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_DONE_BIT) |
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT));
        check_reg_bits("Done transfer combined IRQ_STATUS", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_DONE_BIT) |
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT));

        clear_irq(5'b0_0001);
        check_reg_bits("Clear sticky done only", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT));
        check_reg_bits("Done cleared from STATUS only", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT));

        set_irq_enable(5'b0_0100);
        check_reg_bits("Mask transition to rx_not_empty only", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT));

        drain_rx_fifo(1);
        check_reg_bits("RX pop drops rx_not_empty", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));
        check_reg_bits("RX pop masked status clears", ral().irq_status, all_irq_mask, '0);

        set_irq_enable(5'b1_1111);
        start_transfer();
        wait_for_done();
        check_reg_bits("Underflow sets sticky IRQ", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT));
        check_reg_bits("Underflow visible in masked status", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT));

        clear_irq(5'b0_1000);
        check_reg_bits("Underflow clear leaves level IRQ", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));

        fill_rx_fifo_to_full();
        check_reg_bits("Full RX after burst", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_DONE_BIT) |
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT));

        rsp_q.delete();
        rsp_q.push_back(8'hf1);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'h21);
        start_transfer();
        wait_for_transfer_idle(0, overflow_wait_cycles);

        check_reg_bits("Overflow plus existing level IRQs", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_DONE_BIT) |
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_OVERFLOW_BIT));
        check_reg_bits("Overflow pending in STATUS", ral().status,
                       (32'd1 << STATUS_DONE_PENDING_BIT) |
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT) |
                       (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT),
                       (32'd1 << STATUS_DONE_PENDING_BIT) |
                       (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT));

        set_irq_enable(5'b1_0000);
        check_reg_bits("Masked status selects overflow only", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_RX_OVERFLOW_BIT));

        clear_irq(5'b1_1001);
        check_reg_bits("Clear sticky overflow and done", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT));
        check_reg_bits("Masked status after sticky clear", ral().irq_status, all_irq_mask, '0);

        drain_rx_fifo(8);
        check_reg_bits("Drain RX leaves tx_empty only", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));

        set_irq_enable(5'b0_0010);
        check_reg_bits("tx_empty still level-high after RX drain", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));

        write_reg(ral().ctrl, ctrl_mirror | (32'd1 << CTRL_SOFT_RESET_BIT));
        check_reg_value("IRQ_EN preserved across soft reset", ral().irq_en, 32'h0000_0002);
        check_reg_bits("Soft reset clears sticky and RX-not-empty", ral().irq_raw, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));
        check_reg_bits("Soft reset masked status reflects preserved enable", ral().irq_status, all_irq_mask,
                       (32'd1 << IRQ_TX_EMPTY_BIT));
        check_reg_bits("Soft reset clears STATUS pending bits", ral().status,
                       (32'd1 << STATUS_DONE_PENDING_BIT) |
                       (32'd1 << STATUS_TX_UNDERFLOW_PENDING_BIT) |
                       (32'd1 << STATUS_RX_OVERFLOW_PENDING_BIT),
                       '0);
    endtask
endclass
