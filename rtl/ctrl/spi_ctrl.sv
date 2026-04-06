module spi_ctrl #(
    parameter int unsigned CLKDIV_W = 8
)(
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 cfg_enable,
    input  logic                 cfg_cpha,
    input  logic                 cfg_cpol,
    input  logic                 cfg_cont,
    input  logic                 cfg_rx_en,
    input  logic                 cfg_tx_en,
    input  logic [CLKDIV_W-1:0]  cfg_clkdiv,

    input  logic                 start_pulse,
    input  logic                 soft_reset_pulse,

    output logic                 tx_fifo_ren,
    input  logic [7:0]           tx_fifo_rdata,
    input  logic                 tx_fifo_empty,

    output logic                 rx_fifo_wen,
    output logic [7:0]           rx_fifo_wdata,
    input  logic                 rx_fifo_full,

    output logic                 spi_sclk,
    output logic                 spi_mosi,
    input  logic                 spi_miso,
    output logic                 spi_cs_n,

    output logic                 status_busy,
    output logic                 status_cs_active,

    output logic                 evt_done,
    output logic                 evt_tx_underflow,
    output logic                 evt_rx_overflow
);

    import apb_spi_pkg::*;

    spi_state_e          state_q;
    logic [CLKDIV_W-1:0] clkdiv_cnt_q;
    logic [2:0]          bit_cnt_q;
    logic [7:0]          tx_shift_reg_q;
    logic [6:0]          rx_shift_reg_q;
    logic                sclk_q;
    logic                mosi_q;
    logic                cs_active_q;
    logic [CLKDIV_W-1:0] clkdiv_value;
    logic [7:0]          frame_data;
    logic                can_start;
    logic                divider_hit;
    logic                leading_edge_pulse;
    logic                trailing_edge_pulse;
    logic                sample_edge_pulse;
    logic                shift_edge_pulse;

    assign clkdiv_value        = (cfg_clkdiv == '0) ? CLKDIV_W'(1) : cfg_clkdiv;
    assign frame_data          = cfg_tx_en ? tx_fifo_rdata : 8'h00;
    assign can_start           = cfg_enable && ((cfg_tx_en && !tx_fifo_empty) || (!cfg_tx_en && cfg_rx_en));
    assign divider_hit         = (clkdiv_cnt_q >= (clkdiv_value - CLKDIV_W'(1)));
    assign leading_edge_pulse  = (state_q == SPI_ST_SHIFT) && divider_hit && (sclk_q == cfg_cpol);
    assign trailing_edge_pulse = (state_q == SPI_ST_SHIFT) && divider_hit && (sclk_q != cfg_cpol);
    assign sample_edge_pulse   = cfg_cpha ? trailing_edge_pulse : leading_edge_pulse;
    assign shift_edge_pulse    = cfg_cpha ? leading_edge_pulse : trailing_edge_pulse;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q        <= SPI_ST_IDLE;
            clkdiv_cnt_q   <= '0;
            bit_cnt_q      <= '0;
            tx_shift_reg_q <= '0;
            rx_shift_reg_q <= '0;
            sclk_q         <= 1'b0;
            mosi_q         <= 1'b0;
            cs_active_q    <= 1'b0;
            tx_fifo_ren    <= 1'b0;
            rx_fifo_wen    <= 1'b0;
            rx_fifo_wdata  <= '0;
            evt_done       <= 1'b0;
            evt_tx_underflow <= 1'b0;
            evt_rx_overflow  <= 1'b0;
        end else begin
            tx_fifo_ren      <= 1'b0;
            rx_fifo_wen      <= 1'b0;
            evt_done         <= 1'b0;
            evt_tx_underflow <= 1'b0;
            evt_rx_overflow  <= 1'b0;

            if (soft_reset_pulse) begin
                state_q        <= SPI_ST_IDLE;
                clkdiv_cnt_q   <= '0;
                bit_cnt_q      <= '0;
                tx_shift_reg_q <= '0;
                rx_shift_reg_q <= '0;
                sclk_q         <= cfg_cpol;
                mosi_q         <= 1'b0;
                cs_active_q    <= 1'b0;
                rx_fifo_wdata  <= '0;
            end else begin
                case (state_q)
                    SPI_ST_IDLE: begin
                        sclk_q       <= cfg_cpol;
                        clkdiv_cnt_q <= '0;
                        bit_cnt_q    <= '0;

                        if (start_pulse) begin
                            if (can_start) begin
                                state_q <= SPI_ST_LOAD;
                            end else if (cfg_enable && cfg_tx_en && tx_fifo_empty) begin
                                evt_tx_underflow <= 1'b1;
                            end
                        end
                    end

                    SPI_ST_LOAD: begin
                        cs_active_q    <= 1'b1;
                        sclk_q         <= cfg_cpol;
                        clkdiv_cnt_q   <= '0;
                        bit_cnt_q      <= '0;
                        rx_shift_reg_q <= '0;

                        if (cfg_tx_en) begin
                            tx_fifo_ren <= 1'b1;
                        end

                        if (cfg_cpha) begin
                            tx_shift_reg_q <= frame_data;
                        end else begin
                            tx_shift_reg_q <= {frame_data[6:0], 1'b0};
                        end

                        mosi_q  <= frame_data[7];
                        state_q <= SPI_ST_SHIFT;
                    end

                    SPI_ST_SHIFT: begin
                        if (divider_hit) begin
                            clkdiv_cnt_q <= '0;
                            sclk_q       <= ~sclk_q;

                            if (shift_edge_pulse) begin
                                mosi_q         <= tx_shift_reg_q[7];
                                tx_shift_reg_q <= {tx_shift_reg_q[6:0], 1'b0};
                            end

                            if (sample_edge_pulse) begin
                                if (bit_cnt_q == 3'd7) begin
                                    rx_fifo_wdata <= {rx_shift_reg_q, spi_miso};
                                    state_q       <= SPI_ST_FRAME_DONE;
                                end else begin
                                    rx_shift_reg_q <= {rx_shift_reg_q[5:0], spi_miso};
                                end

                                bit_cnt_q <= bit_cnt_q + 3'd1;
                            end
                        end else begin
                            clkdiv_cnt_q <= clkdiv_cnt_q + CLKDIV_W'(1);
                        end
                    end

                    SPI_ST_FRAME_DONE: begin
                        evt_done <= 1'b1;

                        if (cfg_rx_en) begin
                            if (rx_fifo_full) begin
                                evt_rx_overflow <= 1'b1;
                            end else begin
                                rx_fifo_wen <= 1'b1;
                            end
                        end

                        if (cfg_cont && cfg_enable && cfg_tx_en && !tx_fifo_empty) begin
                            state_q <= SPI_ST_LOAD;
                        end else begin
                            cs_active_q <= 1'b0;
                            sclk_q      <= cfg_cpol;
                            state_q     <= SPI_ST_IDLE;
                        end
                    end

                    default: begin
                        state_q <= SPI_ST_IDLE;
                    end
                endcase
            end
        end
    end

    assign spi_sclk         = sclk_q;
    assign spi_mosi         = mosi_q;
    assign spi_cs_n         = ~cs_active_q;
    assign status_busy      = (state_q != SPI_ST_IDLE);
    assign status_cs_active = cs_active_q;

endmodule
