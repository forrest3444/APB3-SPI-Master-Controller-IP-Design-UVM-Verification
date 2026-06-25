class tx_rx_en_control_test extends apb_spi_base_test;
    `uvm_component_utils(tx_rx_en_control_test)

    function new(string name = "tx_rx_en_control_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_object create_vseq();
        return tx_rx_en_control_vseq::type_id::create("tx_rx_en_control_vseq");
    endfunction
endclass
