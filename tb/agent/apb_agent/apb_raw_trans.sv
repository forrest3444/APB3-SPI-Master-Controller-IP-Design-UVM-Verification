class apb_raw_trans extends apb_trans;
    `uvm_object_utils(apb_raw_trans)

    rand bit        raw_mode;
    rand bit        raw_psel;
    rand bit        raw_penable;
    rand bit        raw_pwrite;
    rand bit [11:0] raw_paddr;
    rand bit [31:0] raw_pwdata;
    rand int unsigned raw_cycles;

    constraint c_raw_cycles {
        raw_cycles inside {[1:8]};
    }

    function new(string name = "apb_raw_trans");
        super.new(name);
        raw_mode    = 1'b0;
        raw_psel    = 1'b0;
        raw_penable = 1'b0;
        raw_pwrite  = 1'b0;
        raw_paddr   = '0;
        raw_pwdata  = '0;
        raw_cycles  = 1;
    endfunction

    function void do_copy(uvm_object rhs);
        apb_raw_trans rhs_t;

        if (!$cast(rhs_t, rhs)) begin
            `uvm_fatal(get_type_name(), "do_copy cast failed")
        end

        super.do_copy(rhs);
        raw_mode    = rhs_t.raw_mode;
        raw_psel    = rhs_t.raw_psel;
        raw_penable = rhs_t.raw_penable;
        raw_pwrite  = rhs_t.raw_pwrite;
        raw_paddr   = rhs_t.raw_paddr;
        raw_pwdata  = rhs_t.raw_pwdata;
        raw_cycles  = rhs_t.raw_cycles;
    endfunction

    function string convert2string();
        if (raw_mode) begin
            return $sformatf("RAW APB psel=%0b penable=%0b pwrite=%0b addr=0x%03h wdata=0x%08h cycles=%0d ready=%0b slverr=%0b",
                             raw_psel,
                             raw_penable,
                             raw_pwrite,
                             raw_paddr,
                             raw_pwdata,
                             raw_cycles,
                             ready,
                             slverr);
        end

        return super.convert2string();
    endfunction
endclass
