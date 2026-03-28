# Verification Plan

## Scope
- DUT: `apb_spi_master_top`
- v1 focus: closed-loop APB configuration, SPI frame movement, FIFO-visible behavior, and basic IRQ observability

## Planned Bring-Up Order
1. Interfaces and cfg objects
2. APB and SPI agents
3. Env, virtual sequencer, scoreboard, and coverage
4. Frozen v1 tests: smoke, mode sweep, FIFO basic, IRQ basic
5. Basic assertions and later refinement

## Pass Criteria
- The four frozen tests compile from the single `Makefile` and `filelist.f` flow
- APB writes to `TXDATA` correlate with SPI MOSI bytes
- SPI slave response bytes correlate with APB reads from `RXDATA`
- Basic IRQ raw/status bits become observable and clearable through APB
