class cold_reset_test extends apb_spi_base_test;
    `uvm_component_utils(cold_reset_test)

    function new(string name = "cold_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return cold_reset_vseq::type_id::create("cold_reset_vseq");
    endfunction
endclass
