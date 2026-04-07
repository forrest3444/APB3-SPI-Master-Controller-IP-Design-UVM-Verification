class apb_spi_ctrl_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_ctrl_reg)

    uvm_reg_field enable_f;
    uvm_reg_field start_f;
    uvm_reg_field cpha_f;
    uvm_reg_field cpol_f;
    uvm_reg_field cont_f;
    uvm_reg_field rx_en_f;
    uvm_reg_field tx_en_f;
    uvm_reg_field soft_reset_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_ctrl_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        enable_f = uvm_reg_field::type_id::create("enable");
        enable_f.configure(this, 1, CTRL_ENABLE_BIT, "RW", 0, 1'b0, 1, 0, 1);

        start_f = uvm_reg_field::type_id::create("start");
        start_f.configure(this, 1, CTRL_START_BIT, "WO", 1, 1'b0, 1, 0, 1);

        cpha_f = uvm_reg_field::type_id::create("cpha");
        cpha_f.configure(this, 1, CTRL_CPHA_BIT, "RW", 0, 1'b0, 1, 0, 1);

        cpol_f = uvm_reg_field::type_id::create("cpol");
        cpol_f.configure(this, 1, CTRL_CPOL_BIT, "RW", 0, 1'b0, 1, 0, 1);

        cont_f = uvm_reg_field::type_id::create("cont");
        cont_f.configure(this, 1, CTRL_CONT_BIT, "RW", 0, 1'b0, 1, 0, 1);

        rx_en_f = uvm_reg_field::type_id::create("rx_en");
        rx_en_f.configure(this, 1, CTRL_RX_EN_BIT, "RW", 0, 1'b1, 1, 0, 1);

        tx_en_f = uvm_reg_field::type_id::create("tx_en");
        tx_en_f.configure(this, 1, CTRL_TX_EN_BIT, "RW", 0, 1'b1, 1, 0, 1);

        soft_reset_f = uvm_reg_field::type_id::create("soft_reset");
        soft_reset_f.configure(this, 1, CTRL_SOFT_RESET_BIT, "WO", 1, 1'b0, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 24, 8, "RO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_status_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_status_reg)

    uvm_reg_field busy_f;
    uvm_reg_field tx_empty_f;
    uvm_reg_field tx_full_f;
    uvm_reg_field rx_empty_f;
    uvm_reg_field rx_full_f;
    uvm_reg_field cs_active_f;
    uvm_reg_field done_pending_f;
    uvm_reg_field tx_underflow_pending_f;
    uvm_reg_field rx_overflow_pending_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_status_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        busy_f = uvm_reg_field::type_id::create("busy");
        busy_f.configure(this, 1, STATUS_BUSY_BIT, "RO", 1, 1'b0, 1, 0, 1);

        tx_empty_f = uvm_reg_field::type_id::create("tx_empty");
        tx_empty_f.configure(this, 1, STATUS_TX_EMPTY_BIT, "RO", 1, 1'b1, 1, 0, 1);

        tx_full_f = uvm_reg_field::type_id::create("tx_full");
        tx_full_f.configure(this, 1, STATUS_TX_FULL_BIT, "RO", 1, 1'b0, 1, 0, 1);

        rx_empty_f = uvm_reg_field::type_id::create("rx_empty");
        rx_empty_f.configure(this, 1, STATUS_RX_EMPTY_BIT, "RO", 1, 1'b1, 1, 0, 1);

        rx_full_f = uvm_reg_field::type_id::create("rx_full");
        rx_full_f.configure(this, 1, STATUS_RX_FULL_BIT, "RO", 1, 1'b0, 1, 0, 1);

        cs_active_f = uvm_reg_field::type_id::create("cs_active");
        cs_active_f.configure(this, 1, STATUS_CS_ACTIVE_BIT, "RO", 1, 1'b0, 1, 0, 1);

        done_pending_f = uvm_reg_field::type_id::create("done_pending");
        done_pending_f.configure(this, 1, STATUS_DONE_PENDING_BIT, "RO", 1, 1'b0, 1, 0, 1);

        tx_underflow_pending_f = uvm_reg_field::type_id::create("tx_underflow_pending");
        tx_underflow_pending_f.configure(this, 1, STATUS_TX_UNDERFLOW_PENDING_BIT, "RO", 1, 1'b0, 1, 0, 1);

        rx_overflow_pending_f = uvm_reg_field::type_id::create("rx_overflow_pending");
        rx_overflow_pending_f.configure(this, 1, STATUS_RX_OVERFLOW_PENDING_BIT, "RO", 1, 1'b0, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 23, 9, "RO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_clkdiv_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_clkdiv_reg)

    uvm_reg_field div_value_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_clkdiv_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        div_value_f = uvm_reg_field::type_id::create("div_value");
        div_value_f.configure(this, 8, 0, "RW", 0, CLKDIV_RESET_VALUE, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 24, 8, "RO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_txdata_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_txdata_reg)

    uvm_reg_field tx_byte_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_txdata_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        tx_byte_f = uvm_reg_field::type_id::create("tx_byte");
        tx_byte_f.configure(this, 8, 0, "WO", 0, 8'h00, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 24, 8, "WO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_rxdata_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_rxdata_reg)

    uvm_reg_field rx_byte_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_rxdata_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        rx_byte_f = uvm_reg_field::type_id::create("rx_byte");
        rx_byte_f.configure(this, 8, 0, "RO", 1, 8'h00, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 24, 8, "RO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_irq_en_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_irq_en_reg)

    uvm_reg_field done_en_f;
    uvm_reg_field tx_empty_en_f;
    uvm_reg_field rx_not_empty_en_f;
    uvm_reg_field tx_underflow_en_f;
    uvm_reg_field rx_overflow_en_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_irq_en_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        done_en_f = uvm_reg_field::type_id::create("done_en");
        done_en_f.configure(this, 1, IRQ_DONE_BIT, "RW", 0, 1'b0, 1, 0, 1);

        tx_empty_en_f = uvm_reg_field::type_id::create("tx_empty_en");
        tx_empty_en_f.configure(this, 1, IRQ_TX_EMPTY_BIT, "RW", 0, 1'b0, 1, 0, 1);

        rx_not_empty_en_f = uvm_reg_field::type_id::create("rx_not_empty_en");
        rx_not_empty_en_f.configure(this, 1, IRQ_RX_NOT_EMPTY_BIT, "RW", 0, 1'b0, 1, 0, 1);

        tx_underflow_en_f = uvm_reg_field::type_id::create("tx_underflow_en");
        tx_underflow_en_f.configure(this, 1, IRQ_TX_UNDERFLOW_BIT, "RW", 0, 1'b0, 1, 0, 1);

        rx_overflow_en_f = uvm_reg_field::type_id::create("rx_overflow_en");
        rx_overflow_en_f.configure(this, 1, IRQ_RX_OVERFLOW_BIT, "RW", 0, 1'b0, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 27, 5, "RO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_irq_raw_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_irq_raw_reg)

    uvm_reg_field done_raw_f;
    uvm_reg_field tx_empty_raw_f;
    uvm_reg_field rx_not_empty_raw_f;
    uvm_reg_field tx_underflow_raw_f;
    uvm_reg_field rx_overflow_raw_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_irq_raw_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        done_raw_f = uvm_reg_field::type_id::create("done_raw");
        done_raw_f.configure(this, 1, IRQ_DONE_BIT, "RO", 1, 1'b0, 1, 0, 1);

        tx_empty_raw_f = uvm_reg_field::type_id::create("tx_empty_raw");
        tx_empty_raw_f.configure(this, 1, IRQ_TX_EMPTY_BIT, "RO", 1, 1'b1, 1, 0, 1);

        rx_not_empty_raw_f = uvm_reg_field::type_id::create("rx_not_empty_raw");
        rx_not_empty_raw_f.configure(this, 1, IRQ_RX_NOT_EMPTY_BIT, "RO", 1, 1'b0, 1, 0, 1);

        tx_underflow_raw_f = uvm_reg_field::type_id::create("tx_underflow_raw");
        tx_underflow_raw_f.configure(this, 1, IRQ_TX_UNDERFLOW_BIT, "RO", 1, 1'b0, 1, 0, 1);

        rx_overflow_raw_f = uvm_reg_field::type_id::create("rx_overflow_raw");
        rx_overflow_raw_f.configure(this, 1, IRQ_RX_OVERFLOW_BIT, "RO", 1, 1'b0, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 27, 5, "RO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_irq_status_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_irq_status_reg)

    uvm_reg_field irq_masked_status_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_irq_status_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        irq_masked_status_f = uvm_reg_field::type_id::create("irq_masked_status");
        irq_masked_status_f.configure(this, 5, 0, "RO", 1, '0, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 27, 5, "RO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_irq_clear_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_irq_clear_reg)

    uvm_reg_field clr_done_f;
    uvm_reg_field clr_tx_empty_f;
    uvm_reg_field clr_rx_not_empty_f;
    uvm_reg_field clr_tx_underflow_f;
    uvm_reg_field clr_rx_overflow_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_irq_clear_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        clr_done_f = uvm_reg_field::type_id::create("clr_done");
        clr_done_f.configure(this, 1, IRQ_DONE_BIT, "WO", 0, 1'b0, 1, 0, 1);

        clr_tx_empty_f = uvm_reg_field::type_id::create("clr_tx_empty");
        clr_tx_empty_f.configure(this, 1, IRQ_TX_EMPTY_BIT, "WO", 0, 1'b0, 1, 0, 1);

        clr_rx_not_empty_f = uvm_reg_field::type_id::create("clr_rx_not_empty");
        clr_rx_not_empty_f.configure(this, 1, IRQ_RX_NOT_EMPTY_BIT, "WO", 0, 1'b0, 1, 0, 1);

        clr_tx_underflow_f = uvm_reg_field::type_id::create("clr_tx_underflow");
        clr_tx_underflow_f.configure(this, 1, IRQ_TX_UNDERFLOW_BIT, "WO", 0, 1'b0, 1, 0, 1);

        clr_rx_overflow_f = uvm_reg_field::type_id::create("clr_rx_overflow");
        clr_rx_overflow_f.configure(this, 1, IRQ_RX_OVERFLOW_BIT, "WO", 0, 1'b0, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 27, 5, "WO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_fifo_lvl_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_fifo_lvl_reg)

    uvm_reg_field level_f;
    uvm_reg_field reserved_f;

    function new(string name = "apb_spi_fifo_lvl_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        level_f = uvm_reg_field::type_id::create("level");
        level_f.configure(this, 4, 0, "RO", 1, 4'h0, 1, 0, 1);

        reserved_f = uvm_reg_field::type_id::create("reserved");
        reserved_f.configure(this, 28, 4, "RO", 0, '0, 1, 0, 0);
    endfunction
endclass

class apb_spi_version_reg extends uvm_reg;
    `uvm_object_utils(apb_spi_version_reg)

    uvm_reg_field minor_f;
    uvm_reg_field major_f;

    function new(string name = "apb_spi_version_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        minor_f = uvm_reg_field::type_id::create("minor");
        minor_f.configure(this, 16, 0, "RO", 0, VERSION_MINOR, 1, 0, 1);

        major_f = uvm_reg_field::type_id::create("major");
        major_f.configure(this, 16, 16, "RO", 0, VERSION_MAJOR, 1, 0, 1);
    endfunction
endclass

class apb_spi_reg_block extends uvm_reg_block;
    `uvm_object_utils(apb_spi_reg_block)

    apb_spi_ctrl_reg       ctrl;
    apb_spi_status_reg     status;
    apb_spi_clkdiv_reg     clkdiv;
    apb_spi_txdata_reg     txdata;
    apb_spi_rxdata_reg     rxdata;
    apb_spi_irq_en_reg     irq_en;
    apb_spi_irq_raw_reg    irq_raw;
    apb_spi_irq_status_reg irq_status;
    apb_spi_irq_clear_reg  irq_clear;
    apb_spi_fifo_lvl_reg   txfifo_lvl;
    apb_spi_fifo_lvl_reg   rxfifo_lvl;
    apb_spi_version_reg    version;

    function new(string name = "apb_spi_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN, 0);

        ctrl = apb_spi_ctrl_reg::type_id::create("ctrl");
        ctrl.configure(this, null, "");
        ctrl.build();
        ctrl.set_reset(CTRL_RESET_VALUE);
        default_map.add_reg(ctrl, REG_CTRL_ADDR, "RW");

        status = apb_spi_status_reg::type_id::create("status");
        status.configure(this, null, "");
        status.build();
        status.set_reset(32'h0000_000a);
        default_map.add_reg(status, REG_STATUS_ADDR, "RO");

        clkdiv = apb_spi_clkdiv_reg::type_id::create("clkdiv");
        clkdiv.configure(this, null, "");
        clkdiv.build();
        clkdiv.set_reset({24'h0, CLKDIV_RESET_VALUE});
        default_map.add_reg(clkdiv, REG_CLKDIV_ADDR, "RW");

        txdata = apb_spi_txdata_reg::type_id::create("txdata");
        txdata.configure(this, null, "");
        txdata.build();
        txdata.set_reset('0);
        default_map.add_reg(txdata, REG_TXDATA_ADDR, "WO");

        rxdata = apb_spi_rxdata_reg::type_id::create("rxdata");
        rxdata.configure(this, null, "");
        rxdata.build();
        rxdata.set_reset('0);
        default_map.add_reg(rxdata, REG_RXDATA_ADDR, "RO");

        irq_en = apb_spi_irq_en_reg::type_id::create("irq_en");
        irq_en.configure(this, null, "");
        irq_en.build();
        irq_en.set_reset('0);
        default_map.add_reg(irq_en, REG_IRQ_EN_ADDR, "RW");

        irq_raw = apb_spi_irq_raw_reg::type_id::create("irq_raw");
        irq_raw.configure(this, null, "");
        irq_raw.build();
        irq_raw.set_reset(32'h0000_0002);
        default_map.add_reg(irq_raw, REG_IRQ_RAW_ADDR, "RO");

        irq_status = apb_spi_irq_status_reg::type_id::create("irq_status");
        irq_status.configure(this, null, "");
        irq_status.build();
        irq_status.set_reset('0);
        default_map.add_reg(irq_status, REG_IRQ_STATUS_ADDR, "RO");

        irq_clear = apb_spi_irq_clear_reg::type_id::create("irq_clear");
        irq_clear.configure(this, null, "");
        irq_clear.build();
        irq_clear.set_reset('0);
        default_map.add_reg(irq_clear, REG_IRQ_CLEAR_ADDR, "WO");

        txfifo_lvl = apb_spi_fifo_lvl_reg::type_id::create("txfifo_lvl");
        txfifo_lvl.configure(this, null, "");
        txfifo_lvl.build();
        txfifo_lvl.set_reset('0);
        default_map.add_reg(txfifo_lvl, REG_TXFIFO_LVL_ADDR, "RO");

        rxfifo_lvl = apb_spi_fifo_lvl_reg::type_id::create("rxfifo_lvl");
        rxfifo_lvl.configure(this, null, "");
        rxfifo_lvl.build();
        rxfifo_lvl.set_reset('0);
        default_map.add_reg(rxfifo_lvl, REG_RXFIFO_LVL_ADDR, "RO");

        version = apb_spi_version_reg::type_id::create("version");
        version.configure(this, null, "");
        version.build();
        version.set_reset(VERSION_RESET_VALUE);
        default_map.add_reg(version, REG_VERSION_ADDR, "RO");
    endfunction
endclass
