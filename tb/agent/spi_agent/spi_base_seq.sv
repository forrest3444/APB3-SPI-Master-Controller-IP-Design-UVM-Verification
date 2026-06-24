class spi_base_seq extends uvm_sequence #(spi_frame);
    `uvm_object_utils(spi_base_seq)
    `uvm_declare_p_sequencer(spi_sequencer)

    byte unsigned response_q[$];
    bit           cpol;
    bit           cpha;
    bit           cont;
    bit           tx_en = 1'b1;
    bit           rx_en = 1'b1;

    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction

    virtual task body();
        spi_frame req;
        int       last_idx;

        last_idx = response_q.size() - 1;

        foreach (response_q[idx]) begin
            req = spi_frame::type_id::create($sformatf("req_%0d", idx));
            start_item(req);
            req.cpol    = cpol;
            req.cpha    = cpha;
            req.cont    = cont && (idx != last_idx);
            req.tx_en   = tx_en;
            req.rx_en   = rx_en;
            req.rx_byte = response_q[idx];
            finish_item(req);
        end
    endtask
endclass
