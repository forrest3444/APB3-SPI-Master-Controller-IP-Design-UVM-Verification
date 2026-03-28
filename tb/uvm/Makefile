TB_TOP    := tb_top
TESTNAME ?= smoke_test
SEED     ?= 1
VERB     ?= UVM_MEDIUM
RUN_TIME ?= 0

OUT_DIR   := sim/out/$(TESTNAME)_seed_$(SEED)
LOG_DIR   := $(OUT_DIR)/log
WAVE_DIR  := $(OUT_DIR)/wave
COV_DIR   := $(OUT_DIR)/cov
SIMV_DIR  := $(OUT_DIR)/simv

FILELIST  := filelist.f

VCS       := vcs
VLOGAN    := vlogan

UVM_HOME ?=
TIMESCALE := 1ns/1ps

VLOGAN_OPTS := -full64 -sverilog -ntb_opts uvm-1.2 -timescale=$(TIMESCALE) -kdb
VCS_OPTS    := -full64 -ntb_opts uvm-1.2 -kdb -lca -debug_access+all
SIM_OPTS    := +ntb_random_seed=$(SEED) +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=$(VERB)

# 可选功能开关
ifdef FSDB
SIM_OPTS += +FSDB +FSDB_FILE=$(WAVE_DIR)/$(TESTNAME).fsdb
endif

ifdef COV
VCS_OPTS += -cm line+cond+fsm+tgl+branch
SIM_OPTS += -cm line+cond+fsm+tgl+branch -cm_dir $(COV_DIR)
endif

ifdef ASSERT
VLOGAN_OPTS += +define+ASSERT_ON
endif

ifdef DEBUG
VLOGAN_OPTS += +define+DEBUG
endif

.PHONY: all build run sim clean clean_all dirs help

all: sim

dirs:
	mkdir -p $(LOG_DIR) $(WAVE_DIR) $(COV_DIR) $(SIMV_DIR)

build: dirs
	$(VLOGAN) $(VLOGAN_OPTS) -f $(FILELIST) | tee $(LOG_DIR)/vlogan.log
	$(VCS) $(VCS_OPTS) $(TB_TOP) -o $(SIMV_DIR)/$(TB_TOP).simv | tee $(LOG_DIR)/vcs.log

run:
	cd $(SIMV_DIR) && ./$(TB_TOP).simv $(SIM_OPTS) | tee ../log/sim.log

sim: build run

clean:
	rm -rf sim/out/$(TESTNAME)_seed_$(SEED)

clean_all:
	rm -rf sim/out

help:
	@echo "Usage:"
	@echo "  make sim TESTNAME=smoke_test SEED=1 VERB=UVM_MEDIUM FSDB=1 COV=1 ASSERT=1"
	@echo ""
	@echo "Targets:"
	@echo "  build      Compile and elaborate"
	@echo "  run        Run existing simv"
	@echo "  sim        Build and run"
	@echo "  clean      Remove current test/seed output"
	@echo "  clean_all  Remove all outputs"
