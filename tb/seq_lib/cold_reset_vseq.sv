class cold_reset_vseq extends apb_spi_base_vseq;
    `uvm_object_utils(cold_reset_vseq)

    function new(string name = "cold_reset_vseq");
        super.new(name);
    endfunction

    task automatic check_signal(string signal_name, logic actual, logic expected);
        if (actual !== expected) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s mismatch exp=%0b act=%0b",
                                 signal_name, expected, actual))
        end
    endtask

    task automatic check_bus_read(string reg_name, uvm_reg rg, bit [31:0] expected);
        bit [31:0] actual;

        bus_read_reg(rg, actual);
        if (actual !== expected) begin
            `uvm_error(get_type_name(),
                       $sformatf("%s mismatch exp=0x%08h act=0x%08h",
                                 reg_name, expected, actual))
        end
    endtask

    task automatic check_safe_outputs(string phase_name);
        check_signal($sformatf("%s PREADY", phase_name),
                     cfg.apb_cfg.vif.pready, 1'b1);
        check_signal($sformatf("%s PSLVERR", phase_name),
                     cfg.apb_cfg.vif.pslverr, 1'b0);
        check_signal($sformatf("%s IRQ", phase_name),
                     cfg.apb_cfg.vif.irq, 1'b0);
        check_signal($sformatf("%s SPI CS_N", phase_name),
                     cfg.spi_cfg.vif.spi_cs_n, 1'b1);
        check_signal($sformatf("%s SPI SCLK", phase_name),
                     cfg.spi_cfg.vif.spi_sclk, 1'b0);
        check_signal($sformatf("%s SPI MOSI", phase_name),
                     cfg.spi_cfg.vif.spi_mosi, 1'b0);
    endtask

    task body();
        if (cfg.apb_cfg.vif.presetn !== 1'b0) begin
            `uvm_fatal(get_type_name(), "Cold-reset sequence did not start during PRESETn assertion")
        end

        // Sample halfway through a reset clock cycle after asynchronous reset
        // assignments have settled.
        @(negedge cfg.apb_cfg.vif.pclk);
        check_safe_outputs("during cold reset");

        wait (cfg.apb_cfg.vif.presetn === 1'b1);
        @(negedge cfg.apb_cfg.vif.pclk);
        check_safe_outputs("after cold reset release");

        check_reg_value("CTRL cold reset",       ral().ctrl,       CTRL_RESET_VALUE);
        check_reg_value("STATUS cold reset",     ral().status,     32'h0000_000a);
        check_reg_value("CLKDIV cold reset",     ral().clkdiv,     32'h0000_0001);
        check_bus_read("TXDATA cold reset",      ral().txdata,     32'h0000_0000);
        check_reg_value("RXDATA cold reset",     ral().rxdata,     32'h0000_0000);
        check_reg_value("IRQ_EN cold reset",     ral().irq_en,     32'h0000_0000);
        check_reg_value("IRQ_RAW cold reset",    ral().irq_raw,    32'h0000_0002);
        check_reg_value("IRQ_STATUS cold reset", ral().irq_status, 32'h0000_0000);
        check_bus_read("IRQ_CLEAR cold reset",   ral().irq_clear,  32'h0000_0000);
        check_reg_value("TXFIFO_LVL cold reset", ral().txfifo_lvl, 32'h0000_0000);
        check_reg_value("RXFIFO_LVL cold reset", ral().rxfifo_lvl, 32'h0000_0000);
        check_reg_value("VERSION cold reset",    ral().version,    VERSION_RESET_VALUE);
    endtask
endclass
