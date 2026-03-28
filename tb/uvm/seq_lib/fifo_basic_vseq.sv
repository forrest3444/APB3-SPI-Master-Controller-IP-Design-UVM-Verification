class fifo_basic_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(fifo_basic_vseq)

    function new(string name = "fifo_basic_vseq");
        super.new(name);
    endfunction

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;

        cfg_spi_mode(1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd1);

        rsp_q.push_back(8'h11);
        rsp_q.push_back(8'h22);
        rsp_q.push_back(8'h33);
        start_spi_responses_async(rsp_q, 1'b1);

        push_tx_byte(8'hA1);
        push_tx_byte(8'hB2);
        push_tx_byte(8'hC3);
        start_transfer();
        wait_for_rx_level(3);

        repeat (3) begin
            pop_rx_byte(rx_byte);
        end

        clear_irq(5'b1_1001);
    endtask
endclass
