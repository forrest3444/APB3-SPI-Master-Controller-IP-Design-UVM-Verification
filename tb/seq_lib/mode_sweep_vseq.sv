class mode_sweep_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(mode_sweep_vseq)

    function new(string name = "mode_sweep_vseq");
        super.new(name);
    endfunction

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;

        for (int mode = 0; mode < 4; mode++) begin
            cfg_spi_mode(mode[1], mode[0], 1'b0, 1'b1, 1'b1, 1'b1);
            set_clkdiv(mode + 1);
            rsp_q.delete();
            rsp_q.push_back(byte'(8'h80 + mode));
            start_spi_responses_async(rsp_q);
            push_tx_byte(byte'(8'h10 + mode));
            start_transfer();
            wait_for_done();
            pop_rx_byte(rx_byte);
            clear_irq(5'b1_1001);
        end
    endtask
endclass
