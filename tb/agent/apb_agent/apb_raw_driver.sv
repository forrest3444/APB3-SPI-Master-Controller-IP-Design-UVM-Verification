class apb_raw_driver extends apb_driver;
    `uvm_component_utils(apb_raw_driver)

    function new(string name = "apb_raw_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task drive_transfer(apb_trans tr);
        apb_raw_trans raw_tr;

        if ($cast(raw_tr, tr) && raw_tr.raw_mode) begin
            drive_raw_transfer(raw_tr);
        end else begin
            super.drive_transfer(tr);
        end
    endtask

    protected task drive_raw_transfer(apb_raw_trans tr);
        @(posedge cfg.vif.pclk);
        cfg.vif.drv_cb.psel    <= tr.raw_psel;
        cfg.vif.drv_cb.penable <= tr.raw_penable;
        cfg.vif.drv_cb.pwrite  <= tr.raw_pwrite;
        cfg.vif.drv_cb.paddr   <= tr.raw_paddr;
        cfg.vif.drv_cb.pwdata  <= tr.raw_pwdata;

        repeat (tr.raw_cycles) begin
            @(posedge cfg.vif.pclk);
        end

        tr.is_write = tr.raw_pwrite;
        tr.addr     = tr.raw_paddr;
        tr.wdata    = tr.raw_pwdata;
        tr.ready    = cfg.vif.pready;
        tr.slverr   = cfg.vif.pslverr;
        tr.rdata    = cfg.vif.prdata;

        cfg.vif.drv_cb.psel    <= 1'b0;
        cfg.vif.drv_cb.penable <= 1'b0;
        cfg.vif.drv_cb.pwrite  <= 1'b0;
        cfg.vif.drv_cb.paddr   <= '0;
        cfg.vif.drv_cb.pwdata  <= '0;
    endtask
endclass
