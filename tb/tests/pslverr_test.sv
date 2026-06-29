class pslverr_test extends apb_spi_base_test;
    `uvm_component_utils(pslverr_test)

    function new(string name = "pslverr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        apb_driver::type_id::set_type_override(apb_raw_driver::get_type());
        super.build_phase(phase);
    endfunction

    virtual function uvm_object create_vseq();
        return pslverr_vseq::type_id::create("pslverr_vseq");
    endfunction
endclass
