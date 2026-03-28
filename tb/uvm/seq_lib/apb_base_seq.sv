class apb_base_seq extends uvm_sequence #(apb_trans);
    `uvm_object_utils(apb_base_seq)
    `uvm_declare_p_sequencer(apb_sequencer)

    function new(string name = "apb_base_seq");
        super.new(name);
    endfunction

    task apb_write_reg(bit [11:0] addr, bit [31:0] data);
        apb_trans req;

        req = apb_trans::type_id::create("req");
        start_item(req);
        req.is_write = 1'b1;
        req.addr     = addr;
        req.wdata    = data;
        finish_item(req);
    endtask

    task apb_read_reg(bit [11:0] addr, output bit [31:0] data);
        apb_trans req;

        req = apb_trans::type_id::create("req");
        start_item(req);
        req.is_write = 1'b0;
        req.addr     = addr;
        req.wdata    = '0;
        finish_item(req);
        data = req.rdata;
    endtask
endclass
