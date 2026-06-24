module spi_protocol_sva (
    input logic PCLK,
    input logic PRESETn,
    input logic spi_sclk,
    input logic spi_cs_n,
    input logic cfg_cpol,
    input logic status_busy,
    input logic status_cs_active
);

    property p_cs_active_matches_status;
        @(posedge PCLK) disable iff (!PRESETn)
        status_cs_active == !spi_cs_n;
    endproperty

    property p_busy_implies_cs_active;
        @(posedge PCLK) disable iff (!PRESETn)
        status_busy |-> status_cs_active;
    endproperty

    property p_idle_sclk_matches_cpol;
        @(posedge PCLK) disable iff (!PRESETn)
        spi_cs_n |-> (spi_sclk == cfg_cpol);
    endproperty

    cs_active_matches_status_a: assert property (p_cs_active_matches_status);
    busy_implies_cs_active_a:    assert property (p_busy_implies_cs_active);
    idle_sclk_matches_cpol_a:    assert property (p_idle_sclk_matches_cpol);

endmodule
