class clkdiv_test_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(clkdiv_test_vseq)

    function new(string name = "clkdiv_test_vseq");
        super.new(name);
    endfunction

    task automatic check_reg(string reg_name, bit [11:0] addr, bit [31:0] exp_data);
        bit [31:0] act_data;

        apb_read_reg(addr, act_data);
        if (act_data !== exp_data) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s mismatch exp=0x%08h act=0x%08h", reg_name, exp_data, act_data))
        end
    endtask

    task automatic measure_sclk_half_periods(int unsigned sample_count, ref time periods[$]);
        time prev_toggle_time;
        time curr_toggle_time;

        periods.delete();
        wait (cfg.spi_cfg.vif.spi_cs_n === 1'b0);
        @(cfg.spi_cfg.vif.spi_sclk);
        prev_toggle_time = $time;

        repeat (sample_count) begin
            @(cfg.spi_cfg.vif.spi_sclk);
            curr_toggle_time = $time;
            periods.push_back(curr_toggle_time - prev_toggle_time);
            prev_toggle_time = curr_toggle_time;
        end
    endtask

    task automatic run_div_case(bit [7:0] div_value, byte unsigned tx_byte, byte unsigned rx_byte,
                                bit check_timing = 1'b1, int unsigned sample_count = 4);
        byte unsigned rx_data;
        byte unsigned rsp_q[$];
        time          periods[$];
        time          exp_half_period;
        int unsigned  eff_div;

        eff_div = (div_value == 8'h00) ? 1 : int'(div_value);
        exp_half_period = eff_div * 10ns;

        set_clkdiv(div_value);
        check_reg($sformatf("CLKDIV readback 0x%02h", div_value), REG_CLKDIV_ADDR, {24'h0, div_value});

        rsp_q.delete();
        rsp_q.push_back(rx_byte);
        start_spi_responses_async(rsp_q);
        push_tx_byte(tx_byte);

        if (check_timing) begin
            fork
                begin
                    measure_sclk_half_periods(sample_count, periods);
                end
                begin
                    start_transfer();
                    wait_for_done();
                end
            join

            foreach (periods[idx]) begin
                if (periods[idx] !== exp_half_period) begin
                    `uvm_error(get_type_name(),
                               $sformatf("CLKDIV 0x%02h half-period[%0d] mismatch exp=%0t act=%0t",
                                         div_value, idx, exp_half_period, periods[idx]))
                end
            end
        end else begin
            start_transfer();
            wait_for_done();
        end

        pop_rx_byte(rx_data);
        if (rx_data !== rx_byte) begin
            `uvm_error(get_type_name(),
                       $sformatf("CLKDIV 0x%02h RX mismatch exp=0x%02h act=0x%02h",
                                 div_value, rx_byte, rx_data))
        end

        clear_irq(5'b1_1101);
    endtask

    task body();
        int unsigned rand_div;
        bit [7:0]    rand_div_8;

        cfg_spi_mode(1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1);
        set_irq_enable(5'b1_1111);

        run_div_case(8'h00, 8'h11, 8'h91);
        run_div_case(8'h01, 8'h22, 8'h92);
        run_div_case(8'h02, 8'h33, 8'h93);
        run_div_case(8'h05, 8'h44, 8'h94);
        run_div_case(8'h10, 8'h55, 8'h95);
        run_div_case(8'hff, 8'h66, 8'h96, 1'b0);

        repeat (4) begin
            if (!std::randomize(rand_div) with { rand_div inside {[1:255]}; }) begin
                `uvm_fatal(get_type_name(), "Failed to randomize divider value")
            end

            rand_div_8 = rand_div[7:0];
            run_div_case(rand_div_8,
                         byte'(8'h80 + rand_div[3:0]),
                         byte'(8'h40 + rand_div[3:0]));
        end

        set_clkdiv(8'hff);
        check_reg("CLKDIV max readback", REG_CLKDIV_ADDR, 32'h0000_00ff);
    endtask
endclass
