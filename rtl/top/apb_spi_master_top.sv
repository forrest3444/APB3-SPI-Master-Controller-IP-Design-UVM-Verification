module apb_spi_master_top #(
    parameter int unsigned APB_ADDR_W    = 12,
    parameter int unsigned TX_FIFO_DEPTH = 8,
    parameter int unsigned RX_FIFO_DEPTH = 8,
    parameter int unsigned CLKDIV_W      = 16
)(
    input  logic                   PCLK,
    input  logic                   PRESETn,

    input  logic                   PSEL,
    input  logic                   PENABLE,
    input  logic                   PWRITE,
    input  logic [APB_ADDR_W-1:0]  PADDR,
    input  logic [31:0]            PWDATA,
    output logic [31:0]            PRDATA,
    output logic                   PREADY,
    output logic                   PSLVERR,

    output logic                   spi_sclk,
    output logic                   spi_mosi,
    input  logic                   spi_miso,
    output logic                   spi_cs_n,

    output logic                   irq
);

    import apb_spi_pkg::*;

    localparam int unsigned TX_FIFO_LVL_W = $clog2(TX_FIFO_DEPTH + 1);
    localparam int unsigned RX_FIFO_LVL_W = $clog2(RX_FIFO_DEPTH + 1);
    localparam int unsigned FIFO_LVL_W    = (TX_FIFO_LVL_W > RX_FIFO_LVL_W) ? TX_FIFO_LVL_W : RX_FIFO_LVL_W;

    logic                 cfg_enable;
    logic                 cfg_cpha;
    logic                 cfg_cpol;
    logic                 cfg_cont;
    logic                 cfg_rx_en;
    logic                 cfg_tx_en;
    logic [CLKDIV_W-1:0]  cfg_clkdiv;

    logic                 start_pulse;
    logic                 soft_reset_pulse;

    logic                 tx_fifo_wen;
    logic [7:0]           tx_fifo_wdata;
    logic                 tx_fifo_ren;
    logic [7:0]           tx_fifo_rdata;
    logic                 tx_fifo_full;
    logic                 tx_fifo_empty;
    logic [TX_FIFO_LVL_W-1:0] tx_fifo_level;
    logic [FIFO_LVL_W-1:0]    tx_fifo_level_apb;

    logic                 rx_fifo_wen;
    logic [7:0]           rx_fifo_wdata;
    logic                 rx_fifo_ren;
    logic [7:0]           rx_fifo_rdata;
    logic                 rx_fifo_full;
    logic                 rx_fifo_empty;
    logic [RX_FIFO_LVL_W-1:0] rx_fifo_level;
    logic [FIFO_LVL_W-1:0]    rx_fifo_level_apb;

    logic                 status_busy;
    logic                 status_cs_active;

    logic                 evt_done;
    logic                 evt_tx_underflow;
    logic                 evt_rx_overflow;

    logic [4:0]           irq_en;
    logic [4:0]           irq_clear;
    logic [4:0]           irq_raw;
    logic [4:0]           irq_status;

    logic                 fifo_rst_n;

    assign fifo_rst_n       = PRESETn && !soft_reset_pulse;
    assign tx_fifo_level_apb = FIFO_LVL_W'(tx_fifo_level);
    assign rx_fifo_level_apb = FIFO_LVL_W'(rx_fifo_level);

    apb_reg_block #(
        .APB_ADDR_W (APB_ADDR_W),
        .CLKDIV_W   (CLKDIV_W),
        .FIFO_LVL_W (FIFO_LVL_W)
    ) u_apb_reg_block (
        .clk                      (PCLK),
        .rst_n                    (PRESETn),
        .psel                     (PSEL),
        .penable                  (PENABLE),
        .pwrite                   (PWRITE),
        .paddr                    (PADDR),
        .pwdata                   (PWDATA),
        .prdata                   (PRDATA),
        .pready                   (PREADY),
        .pslverr                  (PSLVERR),
        .cfg_enable               (cfg_enable),
        .cfg_cpha                 (cfg_cpha),
        .cfg_cpol                 (cfg_cpol),
        .cfg_cont                 (cfg_cont),
        .cfg_rx_en                (cfg_rx_en),
        .cfg_tx_en                (cfg_tx_en),
        .cfg_clkdiv               (cfg_clkdiv),
        .start_pulse              (start_pulse),
        .soft_reset_pulse         (soft_reset_pulse),
        .tx_fifo_wen              (tx_fifo_wen),
        .tx_fifo_wdata            (tx_fifo_wdata),
        .rx_fifo_ren              (rx_fifo_ren),
        .rx_fifo_rdata            (rx_fifo_rdata),
        .status_busy              (status_busy),
        .status_tx_empty          (tx_fifo_empty),
        .status_tx_full           (tx_fifo_full),
        .status_rx_empty          (rx_fifo_empty),
        .status_rx_full           (rx_fifo_full),
        .status_cs_active         (status_cs_active),
        .evt_done_pending         (irq_raw[IRQ_DONE_BIT]),
        .evt_tx_underflow_pending (irq_raw[IRQ_TX_UNDERFLOW_BIT]),
        .evt_rx_overflow_pending  (irq_raw[IRQ_RX_OVERFLOW_BIT]),
        .tx_fifo_level            (tx_fifo_level_apb),
        .rx_fifo_level            (rx_fifo_level_apb),
        .irq_en                   (irq_en),
        .irq_raw                  (irq_raw),
        .irq_status               (irq_status),
        .irq_clear                (irq_clear)
    );

    spi_ctrl #(
        .CLKDIV_W (CLKDIV_W)
    ) u_spi_ctrl (
        .clk               (PCLK),
        .rst_n             (PRESETn),
        .cfg_enable        (cfg_enable),
        .cfg_cpha          (cfg_cpha),
        .cfg_cpol          (cfg_cpol),
        .cfg_cont          (cfg_cont),
        .cfg_rx_en         (cfg_rx_en),
        .cfg_tx_en         (cfg_tx_en),
        .cfg_clkdiv        (cfg_clkdiv),
        .start_pulse       (start_pulse),
        .soft_reset_pulse  (soft_reset_pulse),
        .tx_fifo_ren       (tx_fifo_ren),
        .tx_fifo_rdata     (tx_fifo_rdata),
        .tx_fifo_empty     (tx_fifo_empty),
        .rx_fifo_wen       (rx_fifo_wen),
        .rx_fifo_wdata     (rx_fifo_wdata),
        .rx_fifo_full      (rx_fifo_full),
        .spi_sclk          (spi_sclk),
        .spi_mosi          (spi_mosi),
        .spi_miso          (spi_miso),
        .spi_cs_n          (spi_cs_n),
        .status_busy       (status_busy),
        .status_cs_active  (status_cs_active),
        .evt_done          (evt_done),
        .evt_tx_underflow  (evt_tx_underflow),
        .evt_rx_overflow   (evt_rx_overflow)
    );

    irq_ctrl u_irq_ctrl (
        .clk               (PCLK),
        .rst_n             (PRESETn),
        .soft_reset_pulse  (soft_reset_pulse),
        .evt_done          (evt_done),
        .evt_tx_underflow  (evt_tx_underflow),
        .evt_rx_overflow   (evt_rx_overflow),
        .level_tx_empty    (tx_fifo_empty),
        .level_rx_not_empty(!rx_fifo_empty),
        .irq_en            (irq_en),
        .irq_clear         (irq_clear),
        .irq_raw           (irq_raw),
        .irq_status        (irq_status),
        .irq               (irq)
    );

    sync_fifo #(
        .WIDTH (8),
        .DEPTH (TX_FIFO_DEPTH)
    ) u_tx_fifo (
        .clk    (PCLK),
        .rst_n  (fifo_rst_n),
        .w_en   (tx_fifo_wen),
        .w_data (tx_fifo_wdata),
        .full   (tx_fifo_full),
        .r_en   (tx_fifo_ren),
        .r_data (tx_fifo_rdata),
        .empty  (tx_fifo_empty),
        .level  (tx_fifo_level)
    );

    sync_fifo #(
        .WIDTH (8),
        .DEPTH (RX_FIFO_DEPTH)
    ) u_rx_fifo (
        .clk    (PCLK),
        .rst_n  (fifo_rst_n),
        .w_en   (rx_fifo_wen),
        .w_data (rx_fifo_wdata),
        .full   (rx_fifo_full),
        .r_en   (rx_fifo_ren),
        .r_data (rx_fifo_rdata),
        .empty  (rx_fifo_empty),
        .level  (rx_fifo_level)
    );

endmodule
