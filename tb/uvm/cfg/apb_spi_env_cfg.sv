class apb_spi_env_cfg extends uvm_object;
    `uvm_object_utils(apb_spi_env_cfg)

    apb_agent_cfg apb_cfg;
    spi_agent_cfg spi_cfg;

    bit enable_scoreboard = 1'b1;
    bit enable_coverage   = 1'b1;
    bit enable_assertions = 1'b1;

    function new(string name = "apb_spi_env_cfg");
        super.new(name);
    endfunction
endclass
