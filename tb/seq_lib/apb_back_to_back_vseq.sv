class apb_back_to_back_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(apb_back_to_back_vseq)

    typedef struct packed {
        bit        is_write;
        bit [11:0] addr;
        bit [31:0] wdata;
        bit [31:0] exp_rdata;
        bit [31:0] rmask;
    } apb_b2b_item_s;

    function new(string name = "apb_back_to_back_vseq");
        super.new(name);
    endfunction

    task automatic drive_setup(apb_b2b_item_s item);
        cfg.apb_cfg.vif.psel    = 1'b1;
        cfg.apb_cfg.vif.penable = 1'b0;
        cfg.apb_cfg.vif.pwrite  = item.is_write;
        cfg.apb_cfg.vif.paddr   = item.addr;
        cfg.apb_cfg.vif.pwdata  = item.wdata;
    endtask

    task automatic drive_access();
        cfg.apb_cfg.vif.penable = 1'b1;
    endtask

    task automatic check_setup(string tag);
        #1step;
        if (cfg.apb_cfg.vif.psel !== 1'b1 || cfg.apb_cfg.vif.penable !== 1'b0) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s setup phase mismatch psel=%0b penable=%0b",
                                 tag, cfg.apb_cfg.vif.psel, cfg.apb_cfg.vif.penable))
        end
        if (cfg.apb_cfg.vif.pslverr !== 1'b0) begin
            `uvm_error(get_type_name(), $sformatf("%s PSLVERR asserted outside access phase", tag))
        end
    endtask

    task automatic check_access(string tag, apb_b2b_item_s item);
        #1step;
        if (cfg.apb_cfg.vif.psel !== 1'b1 || cfg.apb_cfg.vif.penable !== 1'b1) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s access phase mismatch psel=%0b penable=%0b",
                                 tag, cfg.apb_cfg.vif.psel, cfg.apb_cfg.vif.penable))
        end
        if (cfg.apb_cfg.vif.pready !== 1'b1) begin
            `uvm_error(get_type_name(), $sformatf("%s legal access did not complete zero-wait", tag))
        end
        if (cfg.apb_cfg.vif.pslverr !== 1'b0) begin
            `uvm_error(get_type_name(), $sformatf("%s legal access returned PSLVERR", tag))
        end
        if (!item.is_write && ((cfg.apb_cfg.vif.prdata & item.rmask) !== (item.exp_rdata & item.rmask))) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s read mismatch addr=0x%03h mask=0x%08h exp=0x%08h act=0x%08h",
                                 tag, item.addr, item.rmask,
                                 item.exp_rdata & item.rmask,
                                 cfg.apb_cfg.vif.prdata & item.rmask))
        end
    endtask

    task automatic run_back_to_back(apb_b2b_item_s items[$]);
        string tag;

        @(negedge cfg.apb_cfg.vif.pclk);
        for (int i = 0; i < items.size(); i++) begin
            tag = $sformatf("b2b[%0d]", i);

            drive_setup(items[i]);
            @(posedge cfg.apb_cfg.vif.pclk);
            check_setup({tag, " setup"});

            @(negedge cfg.apb_cfg.vif.pclk);
            drive_access();
            @(posedge cfg.apb_cfg.vif.pclk);
            check_access({tag, " access"}, items[i]);

            // No idle cycle is inserted here. The next loop iteration drives the
            // following setup phase on the negedge immediately after completion.
            @(negedge cfg.apb_cfg.vif.pclk);
        end

        cfg.apb_cfg.vif.psel    = 1'b0;
        cfg.apb_cfg.vif.penable = 1'b0;
        cfg.apb_cfg.vif.pwrite  = 1'b0;
        cfg.apb_cfg.vif.paddr   = '0;
        cfg.apb_cfg.vif.pwdata  = '0;
        @(posedge cfg.apb_cfg.vif.pclk);
    endtask

    task body();
        apb_b2b_item_s items[$];
        apb_b2b_item_s item;

        wait (cfg.apb_cfg.vif.presetn === 1'b1);
        repeat (2) @(posedge cfg.apb_cfg.vif.pclk);

        item = '{1'b1, REG_CLKDIV_ADDR, 32'h0000_0012, 32'h0, 32'h0};
        items.push_back(item);
        item = '{1'b0, REG_CLKDIV_ADDR, 32'h0000_0000, 32'h0000_0012, 32'h0000_00ff};
        items.push_back(item);
        item = '{1'b1, REG_IRQ_EN_ADDR, 32'h0000_0015, 32'h0, 32'h0};
        items.push_back(item);
        item = '{1'b0, REG_IRQ_EN_ADDR, 32'h0000_0000, 32'h0000_0015, 32'h0000_001f};
        items.push_back(item);
        item = '{1'b1, REG_CTRL_ADDR, 32'h0000_0065, 32'h0, 32'h0};
        items.push_back(item);
        item = '{1'b0, REG_CTRL_ADDR, 32'h0000_0000, 32'h0000_0065, 32'h0000_007d};
        items.push_back(item);
        item = '{1'b1, REG_TXDATA_ADDR, 32'h0000_00a5, 32'h0, 32'h0};
        items.push_back(item);
        item = '{1'b1, REG_TXDATA_ADDR, 32'h0000_003c, 32'h0, 32'h0};
        items.push_back(item);
        item = '{1'b0, REG_TXFIFO_LVL_ADDR, 32'h0000_0000, 32'h0000_0002, 32'h0000_000f};
        items.push_back(item);
        item = '{1'b0, REG_STATUS_ADDR, 32'h0000_0000, 32'h0000_0008, 32'h0000_001e};
        items.push_back(item);
        item = '{1'b0, REG_VERSION_ADDR, 32'h0000_0000, VERSION_RESET_VALUE, 32'hffff_ffff};
        items.push_back(item);
        item = '{1'b1, REG_CLKDIV_ADDR, 32'h0000_00a7, 32'h0, 32'h0};
        items.push_back(item);
        item = '{1'b0, REG_CLKDIV_ADDR, 32'h0000_0000, 32'h0000_00a7, 32'h0000_00ff};
        items.push_back(item);

        run_back_to_back(items);

        check_reg_value("CLKDIV after APB back-to-back", ral().clkdiv, 32'h0000_00a7);
        check_reg_value("IRQ_EN after APB back-to-back", ral().irq_en, 32'h0000_0015);
        check_reg_value("CTRL after APB back-to-back", ral().ctrl, 32'h0000_0065);
        check_reg_value("TXFIFO_LVL after APB back-to-back", ral().txfifo_lvl, 32'h0000_0002);
    endtask
endclass
