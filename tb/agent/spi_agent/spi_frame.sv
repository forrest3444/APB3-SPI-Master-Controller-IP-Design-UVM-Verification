class spi_frame extends uvm_sequence_item;
    `uvm_object_utils(spi_frame)

    rand bit           cpol;
    rand bit           cpha;
    rand bit           cont;
    rand bit           tx_en;
    rand bit           rx_en;
    rand byte unsigned tx_byte;
    rand byte unsigned rx_byte;
         int unsigned  frame_idx;
         int unsigned  cs_window_id;

    function new(string name = "spi_frame");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        spi_frame rhs_t;

        if (!$cast(rhs_t, rhs)) begin
            `uvm_fatal(get_type_name(), "do_copy cast failed")
        end

        super.do_copy(rhs);
        cpol         = rhs_t.cpol;
        cpha         = rhs_t.cpha;
        cont         = rhs_t.cont;
        tx_en        = rhs_t.tx_en;
        rx_en        = rhs_t.rx_en;
        tx_byte      = rhs_t.tx_byte;
        rx_byte      = rhs_t.rx_byte;
        frame_idx    = rhs_t.frame_idx;
        cs_window_id = rhs_t.cs_window_id;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        spi_frame rhs_t;

        if (!$cast(rhs_t, rhs)) begin
            return 1'b0;
        end

        return super.do_compare(rhs, comparer) &&
               (cpol         == rhs_t.cpol) &&
               (cpha         == rhs_t.cpha) &&
               (cont         == rhs_t.cont) &&
               (tx_en        == rhs_t.tx_en) &&
               (rx_en        == rhs_t.rx_en) &&
               (tx_byte      == rhs_t.tx_byte) &&
               (rx_byte      == rhs_t.rx_byte) &&
               (frame_idx    == rhs_t.frame_idx) &&
               (cs_window_id == rhs_t.cs_window_id);
    endfunction

    function string convert2string();
        return $sformatf("SPI frame=%0d window=%0d mode=%0d cont=%0b tx_en=%0b rx_en=%0b tx=0x%02h rx=0x%02h",
                         frame_idx,
                         cs_window_id,
                         {cpol, cpha},
                         cont,
                         tx_en,
                         rx_en,
                         tx_byte,
                         rx_byte);
    endfunction
endclass
