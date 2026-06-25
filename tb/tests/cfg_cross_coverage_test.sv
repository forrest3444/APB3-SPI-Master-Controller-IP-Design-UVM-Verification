class cfg_cross_coverage_test extends apb_spi_base_test;
    `uvm_component_utils(cfg_cross_coverage_test)

    function new(string name = "cfg_cross_coverage_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return cfg_cross_coverage_vseq::type_id::create("cfg_cross_coverage_vseq");
    endfunction
endclass
