class fifo_boundary_test extends apb_spi_base_test;
    `uvm_component_utils(fifo_boundary_test)

    function new(string name = "fifo_boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return fifo_boundary_vseq::type_id::create("fifo_boundary_vseq");
    endfunction
endclass
