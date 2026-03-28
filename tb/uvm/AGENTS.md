# UVM Verification Root

## Objective
This directory contains all UVM block-level verification files for the APB-SPI Master Controller v1.

## General Verification Principles
- Establish a minimal runnable closed-loop verification environment first, then expand functional features.
- Separate verification logic between the APB side and SPI side.
- Monitors are responsible for signal collection, scoreboards for comparison, coverage for statistics, and tests/sequences for scenario generation.
- The verification environment prioritizes maintainability, extensibility, and debuggability; a heavyweight reference model is not required at the initial stage.
- All common constants, types, and package import paths must be unified.

## Mandatory Considerations
- The DUT is `apb_spi_master_top`.
- Configuration is driven through the APB agent.
- Peripheral behavior is implemented using an SPI agent / slave model.
- The environment mainly supports directed tests, supplemented by random test extensions.
- The `Makefile` and `filelist.f` must serve as the single unified entry point for the entire project.
- Directory responsibilities are clearly defined; files must not be placed across directories arbitrarily.

## Exclusions
- Do not implement all checks inside the monitor.
- Do not implement all stimulus directly in the test.
- Do not write complex check logic in the top-level testbench.
- Do not mix temporary debug scripts into the main verification codebase.
- Avoid excessive use of RAL, complex predictors, and large reference models in v1.

## Subdirectory Responsibilities
- `tb_top/`: Top-level testbench instantiation and interface binding
- `if/`: SystemVerilog interface definitions
- `pkg/`: Top-level verification packages
- `cfg/`: Configuration objects
- `seq_item/`: Transaction objects
- `agent/`: APB/SPI agents
- `seq_lib/`: Sequences and virtual sequences
- `env/`: Verification environment and virtual sequencer
- `scb/`: Scoreboard
- `cov/`: Coverage collection
- `sva/`: Assertions and bind modules
- `tests/`: Test classes
- `sim/`: Simulation output directory
- `doc/`: Verification documentation
