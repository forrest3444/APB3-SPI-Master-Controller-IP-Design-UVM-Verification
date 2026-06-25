class pslverr_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(pslverr_vseq)

    function new(string name = "pslverr_vseq");
        super.new(name);
    endfunction

    task automatic raw_apb_transfer(bit        is_write,
                                    bit [11:0] addr,
                                    bit [31:0] wdata,
                                    output bit [31:0] rdata,
                                    output bit        slverr,
                                    output bit        ready);
        apb_trans req;

        req = apb_trans::type_id::create($sformatf("raw_apb_%s_%03h",
                                                   is_write ? "write" : "read",
                                                   addr));
        `uvm_do_on_with(req, p_sequencer.apb_sqr, {
            is_write == local::is_write;
            addr     == local::addr;
            wdata    == local::wdata;
        })

        rdata  = req.rdata;
        slverr = req.slverr;
        ready  = req.ready;
    endtask

    task automatic expect_raw_access(string     name,
                                     bit        is_write,
                                     bit [11:0] addr,
                                     bit [31:0] wdata,
                                     bit        exp_slverr,
                                     bit        check_rdata = 1'b0,
                                     bit [31:0] exp_rdata = '0);
        bit [31:0] rdata;
        bit        slverr;
        bit        ready;

        raw_apb_transfer(is_write, addr, wdata, rdata, slverr, ready);

        if (ready !== 1'b1) begin
            `uvm_error(get_type_name(), $sformatf("%s did not complete with PREADY=1", name))
        end

        if (slverr !== exp_slverr) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s PSLVERR mismatch exp=%0b act=%0b addr=0x%03h",
                                 name, exp_slverr, slverr, addr))
        end

        if (!is_write && check_rdata && (rdata !== exp_rdata)) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s PRDATA mismatch exp=0x%08h act=0x%08h addr=0x%03h",
                                 name, exp_rdata, rdata, addr))
        end
    endtask

    task automatic check_illegal_addr(bit [11:0] addr);
        expect_raw_access($sformatf("illegal write 0x%03h", addr),
                          1'b1, addr, 32'ha5a5_5a5a, 1'b1);
        expect_raw_access($sformatf("illegal read 0x%03h", addr),
                          1'b0, addr, '0, 1'b1, 1'b1, 32'h0000_0000);
    endtask

    task automatic check_legal_read_no_error(string name,
                                             bit [11:0] addr,
                                             bit [31:0] exp_rdata);
        expect_raw_access(name, 1'b0, addr, '0, 1'b0, 1'b1, exp_rdata);
    endtask

    task body();
        bit [31:0] ctrl_before;
        bit [31:0] clkdiv_before;
        bit [31:0] irq_en_before;
        bit [31:0] version_before;
        bit [31:0] tx_level;

        write_reg(ral().ctrl, 32'h0000_0061);
        write_reg(ral().clkdiv, 32'h0000_00aa);
        write_reg(ral().irq_en, 32'h0000_0015);

        read_reg(ral().ctrl, ctrl_before);
        read_reg(ral().clkdiv, clkdiv_before);
        read_reg(ral().irq_en, irq_en_before);
        read_reg(ral().version, version_before);

        check_illegal_addr(12'h001);
        check_illegal_addr(12'h003);
        check_illegal_addr(12'h030);
        check_illegal_addr(12'h031);
        check_illegal_addr(12'h034);
        check_illegal_addr(12'h0ff);

        check_reg_value("CTRL after illegal accesses", ral().ctrl, ctrl_before);
        check_reg_value("CLKDIV after illegal accesses", ral().clkdiv, clkdiv_before);
        check_reg_value("IRQ_EN after illegal accesses", ral().irq_en, irq_en_before);
        check_reg_value("VERSION after illegal accesses", ral().version, version_before);

        expect_raw_access("STATUS RO write is legal", 1'b1, REG_STATUS_ADDR, 32'hffff_ffff, 1'b0);
        expect_raw_access("IRQ_RAW RO write is legal", 1'b1, REG_IRQ_RAW_ADDR, 32'hffff_ffff, 1'b0);
        expect_raw_access("IRQ_STATUS RO write is legal", 1'b1, REG_IRQ_STATUS_ADDR, 32'hffff_ffff, 1'b0);
        expect_raw_access("VERSION RO write is legal", 1'b1, REG_VERSION_ADDR, 32'hffff_ffff, 1'b0);

        check_legal_read_no_error("TXDATA WO read is legal", REG_TXDATA_ADDR, 32'h0000_0000);
        check_legal_read_no_error("IRQ_CLEAR WO read is legal", REG_IRQ_CLEAR_ADDR, 32'h0000_0000);
        check_legal_read_no_error("RXDATA empty read is legal", REG_RXDATA_ADDR, 32'h0000_0000);

        repeat (8) begin
            expect_raw_access("TXDATA fill write is legal", 1'b1, REG_TXDATA_ADDR, 32'h0000_005a, 1'b0);
        end
        read_reg(ral().txfifo_lvl, tx_level);
        if (tx_level !== 32'h0000_0008) begin
            `uvm_error(get_type_name(),
                       $sformatf("TX FIFO level before full-write check exp=8 act=0x%08h", tx_level))
        end

        expect_raw_access("TXDATA full write is legal", 1'b1, REG_TXDATA_ADDR, 32'h000000_c3, 1'b0);
        check_reg_value("TXFIFO_LVL after full TXDATA write", ral().txfifo_lvl, 32'h0000_0008);
    endtask
endclass
