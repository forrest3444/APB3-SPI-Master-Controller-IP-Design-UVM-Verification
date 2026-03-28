class spi_agent_cfg extends uvm_object;
    `uvm_object_utils(spi_agent_cfg)

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    virtual spi_if          vif;
    bit                     default_cpol;
    bit                     default_cpha;

    function new(string name = "spi_agent_cfg");
        super.new(name);
    endfunction
endclass
