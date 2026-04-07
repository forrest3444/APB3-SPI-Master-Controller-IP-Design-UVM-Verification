class apb_reg_access_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(apb_reg_access_vseq)

    function new(string name = "apb_reg_access_vseq");
        super.new(name);
    endfunction

    task automatic check_read(string reg_name, uvm_reg rg, bit [31:0] exp_data);
        check_reg_value(reg_name, rg, exp_data);
    endtask

    task automatic check_bus_read(string reg_name, uvm_reg rg, bit [31:0] exp_data);
        bit [31:0] act_data;

        bus_read_reg(rg, act_data);
        if (act_data !== exp_data) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s mismatch exp=0x%08h act=0x%08h",
                                 reg_name, exp_data, act_data))
        end
    endtask

    task automatic check_ignored_write(string reg_name, uvm_reg rg, bit [31:0] wr_data, bit [31:0] exp_data);
        bus_write_reg(rg, wr_data);
        check_read(reg_name, rg, exp_data);
    endtask

    task body();
        byte unsigned rsp_q[$];
        bit [31:0]   status_before_write;

        check_read("CTRL reset", ral().ctrl, CTRL_RESET_VALUE);
        check_read("STATUS reset", ral().status, 32'h0000_000a);
        check_read("CLKDIV reset", ral().clkdiv, 32'h0000_0001);
        check_bus_read("TXDATA read-as-zero", ral().txdata, 32'h0000_0000);
        check_read("RXDATA empty", ral().rxdata, 32'h0000_0000);
        check_read("IRQ_EN reset", ral().irq_en, 32'h0000_0000);
        check_read("IRQ_RAW reset", ral().irq_raw, 32'h0000_0002);
        check_read("IRQ_STATUS reset", ral().irq_status, 32'h0000_0000);
        check_bus_read("IRQ_CLEAR read-as-zero", ral().irq_clear, 32'h0000_0000);
        check_read("TXFIFO_LVL reset", ral().txfifo_lvl, 32'h0000_0000);
        check_read("RXFIFO_LVL reset", ral().rxfifo_lvl, 32'h0000_0000);
        check_read("VERSION reset", ral().version, VERSION_RESET_VALUE);

        write_reg(ral().ctrl, 32'hffff_ffff);
        check_read("CTRL RW/WO/reserved", ral().ctrl, 32'h0000_007d);

        write_reg(ral().ctrl, 32'h0000_0000);
        check_read("CTRL clear", ral().ctrl, 32'h0000_0000);

        write_reg(ral().clkdiv, 32'hffff_fedc);
        check_read("CLKDIV RW/reserved", ral().clkdiv, 32'h0000_00dc);

        write_reg(ral().irq_en, 32'hffff_ffff);
        check_read("IRQ_EN RW/reserved", ral().irq_en, 32'h0000_001f);

        read_reg(ral().status, status_before_write);
        check_ignored_write("STATUS RO", ral().status, 32'hffff_ffff, status_before_write);
        check_ignored_write("RXDATA RO while empty", ral().rxdata, 32'hffff_ffff, 32'h0000_0000);
        check_ignored_write("IRQ_RAW RO", ral().irq_raw, 32'hffff_ffff, 32'h0000_0002);
        check_ignored_write("IRQ_STATUS RO", ral().irq_status, 32'hffff_ffff, 32'h0000_0002);
        check_ignored_write("TXFIFO_LVL RO", ral().txfifo_lvl, 32'hffff_ffff, 32'h0000_0000);
        check_ignored_write("RXFIFO_LVL RO", ral().rxfifo_lvl, 32'hffff_ffff, 32'h0000_0000);
        check_ignored_write("VERSION RO", ral().version, 32'hffff_ffff, VERSION_RESET_VALUE);

        write_reg(ral().txdata, 32'ha5a5_a53c);
        check_bus_read("TXDATA still read-as-zero", ral().txdata, 32'h0000_0000);
        check_read("TXFIFO_LVL after TXDATA write", ral().txfifo_lvl, 32'h0000_0001);
        check_read("STATUS after TXDATA write", ral().status, 32'h0000_0008);
        check_read("IRQ_RAW after TXDATA write", ral().irq_raw, 32'h0000_0000);
        check_read("IRQ_STATUS after TXDATA write", ral().irq_status, 32'h0000_0000);

        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd1);
        rsp_q.push_back(8'hc3);
        start_spi_responses_async(rsp_q);
        start_transfer();
        wait_for_done();

        check_read("CTRL start self-clear", ral().ctrl, 32'h0000_0061);
        check_read("STATUS after transfer", ral().status, 32'h0000_0042);
        check_read("IRQ_RAW after transfer", ral().irq_raw, 32'h0000_0007);
        check_read("IRQ_STATUS after transfer", ral().irq_status, 32'h0000_0007);
        check_read("TXFIFO_LVL after transfer", ral().txfifo_lvl, 32'h0000_0000);
        check_read("RXFIFO_LVL after transfer", ral().rxfifo_lvl, 32'h0000_0001);

        write_reg(ral().irq_clear, 32'hffff_ffff);
        check_bus_read("IRQ_CLEAR still read-as-zero", ral().irq_clear, 32'h0000_0000);
        check_read("IRQ_RAW after clear", ral().irq_raw, 32'h0000_0006);
        check_read("IRQ_STATUS after clear", ral().irq_status, 32'h0000_0006);

        bus_write_reg(ral().rxdata, 32'hffff_ffff);
        check_read("RXFIFO_LVL after RXDATA RO write", ral().rxfifo_lvl, 32'h0000_0001);
        check_read("IRQ_RAW after RXDATA RO write", ral().irq_raw, 32'h0000_0006);
        check_read("RXDATA pop data and reserved zero", ral().rxdata, 32'h0000_00c3);
        check_read("RXFIFO_LVL after RXDATA read", ral().rxfifo_lvl, 32'h0000_0000);
        check_read("IRQ_RAW after RXDATA read", ral().irq_raw, 32'h0000_0002);
        check_read("IRQ_STATUS after RXDATA read", ral().irq_status, 32'h0000_0002);

        write_reg(ral().ctrl, 32'h0000_00e1);
        check_read("CTRL soft_reset self-clear", ral().ctrl, 32'h0000_0061);
        check_read("TXFIFO_LVL after soft_reset", ral().txfifo_lvl, 32'h0000_0000);
        check_read("RXFIFO_LVL after soft_reset", ral().rxfifo_lvl, 32'h0000_0000);
        check_read("IRQ_RAW after soft_reset", ral().irq_raw, 32'h0000_0002);
        check_read("IRQ_STATUS after soft_reset", ral().irq_status, 32'h0000_0002);
    endtask
endclass
