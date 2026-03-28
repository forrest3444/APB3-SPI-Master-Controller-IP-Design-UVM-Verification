# =========================================================
# Design RTL
# =========================================================
+incdir+../../rtl/include
+incdir+../../rtl/pkg

../../rtl/pkg/apb_spi_pkg.sv
../../rtl/fifo/sync_fifo.sv
../../rtl/irq/irq_ctrl.sv
../../rtl/reg_if/apb_reg_block.sv
../../rtl/ctrl/spi_ctrl.sv
../../rtl/top/apb_spi_master_top.sv

# =========================================================
# Verification Interfaces
# =========================================================
+incdir+./if
./if/apb_if.sv
./if/spi_if.sv
      

# =========================================================
# Verification Package Dependencies
# =========================================================
+incdir+./cfg
+incdir+./seq_item
+incdir+./agent/apb
+incdir+./agent/spi
+incdir+./seq_lib
+incdir+./env
+incdir+./scb
+incdir+./cov
+incdir+./sva
+incdir+./tests
+incdir+./pkg

./cfg/apb_agent_cfg.sv
./cfg/spi_agent_cfg.sv
./cfg/apb_spi_env_cfg.sv

./seq_item/apb_trans.sv
./seq_item/spi_frame.sv
./seq_item/apb_spi_vseq_item.sv

./agent/apb/apb_sequencer.sv
./agent/apb/apb_driver.sv
./agent/apb/apb_monitor.sv
./agent/apb/apb_agent.sv
./agent/apb/apb_agent_pkg.sv

./agent/spi/spi_sequencer.sv
./agent/spi/spi_driver.sv
./agent/spi/spi_monitor.sv
./agent/spi/spi_agent.sv
./agent/spi/spi_agent_pkg.sv

./seq_lib/apb_base_seq.sv
./seq_lib/spi_base_seq.sv
./env/apb_spi_virtual_sequencer.sv
./seq_lib/apb_spi_base_vseq.sv
./seq_lib/smoke_vseq.sv
./seq_lib/mode_sweep_vseq.sv
./seq_lib/fifo_basic_vseq.sv
./seq_lib/irq_basic_vseq.sv

./scb/apb_spi_scoreboard.sv
./cov/apb_spi_coverage.sv

./env/apb_spi_env.sv

./sva/apb_protocol_sva.sv
./sva/spi_protocol_sva.sv
./sva/apb_spi_bind.sv

./tests/apb_spi_base_test.sv
./tests/smoke_test.sv
./tests/mode_sweep_test.sv
./tests/fifo_basic_test.sv
./tests/irq_basic_test.sv

./pkg/apb_spi_uvm_pkg.sv

# =========================================================
# TB Top
# =========================================================
./tb_top/tb_top.sv
