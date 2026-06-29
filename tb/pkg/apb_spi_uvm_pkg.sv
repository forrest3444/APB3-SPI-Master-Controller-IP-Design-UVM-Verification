package apb_spi_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import apb_spi_pkg::*;

    `uvm_analysis_imp_decl(_apb)
    `uvm_analysis_imp_decl(_spi)

    `include "../agent/apb_agent/apb_agent_cfg.sv"
    `include "../agent/spi_agent/spi_agent_cfg.sv"
    `include "../env/apb_spi_env_cfg.sv"

    `include "../agent/apb_agent/apb_trans.sv"
    `include "../agent/apb_agent/apb_raw_trans.sv"
    `include "../agent/spi_agent/spi_frame.sv"
    `include "../env/apb_spi_vseq_item.sv"

    `include "../ral/apb_reg_adapter.sv"
    `include "../ral/apb_spi_reg_block.sv"

    `include "../agent/apb_agent/apb_sequencer.sv"
    `include "../agent/apb_agent/apb_driver.sv"
    `include "../agent/apb_agent/apb_raw_driver.sv"
    `include "../agent/apb_agent/apb_monitor.sv"
    `include "../agent/apb_agent/apb_agent.sv"

    `include "../agent/spi_agent/spi_sequencer.sv"
    `include "../agent/spi_agent/spi_driver.sv"
    `include "../agent/spi_agent/spi_monitor.sv"
    `include "../agent/spi_agent/spi_agent.sv"

    `include "../env/apb_spi_virtual_sequencer.sv"
    `include "../env/apb_spi_scoreboard.sv"
    `include "../env/apb_spi_coverage.sv"
    `include "../env/apb_spi_env.sv"

    `include "../seq_lib/vseqs.svh"
    `include "../tests/tests.svh"


endpackage
