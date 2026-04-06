class cont_mode_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(cont_mode_vseq)

    function new(string name = "cont_mode_vseq");
        super.new(name);
    endfunction

    task automatic check_bits(string reg_name, bit [11:0] addr, bit [31:0] mask, bit [31:0] exp_masked);
        bit [31:0] act_data;

        apb_read_reg(addr, act_data);
        if ((act_data & mask) !== exp_masked) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s masked mismatch mask=0x%08h exp=0x%08h act=0x%08h",
                                 reg_name, mask, exp_masked, act_data & mask))
        end
    endtask

    task body();
        byte unsigned rsp_q[$];
        byte unsigned rx_byte;
        time          one_frame_time;

        cfg_spi_mode(1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1);
        set_clkdiv(16'd16);
        set_irq_enable(5'b1_1111);

        rsp_q.push_back(8'h31);
        rsp_q.push_back(8'h32);
        rsp_q.push_back(8'h33);
        rsp_q.push_back(8'h34);
        start_spi_responses_async(rsp_q, 1'b1);

        push_tx_byte(8'ha1);
        push_tx_byte(8'ha2);
        push_tx_byte(8'ha3);
        push_tx_byte(8'ha4);

        one_frame_time = 16 * 16 * 10ns;
        start_transfer();

        @(negedge cfg.spi_cfg.vif.spi_cs_n);
        #(one_frame_time + (one_frame_time / 2));
        if (cfg.spi_cfg.vif.spi_cs_n !== 1'b0) begin
            `uvm_error(get_type_name(), "CS deasserted before continuous transfer completed")
        end

        wait_for_rx_level(1);
        check_bits("STATUS mid continuous transfer", REG_STATUS_ADDR,
                   (32'd1 << STATUS_BUSY_BIT) | (32'd1 << STATUS_CS_ACTIVE_BIT),
                   (32'd1 << STATUS_BUSY_BIT) | (32'd1 << STATUS_CS_ACTIVE_BIT));

        wait_for_rx_level(4);
        wait_for_done();
        @(posedge cfg.apb_cfg.vif.pclk);

        if (cfg.spi_cfg.vif.spi_cs_n !== 1'b1) begin
            `uvm_error(get_type_name(), "CS did not release after continuous transfer completed")
        end

        check_bits("STATUS after continuous transfer", REG_STATUS_ADDR,
                   (32'd1 << STATUS_BUSY_BIT) | (32'd1 << STATUS_CS_ACTIVE_BIT),
                   '0);

        for (int idx = 0; idx < 4; idx++) begin
            pop_rx_byte(rx_byte);
            if (rx_byte !== byte'(8'h31 + idx)) begin
                `uvm_error(get_type_name(),
                           $sformatf("Continuous RX mismatch idx=%0d exp=0x%02h act=0x%02h",
                                     idx, byte'(8'h31 + idx), rx_byte))
            end
        end

        clear_irq(5'b1_1001);
    endtask
endclass
