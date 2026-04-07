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

    function automatic apb_spi_reg_block ral();
        if (p_sequencer.ral_model == null) begin
            `uvm_fatal(get_type_name(), "RAL model is not configured on the virtual sequencer")
        end
        return p_sequencer.ral_model;
    endfunction

    task write_reg(uvm_reg rg, bit [31:0] data);
        uvm_status_e    status;

        rg.write(status, data, UVM_FRONTDOOR, ral().default_map, this);
        if (status != UVM_IS_OK) begin
            `uvm_fatal(get_type_name(), $sformatf("RAL write failed for %s", rg.get_full_name()))
        end
    endtask

    task read_reg(uvm_reg rg, output bit [31:0] data);
        uvm_status_e    status;
        uvm_reg_data_t  read_data;

        rg.read(status, read_data, UVM_FRONTDOOR, ral().default_map, this);
        if (status != UVM_IS_OK) begin
            `uvm_fatal(get_type_name(), $sformatf("RAL read failed for %s", rg.get_full_name()))
        end
        data = read_data[31:0];
    endtask

    task bus_write_reg(uvm_reg rg, bit [31:0] data);
        apb_trans       req;
        uvm_reg_addr_t  addr;

        addr = rg.get_address(ral().default_map);
        req = apb_trans::type_id::create("req");
        `uvm_do_on_with(req, p_sequencer.apb_sqr, {
            is_write == 1'b1;
            addr     == local::addr[11:0];
            wdata    == local::data;
        })
    endtask

    task bus_read_reg(uvm_reg rg, output bit [31:0] data);
        apb_trans       req;
        uvm_reg_addr_t  addr;

        addr = rg.get_address(ral().default_map);
        req = apb_trans::type_id::create("req");
        `uvm_do_on_with(req, p_sequencer.apb_sqr, {
            is_write == 1'b0;
            addr     == local::addr[11:0];
            wdata    == '0;
        })
        data = req.rdata;
    endtask

    task check_reg_value(string reg_name, uvm_reg rg, bit [31:0] exp_data);
        bit [31:0] act_data;

        read_reg(rg, act_data);
        if (act_data !== exp_data) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s mismatch exp=0x%08h act=0x%08h",
                                 reg_name, exp_data, act_data))
        end
    endtask

    task check_reg_bits(string reg_name, uvm_reg rg, bit [31:0] mask, bit [31:0] exp_masked);
        bit [31:0] act_data;

        read_reg(rg, act_data);
        if ((act_data & mask) !== exp_masked) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s masked mismatch mask=0x%08h exp=0x%08h act=0x%08h",
                                 reg_name, mask, exp_masked, act_data & mask))
        end
    endtask

    task apb_write_reg(bit [11:0] addr, bit [31:0] data);
        case (addr)
            REG_CTRL_ADDR:       write_reg(ral().ctrl, data);
            REG_STATUS_ADDR:     write_reg(ral().status, data);
            REG_CLKDIV_ADDR:     write_reg(ral().clkdiv, data);
            REG_TXDATA_ADDR:     write_reg(ral().txdata, data);
            REG_RXDATA_ADDR:     write_reg(ral().rxdata, data);
            REG_IRQ_EN_ADDR:     write_reg(ral().irq_en, data);
            REG_IRQ_RAW_ADDR:    write_reg(ral().irq_raw, data);
            REG_IRQ_STATUS_ADDR: write_reg(ral().irq_status, data);
            REG_IRQ_CLEAR_ADDR:  write_reg(ral().irq_clear, data);
            REG_TXFIFO_LVL_ADDR: write_reg(ral().txfifo_lvl, data);
            REG_RXFIFO_LVL_ADDR: write_reg(ral().rxfifo_lvl, data);
            REG_VERSION_ADDR:    write_reg(ral().version, data);
            default: `uvm_fatal(get_type_name(), $sformatf("Unsupported register address 0x%03h", addr))
        endcase
    endtask

    task apb_read_reg(bit [11:0] addr, output bit [31:0] data);
        case (addr)
            REG_CTRL_ADDR:       read_reg(ral().ctrl, data);
            REG_STATUS_ADDR:     read_reg(ral().status, data);
            REG_CLKDIV_ADDR:     read_reg(ral().clkdiv, data);
            REG_TXDATA_ADDR:     read_reg(ral().txdata, data);
            REG_RXDATA_ADDR:     read_reg(ral().rxdata, data);
            REG_IRQ_EN_ADDR:     read_reg(ral().irq_en, data);
            REG_IRQ_RAW_ADDR:    read_reg(ral().irq_raw, data);
            REG_IRQ_STATUS_ADDR: read_reg(ral().irq_status, data);
            REG_IRQ_CLEAR_ADDR:  read_reg(ral().irq_clear, data);
            REG_TXFIFO_LVL_ADDR: read_reg(ral().txfifo_lvl, data);
            REG_RXFIFO_LVL_ADDR: read_reg(ral().rxfifo_lvl, data);
            REG_VERSION_ADDR:    read_reg(ral().version, data);
            default: `uvm_fatal(get_type_name(), $sformatf("Unsupported register address 0x%03h", addr))
        endcase
    endtask

    task push_tx_byte(byte unsigned data);
        write_reg(ral().txdata, {24'h0, data});
    endtask

    task pop_rx_byte(output byte unsigned data);
        bit [31:0] rdata;

        read_reg(ral().rxdata, rdata);
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
        write_reg(ral().ctrl, ctrl_mirror);
    endtask

    task set_clkdiv(bit [7:0] div);
        write_reg(ral().clkdiv, {24'h0, div});
    endtask

    task set_irq_enable(bit [4:0] mask);
        write_reg(ral().irq_en, {27'h0, mask});
    endtask

    task clear_irq(bit [4:0] mask);
        write_reg(ral().irq_clear, {27'h0, mask});
    endtask

    task start_transfer();
        write_reg(ral().ctrl, ctrl_mirror | (32'd1 << CTRL_START_BIT));
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
            read_reg(ral().status, status);
            if (status[STATUS_DONE_PENDING_BIT] || status[STATUS_TX_UNDERFLOW_PENDING_BIT] || status[STATUS_RX_OVERFLOW_PENDING_BIT]) begin
                return;
            end
        end

        `uvm_error(get_type_name(), "Timed out waiting for completion-related STATUS bit")
    endtask

    task wait_for_rx_level(int unsigned target_level, int unsigned max_reads = 64);
        bit [31:0] lvl;

        repeat (max_reads) begin
            read_reg(ral().rxfifo_lvl, lvl);
            if (lvl >= target_level) begin
                return;
            end
        end

        `uvm_error(get_type_name(), $sformatf("Timed out waiting for RX level %0d", target_level))
    endtask

    task wait_for_cs_assert(int unsigned max_pclk_cycles = 256);
        repeat (max_pclk_cycles) begin
            @(posedge cfg.apb_cfg.vif.pclk);
            if (cfg.spi_cfg.vif.spi_cs_n === 1'b0) begin
                return;
            end
        end

        `uvm_error(get_type_name(), "Timed out waiting for CS assertion")
    endtask

    task wait_for_cs_release(int unsigned max_pclk_cycles = 256);
        repeat (max_pclk_cycles) begin
            @(posedge cfg.apb_cfg.vif.pclk);
            if ((cfg.spi_cfg.vif.spi_cs_n === 1'b1) &&
                (cfg.spi_cfg.vif.spi_sclk === cfg.spi_cfg.default_cpol)) begin
                return;
            end
        end

        `uvm_error(get_type_name(), "Timed out waiting for CS release")
    endtask

    task wait_for_transfer_idle(int unsigned exp_rx_level = 0,
                                int unsigned max_pclk_cycles = 256);
        wait_for_cs_assert(max_pclk_cycles);
        wait_for_cs_release(max_pclk_cycles);

        if (exp_rx_level != 0) begin
            wait_for_rx_level(exp_rx_level, max_pclk_cycles);
        end

        @(posedge cfg.apb_cfg.vif.pclk);
    endtask
endclass
