class apb_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(apb_reg_adapter)

    function new(string name = "apb_reg_adapter");
        super.new(name);
        supports_byte_enable = 1'b0;
        provides_responses   = 1'b0;
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        apb_trans tr;

        tr = apb_trans::type_id::create("tr");
        tr.is_write = (rw.kind == UVM_WRITE);
        tr.addr     = rw.addr[11:0];
        tr.wdata    = rw.data;
        tr.rdata    = '0;
        tr.ready    = 1'b0;
        tr.slverr   = 1'b0;
        return tr;
    endfunction

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        apb_trans tr;

        if (!$cast(tr, bus_item)) begin
            `uvm_fatal(get_type_name(), "bus_item is not an apb_trans")
        end

        rw.kind   = tr.is_write ? UVM_WRITE : UVM_READ;
        rw.addr   = tr.addr;
        rw.data   = tr.is_write ? tr.wdata : tr.rdata;
        rw.status = tr.slverr ? UVM_NOT_OK : UVM_IS_OK;
    endfunction
endclass
