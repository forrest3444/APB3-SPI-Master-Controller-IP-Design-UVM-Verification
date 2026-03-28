module irq_ctrl (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        soft_reset_pulse,

    input  logic        evt_done,
    input  logic        evt_tx_underflow,
    input  logic        evt_rx_overflow,

    input  logic        level_tx_empty,
    input  logic        level_rx_not_empty,

    input  logic [4:0]  irq_en,
    input  logic [4:0]  irq_clear,

    output logic [4:0]  irq_raw,
    output logic [4:0]  irq_status,
    output logic        irq
);

    import apb_spi_pkg::*;

    logic sticky_done_q;
    logic sticky_tx_underflow_q;
    logic sticky_rx_overflow_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sticky_done_q         <= 1'b0;
            sticky_tx_underflow_q <= 1'b0;
            sticky_rx_overflow_q  <= 1'b0;
        end else if (soft_reset_pulse) begin
            sticky_done_q         <= 1'b0;
            sticky_tx_underflow_q <= 1'b0;
            sticky_rx_overflow_q  <= 1'b0;
        end else begin
            sticky_done_q         <= (sticky_done_q         || evt_done)         && !irq_clear[IRQ_DONE_BIT];
            sticky_tx_underflow_q <= (sticky_tx_underflow_q || evt_tx_underflow) && !irq_clear[IRQ_TX_UNDERFLOW_BIT];
            sticky_rx_overflow_q  <= (sticky_rx_overflow_q  || evt_rx_overflow)  && !irq_clear[IRQ_RX_OVERFLOW_BIT];
        end
    end

    always_comb begin
        irq_raw = '0;
        irq_raw[IRQ_DONE_BIT]         = sticky_done_q;
        irq_raw[IRQ_TX_EMPTY_BIT]     = level_tx_empty;
        irq_raw[IRQ_RX_NOT_EMPTY_BIT] = level_rx_not_empty;
        irq_raw[IRQ_TX_UNDERFLOW_BIT] = sticky_tx_underflow_q;
        irq_raw[IRQ_RX_OVERFLOW_BIT]  = sticky_rx_overflow_q;

        irq_status = irq_raw & irq_en;
        irq        = |irq_status;
    end

endmodule
