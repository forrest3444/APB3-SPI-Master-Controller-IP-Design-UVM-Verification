class soft_reset_test extends apb_spi_base_test;
    `uvm_component_utils(soft_reset_test)

    function new(string name = "soft_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return soft_reset_vseq::type_id::create("soft_reset_vseq");
    endfunction
endclass
