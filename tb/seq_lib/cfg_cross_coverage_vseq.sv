class cfg_cross_coverage_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(cfg_cross_coverage_vseq)

    function new(string name = "cfg_cross_coverage_vseq");
        super.new(name);
    endfunction

    task automatic run_rx_only_single(int unsigned mode, byte unsigned rsp);
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;

        cfg_spi_mode(mode[1], mode[0], 1'b0, 1'b1, 1'b0, 1'b1);
        set_clkdiv(8'd2);

        rsp_q.push_back(rsp);
        start_spi_responses_async(rsp_q, 1'b0, 1'b0, 1'b1);
        start_transfer();
        wait_for_transfer_idle(1);

        pop_rx_byte(rx_byte);
        if (rx_byte !== rsp) begin
            `uvm_error(get_type_name(),
                       $sformatf("RX-only mode%0d mismatch exp=0x%02h act=0x%02h",
                                 mode, rsp, rx_byte))
        end
        clear_irq(5'b1_1001);
    endtask

    task automatic run_tx_only_single(int unsigned mode, byte unsigned tx);
        cfg_spi_mode(mode[1], mode[0], 1'b0, 1'b0, 1'b1, 1'b1);
        set_clkdiv(8'd2);

        push_tx_byte(tx);
        start_transfer();
        wait_for_transfer_idle(0);

        check_reg_value($sformatf("RXFIFO empty after TX-only mode%0d", mode),
                        ral().rxfifo_lvl, 32'h0000_0000);
        clear_irq(5'b1_1001);
    endtask

    task automatic run_tx_only_cont(int unsigned mode, byte unsigned tx0, byte unsigned tx1);
        int unsigned max_pclk_cycles;

        cfg_spi_mode(mode[1], mode[0], 1'b1, 1'b0, 1'b1, 1'b1);
        set_clkdiv(8'd2);

        push_tx_byte(tx0);
        push_tx_byte(tx1);
        start_transfer();

        max_pclk_cycles = 128;
        wait_for_transfer_idle(0, max_pclk_cycles);
        check_reg_value($sformatf("RXFIFO empty after TX-only cont mode%0d", mode),
                        ral().rxfifo_lvl, 32'h0000_0000);
        clear_irq(5'b1_1001);
    endtask

    task automatic run_full_duplex_cont(int unsigned mode,
                                        byte unsigned tx0,
                                        byte unsigned tx1,
                                        byte unsigned rsp0,
                                        byte unsigned rsp1);
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;
        int unsigned  max_pclk_cycles;

        cfg_spi_mode(mode[1], mode[0], 1'b1, 1'b1, 1'b1, 1'b1);
        set_clkdiv(8'd2);

        rsp_q.push_back(rsp0);
        rsp_q.push_back(rsp1);
        start_spi_responses_async(rsp_q, 1'b1, 1'b1, 1'b1);

        push_tx_byte(tx0);
        push_tx_byte(tx1);
        start_transfer();

        max_pclk_cycles = 128;
        wait_for_transfer_idle(2, max_pclk_cycles);

        pop_rx_byte(rx_byte);
        if (rx_byte !== rsp0) begin
            `uvm_error(get_type_name(),
                       $sformatf("Full-duplex cont mode%0d byte0 mismatch exp=0x%02h act=0x%02h",
                                 mode, rsp0, rx_byte))
        end

        pop_rx_byte(rx_byte);
        if (rx_byte !== rsp1) begin
            `uvm_error(get_type_name(),
                       $sformatf("Full-duplex cont mode%0d byte1 mismatch exp=0x%02h act=0x%02h",
                                 mode, rsp1, rx_byte))
        end
        clear_irq(5'b1_1001);
    endtask

    task body();
        // Close legal cfg_cg mode_cross holes after removing ignored txrx=00
        // and receive-only continuous combinations.
        for (int mode = 0; mode < 4; mode++) begin
            run_rx_only_single(mode, byte'(8'h40 + mode));
        end

        for (int mode = 1; mode < 4; mode++) begin
            run_tx_only_single(mode, byte'(8'h50 + mode));
        end

        for (int mode = 0; mode < 4; mode++) begin
            run_tx_only_cont(mode, byte'(8'h60 + (mode * 2)),
                                   byte'(8'h61 + (mode * 2)));
        end

        for (int mode = 1; mode < 4; mode++) begin
            run_full_duplex_cont(mode,
                                 byte'(8'h70 + (mode * 2)),
                                 byte'(8'h71 + (mode * 2)),
                                 byte'(8'h80 + (mode * 2)),
                                 byte'(8'h81 + (mode * 2)));
        end
    endtask
endclass
