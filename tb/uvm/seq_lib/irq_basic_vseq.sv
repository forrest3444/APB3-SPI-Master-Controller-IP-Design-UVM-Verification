class irq_basic_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(irq_basic_vseq)

    function new(string name = "irq_basic_vseq");
        super.new(name);
    endfunction

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;
        bit [31:0]   rdata;

        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd2);
        set_irq_enable(5'b1_1111);

        start_transfer();
        wait_for_done();
        apb_read_reg(REG_IRQ_RAW_ADDR, rdata);
        apb_read_reg(REG_IRQ_STATUS_ADDR, rdata);
        clear_irq(5'b0_1000);

        rsp_q.push_back(8'h5A);
        start_spi_responses_async(rsp_q);
        push_tx_byte(8'hC5);
        start_transfer();
        wait_for_done();
        apb_read_reg(REG_STATUS_ADDR, rdata);
        apb_read_reg(REG_IRQ_RAW_ADDR, rdata);
        apb_read_reg(REG_IRQ_STATUS_ADDR, rdata);
        pop_rx_byte(rx_byte);
        clear_irq(5'b1_1101);
    endtask
endclass
