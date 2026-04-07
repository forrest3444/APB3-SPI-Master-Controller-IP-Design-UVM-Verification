class apb_spi_env extends uvm_env;
    `uvm_component_utils(apb_spi_env)

    apb_spi_env_cfg           cfg;
    apb_agent                 apb_agent_h;
    spi_agent                 spi_agent_h;
    apb_spi_virtual_sequencer vseqr;
    apb_spi_scoreboard        scb;
    apb_spi_coverage          cov;
    apb_spi_reg_block         ral_model;
    apb_reg_adapter           reg_adapter;
    uvm_reg_predictor #(apb_trans) reg_predictor;

    function new(string name = "apb_spi_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(apb_spi_env_cfg)::get(this, "", "env_cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "apb_spi_env_cfg not found")
        end

        uvm_config_db#(apb_agent_cfg)::set(this, "apb_agent_h*", "cfg", cfg.apb_cfg);
        uvm_config_db#(spi_agent_cfg)::set(this, "spi_agent_h*", "cfg", cfg.spi_cfg);

        apb_agent_h = apb_agent::type_id::create("apb_agent_h", this);
        spi_agent_h = spi_agent::type_id::create("spi_agent_h", this);
        vseqr       = apb_spi_virtual_sequencer::type_id::create("vseqr", this);

        if (cfg.enable_ral) begin
            ral_model = apb_spi_reg_block::type_id::create("ral_model");
            ral_model.build();
            ral_model.lock_model();
            ral_model.reset();
            reg_adapter   = apb_reg_adapter::type_id::create("reg_adapter");
            reg_predictor = new("reg_predictor", this);
        end

        if (cfg.enable_scoreboard) begin
            scb = apb_spi_scoreboard::type_id::create("scb", this);
        end

        if (cfg.enable_coverage) begin
            cov = apb_spi_coverage::type_id::create("cov", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        vseqr.apb_sqr = apb_agent_h.sequencer;
        vseqr.spi_sqr = spi_agent_h.sequencer;
        vseqr.cfg     = cfg;

        if (cfg.enable_ral) begin
            vseqr.ral_model = ral_model;
            ral_model.default_map.set_sequencer(apb_agent_h.sequencer, reg_adapter);
            reg_predictor.map     = ral_model.default_map;
            reg_predictor.adapter = reg_adapter;
            apb_agent_h.ap.connect(reg_predictor.bus_in);
        end

        if (cfg.enable_scoreboard) begin
            apb_agent_h.ap.connect(scb.apb_imp);
            spi_agent_h.ap.connect(scb.spi_imp);
        end

        if (cfg.enable_coverage) begin
            apb_agent_h.ap.connect(cov.apb_imp);
            spi_agent_h.ap.connect(cov.spi_imp);
        end
    endfunction
endclass
