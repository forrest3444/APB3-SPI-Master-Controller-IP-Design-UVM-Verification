package apb_spi_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import apb_spi_pkg::*;

    `uvm_analysis_imp_decl(_apb)
    `uvm_analysis_imp_decl(_spi)

    `include "../cfg/apb_agent_cfg.sv"
    `include "../cfg/spi_agent_cfg.sv"
    `include "../cfg/apb_spi_env_cfg.sv"

    `include "../seq_item/apb_trans.sv"
    `include "../seq_item/spi_frame.sv"
    `include "../seq_item/apb_spi_vseq_item.sv"

    `include "../ral/apb_reg_adapter.sv"
    `include "../ral/apb_spi_reg_block.sv"

    `include "../agent/apb/apb_sequencer.sv"
    `include "../agent/apb/apb_driver.sv"
    `include "../agent/apb/apb_monitor.sv"
    `include "../agent/apb/apb_agent.sv"

    `include "../agent/spi/spi_sequencer.sv"
    `include "../agent/spi/spi_driver.sv"
    `include "../agent/spi/spi_monitor.sv"
    `include "../agent/spi/spi_agent.sv"

    `include "../env/apb_spi_virtual_sequencer.sv"
    `include "../scb/apb_spi_scoreboard.sv"
    `include "../cov/apb_spi_coverage.sv"
    `include "../env/apb_spi_env.sv"

    `include "../seq_lib/vseqs.svh"
    `include "../tests/tests.svh"


endpackage
