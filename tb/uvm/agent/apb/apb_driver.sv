class apb_driver extends uvm_driver #(apb_trans);
    `uvm_component_utils(apb_driver)

    apb_agent_cfg cfg;

    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(apb_agent_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "apb_agent_cfg not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        apb_trans req;

        cfg.vif.init_master();
        wait (cfg.vif.presetn === 1'b1);

        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(apb_trans tr);
        @(posedge cfg.vif.pclk);
        cfg.vif.drv_cb.psel    <= 1'b1;
        cfg.vif.drv_cb.penable <= 1'b0;
        cfg.vif.drv_cb.pwrite  <= tr.is_write;
        cfg.vif.drv_cb.paddr   <= tr.addr;
        cfg.vif.drv_cb.pwdata  <= tr.wdata;

        @(posedge cfg.vif.pclk);
        cfg.vif.drv_cb.penable <= 1'b1;

        do begin
            @(posedge cfg.vif.pclk);
        end while (cfg.vif.mon_cb.pready !== 1'b1);

        tr.ready  = cfg.vif.mon_cb.pready;
        tr.slverr = cfg.vif.mon_cb.pslverr;
        if (!tr.is_write) begin
            tr.rdata = cfg.vif.mon_cb.prdata;
        end

        cfg.vif.drv_cb.psel    <= 1'b0;
        cfg.vif.drv_cb.penable <= 1'b0;
        cfg.vif.drv_cb.pwrite  <= 1'b0;
        cfg.vif.drv_cb.paddr   <= '0;
        cfg.vif.drv_cb.pwdata  <= '0;
    endtask
endclass
