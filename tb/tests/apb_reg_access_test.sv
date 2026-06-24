class apb_reg_access_test extends apb_spi_base_test;
    `uvm_component_utils(apb_reg_access_test)

    function new(string name = "apb_reg_access_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return apb_reg_access_vseq::type_id::create("apb_reg_access_vseq");
    endfunction
endclass
