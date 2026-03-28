class apb_spi_scoreboard extends uvm_component;
    `uvm_component_utils(apb_spi_scoreboard)

    uvm_analysis_imp_apb #(apb_trans, apb_spi_scoreboard) apb_imp;
    uvm_analysis_imp_spi #(spi_frame, apb_spi_scoreboard) spi_imp;

    bit [7:0] expected_tx_q[$];
    bit [7:0] expected_rx_q[$];
    bit [7:0] pending_rx_q[$];

    bit       cfg_enable;
    bit       cfg_cpha;
    bit       cfg_cpol;
    bit       cfg_cont;
    bit       cfg_rx_en;
    bit       cfg_tx_en;
    bit [4:0] irq_en;
    bit [4:0] sticky_irq;
    int       tx_fifo_level;
    int       rx_fifo_level;
    int       last_cs_window = -1;
    int       last_frame_idx = -1;
    bit       pending_done;
    bit       pending_rx_overflow;

    function new(string name = "apb_spi_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        apb_imp = new("apb_imp", this);
        spi_imp = new("spi_imp", this);
    endfunction

    function bit has_pending_frame_updates();
        return pending_done || pending_rx_overflow || (pending_rx_q.size() != 0);
    endfunction

    function void commit_pending_frame_updates();
        while (pending_rx_q.size() != 0) begin
            if (expected_rx_q.size() < 8) begin
                expected_rx_q.push_back(pending_rx_q.pop_front());
                rx_fifo_level++;
            end else begin
                void'(pending_rx_q.pop_front());
                pending_rx_overflow = 1'b1;
            end
        end

        if (pending_rx_overflow) begin
            sticky_irq[IRQ_RX_OVERFLOW_BIT] = 1'b1;
        end

        if (pending_done) begin
            sticky_irq[IRQ_DONE_BIT] = 1'b1;
        end

        pending_done        = 1'b0;
        pending_rx_overflow = 1'b0;
    endfunction

    function void write_apb(apb_trans tr);
        bit [31:0] exp_status;
        bit [31:0] exp_irq_raw;
        bit [31:0] exp_irq_status;
        bit [7:0]  exp_rx;
        bit        defer_pending_commit;

        defer_pending_commit = !tr.is_write && (tr.addr == REG_STATUS_ADDR) && has_pending_frame_updates();

        if (!defer_pending_commit) begin
            commit_pending_frame_updates();
        end

        if (tr.is_write) begin
            case (tr.addr)
                REG_CTRL_ADDR: begin
                    cfg_enable = tr.wdata[CTRL_ENABLE_BIT];
                    cfg_cpha   = tr.wdata[CTRL_CPHA_BIT];
                    cfg_cpol   = tr.wdata[CTRL_CPOL_BIT];
                    cfg_cont   = tr.wdata[CTRL_CONT_BIT];
                    cfg_rx_en  = tr.wdata[CTRL_RX_EN_BIT];
                    cfg_tx_en  = tr.wdata[CTRL_TX_EN_BIT];

                    if (tr.wdata[CTRL_SOFT_RESET_BIT]) begin
                        expected_tx_q.delete();
                        expected_rx_q.delete();
                        pending_rx_q.delete();
                        sticky_irq    = '0;
                        tx_fifo_level = 0;
                        rx_fifo_level = 0;
                        pending_done        = 1'b0;
                        pending_rx_overflow = 1'b0;
                    end

                    if (tr.wdata[CTRL_START_BIT] && cfg_enable) begin
                        if (cfg_tx_en && (tx_fifo_level == 0)) begin
                            sticky_irq[IRQ_TX_UNDERFLOW_BIT] = 1'b1;
                        end else if (cfg_tx_en && (tx_fifo_level > 0)) begin
                            tx_fifo_level--;
                        end
                    end
                end

                REG_TXDATA_ADDR: begin
                    if (tx_fifo_level < 8) begin
                        expected_tx_q.push_back(tr.wdata[7:0]);
                        tx_fifo_level++;
                    end
                end

                REG_IRQ_EN_ADDR: begin
                    irq_en = tr.wdata[4:0];
                end

                REG_IRQ_CLEAR_ADDR: begin
                    if (tr.wdata[IRQ_DONE_BIT]) begin
                        sticky_irq[IRQ_DONE_BIT] = 1'b0;
                    end
                    if (tr.wdata[IRQ_TX_UNDERFLOW_BIT]) begin
                        sticky_irq[IRQ_TX_UNDERFLOW_BIT] = 1'b0;
                    end
                    if (tr.wdata[IRQ_RX_OVERFLOW_BIT]) begin
                        sticky_irq[IRQ_RX_OVERFLOW_BIT] = 1'b0;
                    end
                end

                default: begin
                end
            endcase
        end else begin
            case (tr.addr)
                REG_RXDATA_ADDR: begin
                    exp_rx = (expected_rx_q.size() == 0) ? 8'h00 : expected_rx_q.pop_front();
                    if (tr.rdata[7:0] !== exp_rx) begin
                        `uvm_error(get_type_name(),
                                   $sformatf("RXDATA mismatch exp=0x%02h act=0x%02h", exp_rx, tr.rdata[7:0]))
                    end
                    if (rx_fifo_level > 0) begin
                        rx_fifo_level--;
                    end
                end

                REG_STATUS_ADDR: begin
                    exp_status = '0;
                    exp_status[STATUS_TX_EMPTY_BIT]             = (tx_fifo_level == 0);
                    exp_status[STATUS_TX_FULL_BIT]              = (tx_fifo_level == 8);
                    exp_status[STATUS_RX_EMPTY_BIT]             = (rx_fifo_level == 0);
                    exp_status[STATUS_RX_FULL_BIT]              = (rx_fifo_level == 8);
                    if ((tr.rdata & 32'h1e) !== exp_status) begin
                        `uvm_error(get_type_name(),
                                   $sformatf("STATUS mismatch exp=0x%08h act=0x%08h", exp_status, tr.rdata & 32'h1e))
                    end
                end

                REG_IRQ_RAW_ADDR: begin
                    exp_irq_raw = '0;
                    exp_irq_raw[IRQ_DONE_BIT]         = sticky_irq[IRQ_DONE_BIT];
                    exp_irq_raw[IRQ_TX_EMPTY_BIT]     = (tx_fifo_level == 0);
                    exp_irq_raw[IRQ_RX_NOT_EMPTY_BIT] = (rx_fifo_level != 0);
                    exp_irq_raw[IRQ_TX_UNDERFLOW_BIT] = sticky_irq[IRQ_TX_UNDERFLOW_BIT];
                    exp_irq_raw[IRQ_RX_OVERFLOW_BIT]  = sticky_irq[IRQ_RX_OVERFLOW_BIT];
                    if (tr.rdata[4:0] !== exp_irq_raw[4:0]) begin
                        `uvm_error(get_type_name(),
                                   $sformatf("IRQ_RAW mismatch exp=0x%02h act=0x%02h", exp_irq_raw[4:0], tr.rdata[4:0]))
                    end
                end

                REG_IRQ_STATUS_ADDR: begin
                    exp_irq_status = '0;
                    exp_irq_status[IRQ_DONE_BIT]         = sticky_irq[IRQ_DONE_BIT] & irq_en[IRQ_DONE_BIT];
                    exp_irq_status[IRQ_TX_EMPTY_BIT]     = (tx_fifo_level == 0) & irq_en[IRQ_TX_EMPTY_BIT];
                    exp_irq_status[IRQ_RX_NOT_EMPTY_BIT] = (rx_fifo_level != 0) & irq_en[IRQ_RX_NOT_EMPTY_BIT];
                    exp_irq_status[IRQ_TX_UNDERFLOW_BIT] = sticky_irq[IRQ_TX_UNDERFLOW_BIT] & irq_en[IRQ_TX_UNDERFLOW_BIT];
                    exp_irq_status[IRQ_RX_OVERFLOW_BIT]  = sticky_irq[IRQ_RX_OVERFLOW_BIT] & irq_en[IRQ_RX_OVERFLOW_BIT];
                    if (tr.rdata[4:0] !== exp_irq_status[4:0]) begin
                        `uvm_error(get_type_name(),
                                   $sformatf("IRQ_STATUS mismatch exp=0x%02h act=0x%02h",
                                             exp_irq_status[4:0], tr.rdata[4:0]))
                    end
                end

                default: begin
                end
            endcase
        end

        if (defer_pending_commit) begin
            commit_pending_frame_updates();
        end
    endfunction

    function void write_spi(spi_frame tr);
        bit [7:0] exp_tx;

        if (cfg_tx_en) begin
            if (expected_tx_q.size() == 0) begin
                `uvm_error(get_type_name(),
                           $sformatf("Observed SPI TX byte 0x%02h with empty expected queue", tr.tx_byte))
            end else begin
                exp_tx = expected_tx_q.pop_front();
                if (tr.tx_byte !== exp_tx) begin
                    `uvm_error(get_type_name(),
                               $sformatf("SPI TX mismatch exp=0x%02h act=0x%02h", exp_tx, tr.tx_byte))
                end
            end
        end

        if (cfg_rx_en) begin
            if ((expected_rx_q.size() + pending_rx_q.size()) < 8) begin
                pending_rx_q.push_back(tr.rx_byte);
            end else begin
                pending_rx_overflow = 1'b1;
            end
        end

        pending_done = 1'b1;

        if (cfg_cont && (last_cs_window == tr.cs_window_id) && (last_frame_idx >= 0) &&
            (tr.frame_idx != (last_frame_idx + 1))) begin
            `uvm_error(get_type_name(),
                       $sformatf("Continuous mode frame order broke within window %0d: prev=%0d curr=%0d",
                                 tr.cs_window_id, last_frame_idx, tr.frame_idx))
        end

        last_cs_window = tr.cs_window_id;
        last_frame_idx = tr.frame_idx;
    endfunction
endclass
