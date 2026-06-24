class apb_reg_semantics_vseq extends apb_reg_access_vseq;
    `uvm_object_utils(apb_reg_semantics_vseq)

    function new(string name = "apb_reg_semantics_vseq");
        super.new(name);
    endfunction

    task automatic raw_apb_write(bit [11:0] addr, bit [31:0] data);
        apb_trans req;

        req = apb_trans::type_id::create($sformatf("illegal_write_%03h", addr));
        `uvm_do_on_with(req, p_sequencer.apb_sqr, {
            is_write == 1'b1;
            addr     == local::addr;
            wdata    == local::data;
        })
    endtask

    task automatic raw_apb_read(bit [11:0] addr, output bit [31:0] data);
        apb_trans req;

        req = apb_trans::type_id::create($sformatf("illegal_read_%03h", addr));
        `uvm_do_on_with(req, p_sequencer.apb_sqr, {
            is_write == 1'b0;
            addr     == local::addr;
            wdata    == '0;
        })
        data = req.rdata;
    endtask

    task automatic check_illegal_address(bit [11:0] addr);
        bit [31:0] read_data;

        raw_apb_write(addr, 32'ha5a5_5a5a);
        raw_apb_read(addr, read_data);
        if (read_data !== 32'h0000_0000) begin
            `uvm_error(get_type_name(),
                       $sformatf("Illegal address 0x%03h returned 0x%08h instead of zero",
                                 addr, read_data))
        end
    endtask

    task body();
        bit [31:0] ctrl_before;
        bit [31:0] clkdiv_before;
        bit [31:0] irq_en_before;

        // TC-REG-01/04/05/07: reset defaults, WO/RO semantics and VERSION.
        super.body();

        // TC-REG-06: unmapped reads return zero and writes have no side effects.
        read_reg(ral().ctrl, ctrl_before);
        read_reg(ral().clkdiv, clkdiv_before);
        read_reg(ral().irq_en, irq_en_before);

        check_illegal_address(12'h030);
        check_illegal_address(12'h034);
        check_illegal_address(12'h0ff);

        check_read("CTRL after illegal accesses", ral().ctrl, ctrl_before);
        check_read("CLKDIV after illegal accesses", ral().clkdiv, clkdiv_before);
        check_read("IRQ_EN after illegal accesses", ral().irq_en, irq_en_before);
        check_read("VERSION after illegal accesses", ral().version, VERSION_RESET_VALUE);
    endtask
endclass
