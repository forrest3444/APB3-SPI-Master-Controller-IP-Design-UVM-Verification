module sync_fifo #(
    parameter int unsigned WIDTH = 8,
    parameter int unsigned DEPTH = 8
)(
    input  logic                         clk,
    input  logic                         rst_n,

    input  logic                         w_en,
    input  logic [WIDTH-1:0]             w_data,
    output logic                         full,

    input  logic                         r_en,
    output logic [WIDTH-1:0]             r_data,
    output logic                         empty,

    output logic [$clog2(DEPTH+1)-1:0]   level
);

    localparam int unsigned PTR_W   = (DEPTH > 1) ? $clog2(DEPTH) : 1;
    localparam int unsigned LEVEL_W = $clog2(DEPTH + 1);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_W-1:0] wr_ptr_q;
    logic [PTR_W-1:0] rd_ptr_q;
    logic [LEVEL_W-1:0] level_q;

    logic write_accept;
    logic read_accept;
    logic [PTR_W-1:0] wr_ptr_n;
    logic [PTR_W-1:0] rd_ptr_n;

    always_comb begin
        write_accept = w_en && !full;
        read_accept  = r_en && !empty;

        wr_ptr_n = wr_ptr_q;
        rd_ptr_n = rd_ptr_q;

        if (write_accept) begin
            if (wr_ptr_q == PTR_W'(DEPTH-1)) begin
                wr_ptr_n = '0;
            end else begin
                wr_ptr_n = wr_ptr_q + PTR_W'(1);
            end
        end

        if (read_accept) begin
            if (rd_ptr_q == PTR_W'(DEPTH-1)) begin
                rd_ptr_n = '0;
            end else begin
                rd_ptr_n = rd_ptr_q + PTR_W'(1);
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_q <= '0;
            rd_ptr_q <= '0;
            level_q  <= '0;
        end else begin
            if (write_accept) begin
                mem[wr_ptr_q] <= w_data;
                wr_ptr_q      <= wr_ptr_n;
            end

            if (read_accept) begin
                rd_ptr_q <= rd_ptr_n;
            end

            case ({write_accept, read_accept})
                2'b10: level_q <= level_q + LEVEL_W'(1);
                2'b01: level_q <= level_q - LEVEL_W'(1);
                default: level_q <= level_q;
            endcase
        end
    end

    always_comb begin
        empty  = (level_q == '0);
        full   = (level_q == LEVEL_W'(DEPTH));
        level  = level_q;
        r_data = empty ? '0 : mem[rd_ptr_q];
    end

endmodule
