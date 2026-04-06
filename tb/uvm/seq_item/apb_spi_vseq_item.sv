class apb_spi_vseq_item extends uvm_sequence_item;
    `uvm_object_utils(apb_spi_vseq_item)

    rand bit           cpol;
    rand bit           cpha;
    rand bit           cont;
    rand bit           tx_en;
    rand bit           rx_en;
    rand bit [7:0]     clkdiv;
    rand byte unsigned tx_data_q[$];
    rand byte unsigned rx_data_q[$];

    function new(string name = "apb_spi_vseq_item");
        super.new(name);
    endfunction
endclass
