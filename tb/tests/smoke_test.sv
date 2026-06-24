class smoke_test extends apb_spi_base_test;
    `uvm_component_utils(smoke_test)

    function new(string name = "smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return smoke_vseq::type_id::create("smoke_vseq");
    endfunction
endclass
