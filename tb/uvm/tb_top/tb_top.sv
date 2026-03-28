module tb_top;

    import uvm_pkg::*;
    import apb_spi_uvm_pkg::*;

    string dump_file;

    logic pclk;
    logic presetn;
    logic irq;

    apb_if apb_vif (
        .pclk    (pclk),
        .presetn (presetn)
    );

    spi_if spi_vif();

    apb_spi_master_top dut (
        .PCLK     (pclk),
        .PRESETn  (presetn),
        .PSEL     (apb_vif.psel),
        .PENABLE  (apb_vif.penable),
        .PWRITE   (apb_vif.pwrite),
        .PADDR    (apb_vif.paddr),
        .PWDATA   (apb_vif.pwdata),
        .PRDATA   (apb_vif.prdata),
        .PREADY   (apb_vif.pready),
        .PSLVERR  (apb_vif.pslverr),
        .spi_sclk (spi_vif.spi_sclk),
        .spi_mosi (spi_vif.spi_mosi),
        .spi_miso (spi_vif.spi_miso),
        .spi_cs_n (spi_vif.spi_cs_n),
        .irq      (irq)
    );

    initial begin
        pclk = 1'b0;
        forever #5ns pclk = ~pclk;
    end

    initial begin
        presetn = 1'b0;
        apb_vif.init_master();
        spi_vif.spi_miso = 1'b0;
        repeat (5) @(posedge pclk);
        presetn = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top", "apb_vif", apb_vif);
        uvm_config_db#(virtual spi_if)::set(null, "uvm_test_top", "spi_vif", spi_vif);
        run_test();
    end

    initial begin
        if ($test$plusargs("FSDB")) begin
            if (!$value$plusargs("FSDB_FILE=%s", dump_file)) begin
                dump_file = "waves.fsdb";
            end
            $fsdbDumpfile(dump_file);
            $fsdbDumpvars(0, tb_top, "+all");
        end else begin
            if (!$value$plusargs("VPD_FILE=%s", dump_file)) begin
                dump_file = "waves.vpd";
            end
            $vcdplusfile(dump_file);
            $vcdpluson(0, tb_top);
        end
    end

endmodule
