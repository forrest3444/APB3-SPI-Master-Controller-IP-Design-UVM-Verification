class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_agent_cfg                  cfg;
    apb_sequencer                  sequencer;
    apb_driver                     driver;
    apb_monitor                    monitor;
    uvm_analysis_port #(apb_trans) ap;

    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(apb_agent_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "apb_agent_cfg not found")
        end

        monitor = apb_monitor::type_id::create("monitor", this);
        uvm_config_db#(apb_agent_cfg)::set(this, "monitor", "cfg", cfg);

        if (cfg.is_active == UVM_ACTIVE) begin
            sequencer = apb_sequencer::type_id::create("sequencer", this);
            driver    = apb_driver::type_id::create("driver", this);
            uvm_config_db#(apb_agent_cfg)::set(this, "driver", "cfg", cfg);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.ap.connect(ap);

        if (cfg.is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass
