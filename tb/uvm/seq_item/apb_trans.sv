class apb_trans extends uvm_sequence_item;
    `uvm_object_utils(apb_trans)

    rand bit        is_write;
    rand bit [11:0] addr;
    rand bit [31:0] wdata;
         bit [31:0] rdata;
         bit        ready;
         bit        slverr;

    function new(string name = "apb_trans");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        apb_trans rhs_t;

        if (!$cast(rhs_t, rhs)) begin
            `uvm_fatal(get_type_name(), "do_copy cast failed")
        end

        super.do_copy(rhs);
        is_write = rhs_t.is_write;
        addr     = rhs_t.addr;
        wdata    = rhs_t.wdata;
        rdata    = rhs_t.rdata;
        ready    = rhs_t.ready;
        slverr   = rhs_t.slverr;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        apb_trans rhs_t;

        if (!$cast(rhs_t, rhs)) begin
            return 1'b0;
        end

        return super.do_compare(rhs, comparer) &&
               (is_write == rhs_t.is_write) &&
               (addr     == rhs_t.addr) &&
               (wdata    == rhs_t.wdata) &&
               (rdata    == rhs_t.rdata) &&
               (ready    == rhs_t.ready) &&
               (slverr   == rhs_t.slverr);
    endfunction

    function string convert2string();
        return $sformatf("APB %s addr=0x%03h wdata=0x%08h rdata=0x%08h ready=%0b slverr=%0b",
                         is_write ? "WRITE" : "READ",
                         addr,
                         wdata,
                         rdata,
                         ready,
                         slverr);
    endfunction
endclass
