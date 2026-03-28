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

./pkg/apb_spi_uvm_pkg.sv
./sva/apb_protocol_sva.sv
./sva/spi_protocol_sva.sv
./sva/apb_spi_bind.sv

# =========================================================
# TB Top
# =========================================================
./tb_top/tb_top.sv
