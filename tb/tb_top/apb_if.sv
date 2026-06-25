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
    logic        irq;
    logic        irq_evt_force_valid;
    logic [2:0]  irq_evt_force_value;

    clocking drv_cb @(posedge pclk);
        default input #1step output #0;
        output psel, penable, pwrite, paddr, pwdata;
        input  prdata, pready, pslverr, irq;
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
        irq_evt_force_valid = 1'b0;
        irq_evt_force_value = '0;
    endtask

    task automatic force_irq_event(bit done, bit tx_underflow, bit rx_overflow);
        irq_evt_force_value[0] = done;
        irq_evt_force_value[1] = tx_underflow;
        irq_evt_force_value[2] = rx_overflow;
        irq_evt_force_valid    = 1'b1;
    endtask

    task automatic release_irq_event();
        irq_evt_force_valid = 1'b0;
        irq_evt_force_value = '0;
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
