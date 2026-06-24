class apb_spi_coverage extends uvm_component;
    `uvm_component_utils(apb_spi_coverage)

    uvm_analysis_imp_apb #(apb_trans, apb_spi_coverage) apb_imp;
    uvm_analysis_imp_spi #(spi_frame, apb_spi_coverage) spi_imp;

    bit          cg_cpol;
    bit          cg_cpha;
    bit          cg_cont;
    bit          cg_tx_en;
    bit          cg_rx_en;
    int unsigned cg_clkdiv;
    int unsigned cg_tx_level;
    int unsigned cg_rx_level;
    int unsigned cg_irq_kind;
    bit          cg_is_multi;
    int unsigned last_window_id;

    covergroup cfg_cg;
        option.per_instance = 1;
        cp_mode: coverpoint {cg_cpol, cg_cpha} { bins modes[] = {[0:3]}; }
        cp_cont: coverpoint cg_cont { bins off = {0}; bins on = {1}; }
        cp_txrx: coverpoint {cg_tx_en, cg_rx_en} { bins combos[] = {[0:3]}; }
        cp_clkdiv: coverpoint cg_clkdiv {
            bins min  = {[1:2]};
            bins mid  = {[3:8]};
            bins high = {[9:$]};
        }
        mode_cross: cross cp_mode, cp_cont, cp_txrx;
    endgroup

    covergroup fifo_cg;
        option.per_instance = 1;
        cp_tx_level: coverpoint cg_tx_level {
            bins empty = {0};
            bins mid[] = {[1:7]};
            bins full = {8};
        }
        cp_rx_level: coverpoint cg_rx_level {
            bins empty = {0};
            bins mid[] = {[1:7]};
            bins full = {8};
        }
    endgroup

    covergroup irq_cg;
        option.per_instance = 1;
        cp_irq: coverpoint cg_irq_kind {
            bins done         = {IRQ_DONE_BIT};
            bins tx_empty     = {IRQ_TX_EMPTY_BIT};
            bins rx_not_empty = {IRQ_RX_NOT_EMPTY_BIT};
            bins underflow    = {IRQ_TX_UNDERFLOW_BIT};
            bins overflow     = {IRQ_RX_OVERFLOW_BIT};
        }
    endgroup

    covergroup frame_cg;
        option.per_instance = 1;
        cp_multi_frame: coverpoint cg_is_multi { bins single = {0}; bins multi = {1}; }
    endgroup

    function new(string name = "apb_spi_coverage", uvm_component parent = null);
        super.new(name, parent);
        apb_imp  = new("apb_imp", this);
        spi_imp  = new("spi_imp", this);
        cfg_cg   = new();
        fifo_cg  = new();
        irq_cg   = new();
        frame_cg = new();
    endfunction

    function void write_apb(apb_trans tr);
        if (tr.is_write) begin
            case (tr.addr)
                REG_CTRL_ADDR: begin
                    cg_cpha  = tr.wdata[CTRL_CPHA_BIT];
                    cg_cpol  = tr.wdata[CTRL_CPOL_BIT];
                    cg_cont  = tr.wdata[CTRL_CONT_BIT];
                    cg_rx_en = tr.wdata[CTRL_RX_EN_BIT];
                    cg_tx_en = tr.wdata[CTRL_TX_EN_BIT];
                    cfg_cg.sample();
                end

                REG_CLKDIV_ADDR: begin
                    cg_clkdiv = (tr.wdata[7:0] == 0) ? 1 : tr.wdata[7:0];
                    cfg_cg.sample();
                end

                default: begin
                end
            endcase
        end else begin
            case (tr.addr)
                REG_STATUS_ADDR: begin
                    cg_tx_level = tr.rdata[STATUS_TX_EMPTY_BIT] ? 0 : (tr.rdata[STATUS_TX_FULL_BIT] ? 8 : 1);
                    cg_rx_level = tr.rdata[STATUS_RX_EMPTY_BIT] ? 0 : (tr.rdata[STATUS_RX_FULL_BIT] ? 8 : 1);
                    fifo_cg.sample();

                    if (tr.rdata[STATUS_DONE_PENDING_BIT]) begin
                        cg_irq_kind = IRQ_DONE_BIT;
                        irq_cg.sample();
                    end
                    if (tr.rdata[STATUS_TX_UNDERFLOW_PENDING_BIT]) begin
                        cg_irq_kind = IRQ_TX_UNDERFLOW_BIT;
                        irq_cg.sample();
                    end
                    if (tr.rdata[STATUS_RX_OVERFLOW_PENDING_BIT]) begin
                        cg_irq_kind = IRQ_RX_OVERFLOW_BIT;
                        irq_cg.sample();
                    end
                end

                REG_IRQ_RAW_ADDR,
                REG_IRQ_STATUS_ADDR: begin
                    if (tr.rdata[IRQ_TX_EMPTY_BIT]) begin
                        cg_irq_kind = IRQ_TX_EMPTY_BIT;
                        irq_cg.sample();
                    end
                    if (tr.rdata[IRQ_RX_NOT_EMPTY_BIT]) begin
                        cg_irq_kind = IRQ_RX_NOT_EMPTY_BIT;
                        irq_cg.sample();
                    end
                end

                default: begin
                end
            endcase
        end
    endfunction

    function void write_spi(spi_frame tr);
        cg_is_multi   = (tr.cs_window_id == last_window_id);
        last_window_id = tr.cs_window_id;
        frame_cg.sample();
    endfunction
endclass
