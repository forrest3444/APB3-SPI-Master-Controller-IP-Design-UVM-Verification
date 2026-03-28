class smoke_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(smoke_vseq)

    function new(string name = "smoke_vseq");
        super.new(name);
    endfunction

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;

        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd2);
        rsp_q.push_back(8'hA5);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'h3C);
        start_transfer();
        wait_for_done();
        pop_rx_byte(rx_byte);
        clear_irq(5'b1_1001);
    endtask
endclass
