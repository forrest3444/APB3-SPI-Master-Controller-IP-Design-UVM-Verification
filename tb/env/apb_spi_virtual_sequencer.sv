class apb_spi_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);
    `uvm_component_utils(apb_spi_virtual_sequencer)

    apb_sequencer   apb_sqr;
    spi_sequencer   spi_sqr;
    apb_spi_env_cfg cfg;
    apb_spi_reg_block ral_model;

    function new(string name = "apb_spi_virtual_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
