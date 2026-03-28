class apb_spi_base_test extends uvm_test;
    `uvm_component_utils(apb_spi_base_test)

    apb_spi_env     env;
    apb_spi_env_cfg env_cfg;
    virtual apb_if  apb_vif;
    virtual spi_if  spi_vif;

    function new(string name = "apb_spi_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif)) begin
            `uvm_fatal(get_type_name(), "apb_vif not found")
        end

        if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif)) begin
            `uvm_fatal(get_type_name(), "spi_vif not found")
        end

        env_cfg = apb_spi_env_cfg::type_id::create("env_cfg");
        env_cfg.apb_cfg = apb_agent_cfg::type_id::create("apb_cfg");
        env_cfg.spi_cfg = spi_agent_cfg::type_id::create("spi_cfg");

        env_cfg.apb_cfg.vif       = apb_vif;
        env_cfg.apb_cfg.is_active = UVM_ACTIVE;
        env_cfg.spi_cfg.vif       = spi_vif;
        env_cfg.spi_cfg.is_active = UVM_ACTIVE;
        env_cfg.spi_cfg.default_cpol = 1'b0;
        env_cfg.spi_cfg.default_cpha = 1'b0;

        uvm_config_db#(apb_spi_env_cfg)::set(this, "env", "env_cfg", env_cfg);
        env = apb_spi_env::type_id::create("env", this);
    endfunction

    virtual function uvm_object create_vseq();
        return apb_spi_base_vseq::type_id::create("base_vseq");
    endfunction

    task run_phase(uvm_phase phase);
        apb_spi_base_vseq vseq;

        phase.raise_objection(this);
        if (!$cast(vseq, create_vseq())) begin
            `uvm_fatal(get_type_name(), "create_vseq() returned wrong type")
        end

        vseq.start(env.vseqr);
        phase.drop_objection(this);
    endtask
endclass
