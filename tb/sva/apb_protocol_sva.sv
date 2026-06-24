module apb_protocol_sva (
    input logic PCLK,
    input logic PRESETn,
    input logic PSEL,
    input logic PENABLE,
    input logic PREADY,
    input logic PSLVERR
);

    property p_apb_setup_to_access;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE) |=> PENABLE;
    endproperty

    property p_apb_always_ready;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> PREADY;
    endproperty

    property p_apb_no_error;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> !PSLVERR;
    endproperty

    apb_setup_to_access_a: assert property (p_apb_setup_to_access);
    apb_always_ready_a:     assert property (p_apb_always_ready);
    apb_no_error_a:         assert property (p_apb_no_error);

endmodule
