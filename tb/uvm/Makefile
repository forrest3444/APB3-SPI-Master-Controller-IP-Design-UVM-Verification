###############################################################################
# Project / Test Configuration
###############################################################################
TB_TOP    ?= tb_top
TESTNAME  ?= smoke_test
SEED      ?= 1
VERB      ?= UVM_MEDIUM
RUN_TIME  ?= 1
BUILD_NAME ?= default

SIM       ?= sim
BUILD_DIR := $(SIM)/build/$(BUILD_NAME)
RUN_DIR   := $(SIM)/$(TESTNAME)_seed_$(SEED)
BUILD_LOG_DIR := $(BUILD_DIR)/log
RUN_LOG_DIR   := $(RUN_DIR)/log
WAVE_DIR      := $(RUN_DIR)/wave
COV_DIR       := $(RUN_DIR)/cov
SIMV_DIR      := $(BUILD_DIR)/simv

FILELIST  ?= ./filelist.f
PTHREAD_FIX ?= ./debug/pthread_yield_shim.c

###############################################################################
# Tools
###############################################################################
VCS       ?= vcs
VERDI     ?= verdi
URG       ?= urg

###############################################################################
# Common Options
###############################################################################
TIMESCALE ?= 1ns/1ps

VCS_OPTS = -full64                      \
           -sverilog                    \
           -timescale=$(TIMESCALE)      \
           -ntb_opts uvm-1.2            \
           -kdb                         \
           -debug_access+all            \
           -lca                         \
           -nc                          \
           $(INC_DIR)

###############################################################################
# Optional Feature Switches
###############################################################################
ifdef ASSERT
VCS_OPTS += +define+ASSERT_ON
endif

ifdef DEBUG
VCS_OPTS += +define+DEBUG
endif

ifdef COV
VCS_OPTS += -cm line+cond+fsm+branch+tgl+assert
SIM_COV_OPTS = -cm line+cond+fsm+branch+tgl+assert -cm_dir $(COV_DIR)
endif

ifdef FSDB
SIM_WAVE_OPTS = +FSDB +FSDB_FILE=$(WAVE_DIR)/$(TESTNAME)_seed$(SEED).fsdb
endif

###############################################################################
# Runtime Options
###############################################################################
SIM_OPTS = +ntb_random_seed=$(SEED)     \
           +UVM_TESTNAME=$(TESTNAME)    \
           +UVM_VERBOSITY=$(VERB)       \
           +vcs+watchdog+time=5ms

###############################################################################
# Targets
###############################################################################
.PHONY: all prepare_build prepare_run elab build run sim verdi merge_cov clean clean_all help

all: sim

prepare_build:
	mkdir -p $(BUILD_LOG_DIR)
	mkdir -p $(SIMV_DIR)

prepare_run:
	mkdir -p $(RUN_LOG_DIR)
	mkdir -p $(WAVE_DIR)
	mkdir -p $(COV_DIR)

elab: prepare_build
	$(VCS) $(VCS_OPTS)                  \
	      $(PTHREAD_FIX)                \
	      -f $(FILELIST)                \
	      $(VFILES)                     \
	      -top $(TB_TOP)                \
	      -o $(SIMV_DIR)/$(TB_TOP).simv \
	      -l $(BUILD_LOG_DIR)/compile.log

run: prepare_run
	timeout $(RUN_TIME) $(SIMV_DIR)/$(TB_TOP).simv \
	      $(SIM_OPTS)                   \
	      $(SIM_COV_OPTS)               \
	      $(SIM_WAVE_OPTS)              \
	      -l $(RUN_LOG_DIR)/run.log

sim: elab run

verdi:
	$(VERDI) -sv                        \
	         -f $(FILELIST)             \
	         $(VFILES)                  \
	         -top $(TB_TOP)             \
	         -ssf $(WAVE_DIR)/$(TESTNAME)_seed$(SEED).fsdb &

merge_cov:
	$(URG) \
	  -dir $(SIM)/test1_seed_1/cov.vdb \
	  -dir $(SIM)/test2_seed_1/cov.vdb \
	  -dbname $(SIM)/merged_cov

clean:
	@if [ -d $(SIM) ]; then find $(SIM) -mindepth 1 ! -name AGENTS.md -exec rm -rf {} +; fi
	rm -rf csrc *.daidir vc_hdrs.h ucli.key DVEfiles verdiLog novas* inter.vpd *.vpd *.fsdb *.vdb tr_db.log

clean_all: clean

help:
	@echo "Usage examples:"
	@echo "  make sim TESTNAME=smoke_test SEED=1 VERB=UVM_MEDIUM"
	@echo "  make elab BUILD_NAME=regression FSDB=1 COV=1 ASSERT=1"
	@echo "  make run TESTNAME=smoke_test SEED=1 BUILD_NAME=regression FSDB=1 COV=1 ASSERT=1"
	@echo "  make sim TESTNAME=smoke_test SEED=1 FSDB=1"
	@echo "  make sim TESTNAME=smoke_test SEED=1 COV=1"
	@echo "  make sim TESTNAME=smoke_test SEED=1 FSDB=1 COV=1 ASSERT=1 DEBUG=1"
	@echo ""
	@echo "Targets:"
	@echo "  elab         Compile and elaborate into sim/build/<BUILD_NAME>"
	@echo "  run          Run existing simv for TESTNAME using sim/build/<BUILD_NAME>"
	@echo "  sim/all      Build and run"
	@echo "  verdi        Open waveform in Verdi"
	@echo "  merge_cov    Merge coverage databases"
	@echo "  clean        Remove current test output"
