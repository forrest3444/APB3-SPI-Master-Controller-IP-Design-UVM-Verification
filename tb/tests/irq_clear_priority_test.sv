class irq_clear_priority_test extends apb_spi_base_test;
    `uvm_component_utils(irq_clear_priority_test)

    function new(string name = "irq_clear_priority_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_cfg.enable_scoreboard = 1'b0;
    endfunction

    virtual function uvm_object create_vseq();
        return irq_clear_priority_vseq::type_id::create("irq_clear_priority_vseq");
    endfunction
endclass
