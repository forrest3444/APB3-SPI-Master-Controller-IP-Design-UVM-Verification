# Test Matrix

| Test | Primary Intent | Main Observations |
|---|---|---|
| `smoke_test` | End-to-end bring-up | One APB-programmed transfer, one SPI frame, one RX readback |
| `mode_sweep_test` | CPOL/CPHA coverage | All four SPI modes exercised with one frame each |
| `fifo_basic_test` | FIFO-visible ordering | Continuous multi-frame transfer with ordered RX draining |
| `irq_basic_test` | Basic interrupt behavior | Underflow, done, tx-empty, and rx-not-empty visibility/clear |
