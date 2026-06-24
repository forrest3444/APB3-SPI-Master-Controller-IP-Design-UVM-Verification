# =========================================================
# Design RTL
# =========================================================
+incdir+../rtl

../rtl/apb_spi_pkg.sv
../rtl/sync_fifo.sv
../rtl/irq_ctrl.sv
../rtl/apb_reg_block.sv
../rtl/spi_ctrl.sv
../rtl/apb_spi_master_top.sv

# =========================================================
# Verification Interfaces
# =========================================================
+incdir+./tb_top
./tb_top/apb_if.sv
./tb_top/spi_if.sv


# =========================================================
# Verification Package Dependencies
# =========================================================
+incdir+./agent/apb_agent
+incdir+./agent/spi_agent
+incdir+./env
+incdir+./seq_lib
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
