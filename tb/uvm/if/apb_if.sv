interface apb_if (
    input logic pclk,
    input logic presetn
);

    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [11:0] paddr;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic        pready;
    logic        pslverr;

    clocking drv_cb @(posedge pclk);
        default input #1step output #0;
        output psel, penable, pwrite, paddr, pwdata;
        input  prdata, pready, pslverr;
    endclocking

    clocking mon_cb @(posedge pclk);
        default input #1step;
        input psel, penable, pwrite, paddr, pwdata, prdata, pready, pslverr;
    endclocking

    task automatic init_master();
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = '0;
        pwdata  = '0;
    endtask

    modport dut (
        input  psel,
        input  penable,
        input  pwrite,
        input  paddr,
        input  pwdata,
        output prdata,
        output pready,
        output pslverr
    );

endinterface
