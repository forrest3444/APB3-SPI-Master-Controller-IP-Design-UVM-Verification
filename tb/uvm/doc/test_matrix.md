# Test Matrix

| Test | Primary Intent | Main Observations |
|---|---|---|
| `smoke_test` | End-to-end bring-up | One APB-programmed transfer, one SPI frame, one RX readback |
| `apb_reg_access_test` | Register access policy | RW/RO/WO behavior and reserved-bit handling across the map |
| `clkdiv_test` | Programmable divider sweep | Directed min/typical values plus randomized safe divider values |
| `mode_sweep_test` | CPOL/CPHA coverage | All four SPI modes exercised with one frame each |
| `fifo_basic_test` | FIFO-visible ordering | Continuous multi-frame transfer with ordered RX draining |
| `fifo_boundary_test` | FIFO limit behavior | TX full saturation plus RX overflow and TX underflow visibility |
| `cont_mode_test` | Continuous CS behavior | CS stays asserted across multiple frames and releases at completion |
| `irq_basic_test` | Basic interrupt behavior | Underflow, done, tx-empty, and rx-not-empty visibility/clear |
| `irq_stress_test` | Interrupt stress and masking | Sticky plus level IRQ interactions, mask transitions, overflow, underflow, clear, and soft-reset persistence |
| `soft_reset_test` | Soft reset recovery | Mid-transfer reset clears FIFOs/IRQs and allows a clean restart |
