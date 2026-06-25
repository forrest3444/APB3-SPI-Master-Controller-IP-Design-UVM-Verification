class start_rejection_test extends apb_spi_base_test;
    `uvm_component_utils(start_rejection_test)

    function new(string name = "start_rejection_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return start_rejection_vseq::type_id::create("start_rejection_vseq");
    endfunction
endclass
