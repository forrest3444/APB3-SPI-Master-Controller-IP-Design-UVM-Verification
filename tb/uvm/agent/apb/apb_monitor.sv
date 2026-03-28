class apb_monitor extends uvm_component;
    `uvm_component_utils(apb_monitor)

    apb_agent_cfg                  cfg;
    uvm_analysis_port #(apb_trans) ap;

    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(apb_agent_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "apb_agent_cfg not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        apb_trans tr;

        forever begin
            @(posedge cfg.vif.pclk);
            if (!cfg.vif.presetn) begin
                continue;
            end

            if (cfg.vif.mon_cb.psel && cfg.vif.mon_cb.penable && cfg.vif.mon_cb.pready) begin
                tr = apb_trans::type_id::create("tr");
                tr.is_write = cfg.vif.mon_cb.pwrite;
                tr.addr     = cfg.vif.mon_cb.paddr;
                tr.wdata    = cfg.vif.mon_cb.pwdata;
                tr.rdata    = cfg.vif.mon_cb.prdata;
                tr.ready    = cfg.vif.mon_cb.pready;
                tr.slverr   = cfg.vif.mon_cb.pslverr;
                ap.write(tr);
            end
        end
    endtask
endclass
