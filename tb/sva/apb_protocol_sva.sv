module apb_protocol_sva (
    input logic PCLK,
    input logic PRESETn,
    input logic PSEL,
    input logic PENABLE,
    input logic [11:0] PADDR,
    input logic PREADY,
    input logic PSLVERR
);

    function automatic bit is_legal_addr(logic [11:0] addr);
        unique case (addr)
            12'h000,
            12'h004,
            12'h008,
            12'h00c,
            12'h010,
            12'h014,
            12'h018,
            12'h01c,
            12'h020,
            12'h024,
            12'h028,
            12'h02c: is_legal_addr = 1'b1;
            default: is_legal_addr = 1'b0;
        endcase
    endfunction

    property p_apb_setup_to_access;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE) |=> PENABLE;
    endproperty

    property p_apb_always_ready;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> PREADY;
    endproperty

    property p_apb_legal_no_error;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && PREADY && is_legal_addr(PADDR)) |-> !PSLVERR;
    endproperty

    property p_apb_illegal_error;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && PREADY && !is_legal_addr(PADDR)) |-> PSLVERR;
    endproperty

    property p_apb_error_only_on_illegal_completion;
        @(posedge PCLK) disable iff (!PRESETn)
        PSLVERR |-> (PSEL && PENABLE && PREADY && !is_legal_addr(PADDR));
    endproperty

    apb_setup_to_access_a: assert property (p_apb_setup_to_access);
    apb_always_ready_a:      assert property (p_apb_always_ready);
    apb_legal_no_error_a:    assert property (p_apb_legal_no_error);
    apb_illegal_error_a:     assert property (p_apb_illegal_error);
    apb_error_completion_a:  assert property (p_apb_error_only_on_illegal_completion);

endmodule
