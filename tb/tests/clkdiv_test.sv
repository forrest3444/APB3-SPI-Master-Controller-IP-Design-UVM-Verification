class clkdiv_test extends apb_spi_base_test;
    `uvm_component_utils(clkdiv_test)

    function new(string name = "clkdiv_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return clkdiv_test_vseq::type_id::create("clkdiv_test_vseq");
    endfunction
endclass
