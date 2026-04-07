simSetSimulator "-vcssv" -exec \
           "/home/wwh/github/apb_spi_master_controller/tb/uvm/sim/build/regression/simv/tb_top.simv" \
           -args \
           "+ntb_random_seed=1 +UVM_TESTNAME=apb_reg_access_test +UVM_VERBOSITY=UVM_MEDIUM +vcs+watchdog+time=5ms -cm line+cond+fsm+branch+tgl+assert -cm_dir sim/apb_reg_access_test_seed_1/cov +FSDB +FSDB_FILE=sim/apb_reg_access_test_seed_1/wave/apb_reg_access_test_seed1.fsdb"
debImport "-dbdir" \
          "/home/wwh/github/apb_spi_master_controller/tb/uvm/sim/build/regression/simv/tb_top.simv.daidir"
debLoadSimResult \
           /home/wwh/github/apb_spi_master_controller/tb/uvm/sim/apb_reg_access_test_seed_1/wave/apb_reg_access_test_seed1.fsdb
wvCreateWindow
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
srcSetScope -win $_nTrace1 "apb_spi_uvm_pkg" -delim "." -lib "work"
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
srcDeselectAll -win $_nTrace1
srcTBInvokeSim
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
srcSetScope -win $_nTrace1 "apb_spi_uvm_pkg" -delim "." -lib "work"
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
verdiDockWidgetSetCurTab -dock windowDock_nWave_2
verdiDockWidgetSetCurTab -dock windowDock_InteractiveConsole_3
verdiDockWidgetSetCurTab -dock windowDock_nWave_2
verdiDockWidgetSetCurTab -dock windowDock_OneSearch
verdiDockWidgetSetCurTab -dock widgetDock_<Message>
srcDeselectAll -win $_nTrace1
srcSelect -word -line 18 -pos 4 -win $_nTrace1
srcAction -pos 18 4 17 -win $_nTrace1 -name "\"../ral/apb_reg_adapter.sv\"" \
          -ctrlKey off
srcBackwardHistory -win $_nTrace1
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -word -line 19 -pos 4 -win $_nTrace1
srcAction -pos 19 4 18 -win $_nTrace1 -name "\"../ral/apb_spi_reg_block.sv\"" \
          -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -word -line 18 -pos 7 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -word -line 52 -pos 9 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
verdiDockWidgetSetCurTab -dock windowDock_InteractiveConsole_3
restart
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
srcSetScope -win $_nTrace1 "apb_spi_uvm_pkg" -delim "." -lib "work"
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
srcDeselectAll -win $_nTrace1
srcSelect -word -line 19 -pos 4 -win $_nTrace1
srcAction -pos 19 4 16 -win $_nTrace1 -name "\"../ral/apb_spi_reg_block.sv\"" \
          -ctrlKey off
debReload
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -signal "CTRL_RESET_VALUE" -line 48 -pos 1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -word -line 9 -pos 1 -win $_nTrace1
srcAction -pos 9 1 5 -win $_nTrace1 -name "set_reset" -ctrlKey off
srcBackwardHistory -win $_nTrace1
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -word -line 56 -pos 1 -win $_nTrace1
srcAction -pos 56 1 16 -win $_nTrace1 -name "default_map.add_reg" -ctrlKey off
srcBackwardHistory -win $_nTrace1
srcHBSelect "apb_spi_uvm_pkg" -win $_nTrace1 -lib "work"
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
debExit
