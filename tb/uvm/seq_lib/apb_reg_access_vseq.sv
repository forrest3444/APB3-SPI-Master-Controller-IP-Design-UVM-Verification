class apb_reg_access_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(apb_reg_access_vseq)

    function new(string name = "apb_reg_access_vseq");
        super.new(name);
    endfunction

    task automatic check_read(string reg_name, bit [11:0] addr, bit [31:0] exp_data);
        bit [31:0] act_data;

        apb_read_reg(addr, act_data);
        if (act_data !== exp_data) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s mismatch at 0x%03h exp=0x%08h act=0x%08h",
                                 reg_name, addr, exp_data, act_data))
        end
    endtask

    task automatic check_ignored_write(string reg_name, bit [11:0] addr, bit [31:0] wr_data, bit [31:0] exp_data);
        apb_write_reg(addr, wr_data);
        check_read(reg_name, addr, exp_data);
    endtask

    task body();
        byte unsigned rsp_q[$];
        bit [31:0]   status_before_write;

        check_read("CTRL reset", REG_CTRL_ADDR, CTRL_RESET_VALUE);
        check_read("STATUS reset", REG_STATUS_ADDR, 32'h0000_000a);
        check_read("CLKDIV reset", REG_CLKDIV_ADDR, 32'h0000_0001);
        check_read("TXDATA read-as-zero", REG_TXDATA_ADDR, 32'h0000_0000);
        check_read("RXDATA empty", REG_RXDATA_ADDR, 32'h0000_0000);
        check_read("IRQ_EN reset", REG_IRQ_EN_ADDR, 32'h0000_0000);
        check_read("IRQ_RAW reset", REG_IRQ_RAW_ADDR, 32'h0000_0002);
        check_read("IRQ_STATUS reset", REG_IRQ_STATUS_ADDR, 32'h0000_0000);
        check_read("IRQ_CLEAR read-as-zero", REG_IRQ_CLEAR_ADDR, 32'h0000_0000);
        check_read("TXFIFO_LVL reset", REG_TXFIFO_LVL_ADDR, 32'h0000_0000);
        check_read("RXFIFO_LVL reset", REG_RXFIFO_LVL_ADDR, 32'h0000_0000);
        check_read("VERSION reset", REG_VERSION_ADDR, VERSION_RESET_VALUE);

        apb_write_reg(REG_CTRL_ADDR, 32'hffff_ffff);
        check_read("CTRL RW/WO/reserved", REG_CTRL_ADDR, 32'h0000_007d);

        apb_write_reg(REG_CTRL_ADDR, 32'h0000_0000);
        check_read("CTRL clear", REG_CTRL_ADDR, 32'h0000_0000);

        apb_write_reg(REG_CLKDIV_ADDR, 32'hffff_fedc);
        check_read("CLKDIV RW/reserved", REG_CLKDIV_ADDR, 32'h0000_fedc);

        apb_write_reg(REG_IRQ_EN_ADDR, 32'hffff_ffff);
        check_read("IRQ_EN RW/reserved", REG_IRQ_EN_ADDR, 32'h0000_001f);

        apb_read_reg(REG_STATUS_ADDR, status_before_write);
        check_ignored_write("STATUS RO", REG_STATUS_ADDR, 32'hffff_ffff, status_before_write);
        check_ignored_write("RXDATA RO while empty", REG_RXDATA_ADDR, 32'hffff_ffff, 32'h0000_0000);
        check_ignored_write("IRQ_RAW RO", REG_IRQ_RAW_ADDR, 32'hffff_ffff, 32'h0000_0002);
        check_ignored_write("IRQ_STATUS RO", REG_IRQ_STATUS_ADDR, 32'hffff_ffff, 32'h0000_0002);
        check_ignored_write("TXFIFO_LVL RO", REG_TXFIFO_LVL_ADDR, 32'hffff_ffff, 32'h0000_0000);
        check_ignored_write("RXFIFO_LVL RO", REG_RXFIFO_LVL_ADDR, 32'hffff_ffff, 32'h0000_0000);
        check_ignored_write("VERSION RO", REG_VERSION_ADDR, 32'hffff_ffff, VERSION_RESET_VALUE);

        apb_write_reg(REG_TXDATA_ADDR, 32'ha5a5_a53c);
        check_read("TXDATA still read-as-zero", REG_TXDATA_ADDR, 32'h0000_0000);
        check_read("TXFIFO_LVL after TXDATA write", REG_TXFIFO_LVL_ADDR, 32'h0000_0001);
        check_read("STATUS after TXDATA write", REG_STATUS_ADDR, 32'h0000_0008);
        check_read("IRQ_RAW after TXDATA write", REG_IRQ_RAW_ADDR, 32'h0000_0000);
        check_read("IRQ_STATUS after TXDATA write", REG_IRQ_STATUS_ADDR, 32'h0000_0000);

        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd1);
        rsp_q.push_back(8'hc3);
        start_spi_responses_async(rsp_q);
        start_transfer();
        wait_for_done();

        check_read("CTRL start self-clear", REG_CTRL_ADDR, 32'h0000_0061);
        check_read("STATUS after transfer", REG_STATUS_ADDR, 32'h0000_004a);
        check_read("IRQ_RAW after transfer", REG_IRQ_RAW_ADDR, 32'h0000_0007);
        check_read("IRQ_STATUS after transfer", REG_IRQ_STATUS_ADDR, 32'h0000_0007);
        check_read("TXFIFO_LVL after transfer", REG_TXFIFO_LVL_ADDR, 32'h0000_0000);
        check_read("RXFIFO_LVL after transfer", REG_RXFIFO_LVL_ADDR, 32'h0000_0001);

        apb_write_reg(REG_IRQ_CLEAR_ADDR, 32'hffff_ffff);
        check_read("IRQ_CLEAR still read-as-zero", REG_IRQ_CLEAR_ADDR, 32'h0000_0000);
        check_read("IRQ_RAW after clear", REG_IRQ_RAW_ADDR, 32'h0000_0006);
        check_read("IRQ_STATUS after clear", REG_IRQ_STATUS_ADDR, 32'h0000_0006);

        apb_write_reg(REG_RXDATA_ADDR, 32'hffff_ffff);
        check_read("RXFIFO_LVL after RXDATA RO write", REG_RXFIFO_LVL_ADDR, 32'h0000_0001);
        check_read("IRQ_RAW after RXDATA RO write", REG_IRQ_RAW_ADDR, 32'h0000_0006);
        check_read("RXDATA pop data and reserved zero", REG_RXDATA_ADDR, 32'h0000_00c3);
        check_read("RXFIFO_LVL after RXDATA read", REG_RXFIFO_LVL_ADDR, 32'h0000_0000);
        check_read("IRQ_RAW after RXDATA read", REG_IRQ_RAW_ADDR, 32'h0000_0002);
        check_read("IRQ_STATUS after RXDATA read", REG_IRQ_STATUS_ADDR, 32'h0000_0002);

        apb_write_reg(REG_CTRL_ADDR, 32'h0000_00e1);
        check_read("CTRL soft_reset self-clear", REG_CTRL_ADDR, 32'h0000_0061);
        check_read("TXFIFO_LVL after soft_reset", REG_TXFIFO_LVL_ADDR, 32'h0000_0000);
        check_read("RXFIFO_LVL after soft_reset", REG_RXFIFO_LVL_ADDR, 32'h0000_0000);
        check_read("IRQ_RAW after soft_reset", REG_IRQ_RAW_ADDR, 32'h0000_0002);
        check_read("IRQ_STATUS after soft_reset", REG_IRQ_STATUS_ADDR, 32'h0000_0002);
    endtask
endclass
