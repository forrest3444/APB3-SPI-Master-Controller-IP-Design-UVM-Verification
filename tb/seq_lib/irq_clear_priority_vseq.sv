class irq_clear_priority_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(irq_clear_priority_vseq)

    function new(string name = "irq_clear_priority_vseq");
        super.new(name);
    endfunction

    task automatic drive_idle_apb();
        cfg.apb_cfg.vif.psel    = 1'b0;
        cfg.apb_cfg.vif.penable = 1'b0;
        cfg.apb_cfg.vif.pwrite  = 1'b0;
        cfg.apb_cfg.vif.paddr   = '0;
        cfg.apb_cfg.vif.pwdata  = '0;
    endtask

    task automatic force_irq_event_bit(int unsigned irq_bit);
        cfg.apb_cfg.vif.force_irq_event(irq_bit == IRQ_DONE_BIT,
                                         irq_bit == IRQ_TX_UNDERFLOW_BIT,
                                         irq_bit == IRQ_RX_OVERFLOW_BIT);
    endtask

    task automatic direct_apb_write_with_forced_event(int unsigned irq_bit,
                                                      bit [4:0]  clear_mask);
 
        @(negedge cfg.apb_cfg.vif.pclk);
        cfg.apb_cfg.vif.psel    = 1'b1;
        cfg.apb_cfg.vif.penable = 1'b0;
        cfg.apb_cfg.vif.pwrite  = 1'b1;
        cfg.apb_cfg.vif.paddr   = REG_IRQ_CLEAR_ADDR;
        cfg.apb_cfg.vif.pwdata  = {27'h0, clear_mask};

        @(negedge cfg.apb_cfg.vif.pclk);
        cfg.apb_cfg.vif.penable = 1'b1;
        force_irq_event_bit(irq_bit);

        @(posedge cfg.apb_cfg.vif.pclk);
        @(negedge cfg.apb_cfg.vif.pclk);
        cfg.apb_cfg.vif.release_irq_event();
        drive_idle_apb();
        @(posedge cfg.apb_cfg.vif.pclk);
    endtask

    task automatic force_event_without_clear(int unsigned irq_bit);
        @(negedge cfg.apb_cfg.vif.pclk);
        force_irq_event_bit(irq_bit);

        @(posedge cfg.apb_cfg.vif.pclk);
        @(negedge cfg.apb_cfg.vif.pclk);
        cfg.apb_cfg.vif.release_irq_event();

        @(posedge cfg.apb_cfg.vif.pclk);
    endtask

    task automatic check_same_cycle_clear_wins(string     name,
                                               int unsigned irq_bit,
                                               int unsigned status_bit);
        bit [31:0] sticky_mask;

        sticky_mask = 32'd1 << irq_bit;

        write_reg(ral().irq_clear, 32'hffff_ffff);
        check_reg_bits({name, " cleared precondition"}, ral().irq_raw,
                       sticky_mask, '0);

        direct_apb_write_with_forced_event(irq_bit, sticky_mask[4:0]);
        check_reg_bits({name, " event+clear from zero leaves raw clear"}, ral().irq_raw,
                       sticky_mask, '0);
        check_reg_bits({name, " event+clear from zero leaves status clear"}, ral().status,
                       32'd1 << status_bit, '0);

        force_event_without_clear(irq_bit);
        check_reg_bits({name, " forced event sets raw"}, ral().irq_raw,
                       sticky_mask, sticky_mask);
        check_reg_bits({name, " forced event sets status pending"}, ral().status,
                       32'd1 << status_bit, 32'd1 << status_bit);

        direct_apb_write_with_forced_event(irq_bit, sticky_mask[4:0]);
        check_reg_bits({name, " event+clear from one clears raw"}, ral().irq_raw,
                       sticky_mask, '0);
        check_reg_bits({name, " event+clear from one clears status pending"}, ral().status,
                       32'd1 << status_bit, '0);
    endtask

    task body();
        bit [31:0] all_irq_mask;

        drive_idle_apb();
        write_reg(ral().ctrl, CTRL_RESET_VALUE | (32'd1 << CTRL_SOFT_RESET_BIT));
        set_irq_enable(5'b1_1111);

        all_irq_mask = (32'd1 << IRQ_DONE_BIT) |
                       (32'd1 << IRQ_TX_EMPTY_BIT) |
                       (32'd1 << IRQ_RX_NOT_EMPTY_BIT) |
                       (32'd1 << IRQ_TX_UNDERFLOW_BIT) |
                       (32'd1 << IRQ_RX_OVERFLOW_BIT);

        check_reg_bits("IRQ_CLEAR cannot clear tx_empty level raw", ral().irq_raw,
                       all_irq_mask, 32'd1 << IRQ_TX_EMPTY_BIT);
        clear_irq(5'b0_0010);
        check_reg_bits("Level IRQ clear has no effect on raw", ral().irq_raw,
                       all_irq_mask, 32'd1 << IRQ_TX_EMPTY_BIT);
        check_reg_bits("Level IRQ clear has no effect on masked status", ral().irq_status,
                       all_irq_mask, 32'd1 << IRQ_TX_EMPTY_BIT);

        check_same_cycle_clear_wins("done", IRQ_DONE_BIT, STATUS_DONE_PENDING_BIT);
        check_same_cycle_clear_wins("tx_underflow", IRQ_TX_UNDERFLOW_BIT,
                                    STATUS_TX_UNDERFLOW_PENDING_BIT);
        check_same_cycle_clear_wins("rx_overflow", IRQ_RX_OVERFLOW_BIT,
                                    STATUS_RX_OVERFLOW_PENDING_BIT);
    endtask
endclass
