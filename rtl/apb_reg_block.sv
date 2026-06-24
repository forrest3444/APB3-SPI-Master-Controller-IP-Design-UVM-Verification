module apb_reg_block #(
    parameter int unsigned APB_ADDR_W = 12,
    parameter int unsigned CLKDIV_W   = 8,
    parameter int unsigned FIFO_LVL_W = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   psel,
    input  logic                   penable,
    input  logic                   pwrite,
    input  logic [APB_ADDR_W-1:0]  paddr,
    input  logic [31:0]            pwdata,
    output logic [31:0]            prdata,
    output logic                   pready,
    output logic                   pslverr,

    output logic                   cfg_enable,
    output logic                   cfg_cpha,
    output logic                   cfg_cpol,
    output logic                   cfg_cont,
    output logic                   cfg_rx_en,
    output logic                   cfg_tx_en,
    output logic [CLKDIV_W-1:0]    cfg_clkdiv,

    output logic                   start_pulse,
    output logic                   soft_reset_pulse,

    output logic                   tx_fifo_wen,
    output logic [7:0]             tx_fifo_wdata,

    output logic                   rx_fifo_ren,
    input  logic [7:0]             rx_fifo_rdata,

    input  logic                   status_busy,
    input  logic                   status_tx_empty,
    input  logic                   status_tx_full,
    input  logic                   status_rx_empty,
    input  logic                   status_rx_full,
    input  logic                   status_cs_active,

    input  logic                   evt_done_pending,
    input  logic                   evt_tx_underflow_pending,
    input  logic                   evt_rx_overflow_pending,

    input  logic [FIFO_LVL_W-1:0]  tx_fifo_level,
    input  logic [FIFO_LVL_W-1:0]  rx_fifo_level,

    output logic [4:0]             irq_en,
    input  logic [4:0]             irq_raw,
    input  logic [4:0]             irq_status,
    output logic [4:0]             irq_clear
);

    import apb_spi_pkg::*;

    logic [4:0]  irq_en_q;
    logic        write_access;
    logic        read_access;
    logic [11:0] addr_dec;

    assign write_access = psel && penable && pwrite;
    assign read_access  = psel && penable && !pwrite;
    assign addr_dec     = 12'(paddr);

    assign pready  = 1'b1;
    assign pslverr = 1'b0;

    assign start_pulse      = write_access && (addr_dec == REG_CTRL_ADDR) && pwdata[CTRL_START_BIT];
    assign soft_reset_pulse = write_access && (addr_dec == REG_CTRL_ADDR) && pwdata[CTRL_SOFT_RESET_BIT];
    assign tx_fifo_wen      = write_access && (addr_dec == REG_TXDATA_ADDR) && !status_tx_full;
    assign tx_fifo_wdata    = pwdata[7:0];
    assign rx_fifo_ren      = read_access && (addr_dec == REG_RXDATA_ADDR) && !status_rx_empty;
    assign irq_clear        = (write_access && (addr_dec == REG_IRQ_CLEAR_ADDR)) ? pwdata[4:0] : '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_enable <= CTRL_RESET_VALUE[CTRL_ENABLE_BIT];
            cfg_cpha   <= CTRL_RESET_VALUE[CTRL_CPHA_BIT];
            cfg_cpol   <= CTRL_RESET_VALUE[CTRL_CPOL_BIT];
            cfg_cont   <= CTRL_RESET_VALUE[CTRL_CONT_BIT];
            cfg_rx_en  <= CTRL_RESET_VALUE[CTRL_RX_EN_BIT];
            cfg_tx_en  <= CTRL_RESET_VALUE[CTRL_TX_EN_BIT];
            cfg_clkdiv <= CLKDIV_W'(CLKDIV_RESET_VALUE);
            irq_en_q   <= '0;
        end else begin
            if (write_access && (addr_dec == REG_CTRL_ADDR)) begin
                cfg_enable <= pwdata[CTRL_ENABLE_BIT];
                cfg_cpha   <= pwdata[CTRL_CPHA_BIT];
                cfg_cpol   <= pwdata[CTRL_CPOL_BIT];
                cfg_cont   <= pwdata[CTRL_CONT_BIT];
                cfg_rx_en  <= pwdata[CTRL_RX_EN_BIT];
                cfg_tx_en  <= pwdata[CTRL_TX_EN_BIT];
            end

            if (write_access && (addr_dec == REG_CLKDIV_ADDR)) begin
                cfg_clkdiv <= pwdata[CLKDIV_W-1:0];
            end

            if (write_access && (addr_dec == REG_IRQ_EN_ADDR)) begin
                irq_en_q <= pwdata[4:0];
            end
        end
    end

    always_comb begin
        prdata = '0;

        case (addr_dec)
            REG_CTRL_ADDR: begin
                prdata[CTRL_ENABLE_BIT] = cfg_enable;
                prdata[CTRL_CPHA_BIT]   = cfg_cpha;
                prdata[CTRL_CPOL_BIT]   = cfg_cpol;
                prdata[CTRL_CONT_BIT]   = cfg_cont;
                prdata[CTRL_RX_EN_BIT]  = cfg_rx_en;
                prdata[CTRL_TX_EN_BIT]  = cfg_tx_en;
            end

            REG_STATUS_ADDR: begin
                prdata[STATUS_BUSY_BIT]                 = status_busy;
                prdata[STATUS_TX_EMPTY_BIT]             = status_tx_empty;
                prdata[STATUS_TX_FULL_BIT]              = status_tx_full;
                prdata[STATUS_RX_EMPTY_BIT]             = status_rx_empty;
                prdata[STATUS_RX_FULL_BIT]              = status_rx_full;
                prdata[STATUS_CS_ACTIVE_BIT]            = status_cs_active;
                prdata[STATUS_DONE_PENDING_BIT]         = evt_done_pending;
                prdata[STATUS_TX_UNDERFLOW_PENDING_BIT] = evt_tx_underflow_pending;
                prdata[STATUS_RX_OVERFLOW_PENDING_BIT]  = evt_rx_overflow_pending;
            end

            REG_CLKDIV_ADDR: begin
                prdata[CLKDIV_W-1:0] = cfg_clkdiv;
            end

            REG_RXDATA_ADDR: begin
                prdata[7:0] = status_rx_empty ? 8'h00 : rx_fifo_rdata;
            end

            REG_IRQ_EN_ADDR: begin
                prdata[4:0] = irq_en_q;
            end

            REG_IRQ_RAW_ADDR: begin
                prdata[4:0] = irq_raw;
            end

            REG_IRQ_STATUS_ADDR: begin
                prdata[4:0] = irq_status;
            end

            REG_TXFIFO_LVL_ADDR: begin
                prdata[FIFO_LVL_W-1:0] = tx_fifo_level;
            end

            REG_RXFIFO_LVL_ADDR: begin
                prdata[FIFO_LVL_W-1:0] = rx_fifo_level;
            end

            REG_VERSION_ADDR: begin
                prdata = VERSION_RESET_VALUE;
            end

            default: begin
                prdata = '0;
            end
        endcase
    end

    assign irq_en = irq_en_q;

endmodule
