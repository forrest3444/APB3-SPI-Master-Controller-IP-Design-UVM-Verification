class mode_sweep_test extends apb_spi_base_test;
    `uvm_component_utils(mode_sweep_test)

    function new(string name = "mode_sweep_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return mode_sweep_vseq::type_id::create("mode_sweep_vseq");
    endfunction
endclass
