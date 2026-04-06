class cont_mode_test extends apb_spi_base_test;
    `uvm_component_utils(cont_mode_test)

    function new(string name = "cont_mode_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return cont_mode_vseq::type_id::create("cont_mode_vseq");
    endfunction
endclass
