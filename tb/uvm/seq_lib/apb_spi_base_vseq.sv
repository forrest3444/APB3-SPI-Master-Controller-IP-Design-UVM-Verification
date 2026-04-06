class apb_spi_base_vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(apb_spi_base_vseq)
    `uvm_declare_p_sequencer(apb_spi_virtual_sequencer)

    apb_spi_env_cfg cfg;
    bit [31:0]      ctrl_mirror;

    function new(string name = "apb_spi_base_vseq");
        super.new(name);
        ctrl_mirror = CTRL_RESET_VALUE;
    endfunction

    task pre_body();
        cfg = p_sequencer.cfg;
    endtask

    task apb_write_reg(bit [11:0] addr, bit [31:0] data);
        apb_trans req;

        req = apb_trans::type_id::create("req");
        `uvm_do_on_with(req, p_sequencer.apb_sqr, {
            is_write == 1'b1;
            addr     == local::addr;
            wdata    == local::data;
        })
    endtask

    task apb_read_reg(bit [11:0] addr, output bit [31:0] data);
        apb_trans req;

        req = apb_trans::type_id::create("req");
        `uvm_do_on_with(req, p_sequencer.apb_sqr, {
            is_write == 1'b0;
            addr     == local::addr;
            wdata    == '0;
        })
        data = req.rdata;
    endtask

    task push_tx_byte(byte unsigned data);
        apb_write_reg(REG_TXDATA_ADDR, {24'h0, data});
    endtask

    task pop_rx_byte(output byte unsigned data);
        bit [31:0] rdata;

        apb_read_reg(REG_RXDATA_ADDR, rdata);
        data = rdata[7:0];
    endtask

    task cfg_spi_mode(bit cpol, bit cpha, bit cont = 1'b0, bit rx_en = 1'b1, bit tx_en = 1'b1, bit enable = 1'b1);
        ctrl_mirror = '0;
        ctrl_mirror[CTRL_ENABLE_BIT] = enable;
        ctrl_mirror[CTRL_CPHA_BIT]   = cpha;
        ctrl_mirror[CTRL_CPOL_BIT]   = cpol;
        ctrl_mirror[CTRL_CONT_BIT]   = cont;
        ctrl_mirror[CTRL_RX_EN_BIT]  = rx_en;
        ctrl_mirror[CTRL_TX_EN_BIT]  = tx_en;

        cfg.spi_cfg.default_cpol = cpol;
        cfg.spi_cfg.default_cpha = cpha;
        apb_write_reg(REG_CTRL_ADDR, ctrl_mirror);
    endtask

    task set_clkdiv(bit [7:0] div);
        apb_write_reg(REG_CLKDIV_ADDR, {24'h0, div});
    endtask

    task set_irq_enable(bit [4:0] mask);
        apb_write_reg(REG_IRQ_EN_ADDR, {27'h0, mask});
    endtask

    task clear_irq(bit [4:0] mask);
        apb_write_reg(REG_IRQ_CLEAR_ADDR, {27'h0, mask});
    endtask

    task start_transfer();
        apb_write_reg(REG_CTRL_ADDR, ctrl_mirror | (32'd1 << CTRL_START_BIT));
    endtask

    task start_spi_responses_async(byte unsigned rsp_q[$], bit cont = 1'b0, bit tx_en = 1'b1, bit rx_en = 1'b1);
        spi_base_seq seq;

        seq = spi_base_seq::type_id::create($sformatf("spi_rsp_seq_%0t", $time));
        seq.response_q = rsp_q;
        seq.cpol       = cfg.spi_cfg.default_cpol;
        seq.cpha       = cfg.spi_cfg.default_cpha;
        seq.cont       = cont;
        seq.tx_en      = tx_en;
        seq.rx_en      = rx_en;

        fork
            seq.start(p_sequencer.spi_sqr);
        join_none
    endtask

    task wait_for_done(int unsigned max_reads = 64);
        bit [31:0] status;

        repeat (max_reads) begin
            apb_read_reg(REG_STATUS_ADDR, status);
            if (status[STATUS_DONE_PENDING_BIT] || status[STATUS_TX_UNDERFLOW_PENDING_BIT] || status[STATUS_RX_OVERFLOW_PENDING_BIT]) begin
                return;
            end
        end

        `uvm_error(get_type_name(), "Timed out waiting for completion-related STATUS bit")
    endtask

    task wait_for_rx_level(int unsigned target_level, int unsigned max_reads = 64);
        bit [31:0] lvl;

        repeat (max_reads) begin
            apb_read_reg(REG_RXFIFO_LVL_ADDR, lvl);
            if (lvl >= target_level) begin
                return;
            end
        end

        `uvm_error(get_type_name(), $sformatf("Timed out waiting for RX level %0d", target_level))
    endtask
endclass
