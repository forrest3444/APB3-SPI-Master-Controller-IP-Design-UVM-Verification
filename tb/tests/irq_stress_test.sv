class irq_stress_test extends apb_spi_base_test;
    `uvm_component_utils(irq_stress_test)

    function new(string name = "irq_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return irq_stress_vseq::type_id::create("irq_stress_vseq");
    endfunction
endclass
