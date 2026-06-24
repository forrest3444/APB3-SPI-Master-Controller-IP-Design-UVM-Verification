# APB3 SPI Master Controller

**English** | [简体中文](README_CN.md)

An APB3-style SPI master controller with synthesizable SystemVerilog RTL and a UVM verification environment.

## Highlights

- Always-ready 32-bit APB register interface
- SPI modes 0–3, fixed 8-bit frames, MSB first
- Programmable clock divider and automatic chip-select control
- Independent 8-entry TX and RX FIFOs
- Single-frame and continuous-transfer modes
- Raw, masked, level-triggered, and sticky interrupt handling
- Hardware and software reset support
- UVM agents, RAL model, scoreboard, functional coverage, and SVA

## Repository Layout

```text
rtl/          Synthesizable RTL and design specifications
tb/           UVM testbench, tests, sequences, RAL, coverage, and assertions
tb/doc/       Verification plan
doc/          Project documentation assets
```

## Quick Start

The supplied flow uses Synopsys VCS with UVM 1.2. Run commands from the repository root:

```bash
# Build and run the smoke test
make -C tb sim TESTNAME=smoke_test SEED=1

# Run the regression suite
make -C tb regression BUILD_NAME=regression

# Remove generated simulation files
make -C tb clean_all
```

Useful options include `COV=0`, `FSDB=0`, `ASSERT=0`, `DEBUG=1`, and `VERB=UVM_HIGH`.

## Documentation

- [Design specification — English](rtl/doc/apb_spi_master_controller_v1_spec_en.md)
- [Design specification — 中文](rtl/doc/apb_spi_master_controller_v1_spec_cn.md)
- [Verification plan — English](tb/doc/VERIFICATION_PLAN_V1_EN.md)
- [Verification plan — 中文](tb/doc/VERIFICATION_PLAN_V1_CN.md)

## License

This project is released under the [MIT License](LICENSE).
