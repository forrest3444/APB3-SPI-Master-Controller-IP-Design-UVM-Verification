class fifo_basic_test extends apb_spi_base_test;
    `uvm_component_utils(fifo_basic_test)

    function new(string name = "fifo_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return fifo_basic_vseq::type_id::create("fifo_basic_vseq");
    endfunction
endclass
