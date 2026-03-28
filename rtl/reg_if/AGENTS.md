# Register / APB Interface

## Objective
This directory is responsible for APB slave interface access, register mapping, configuration storage, status readback, and data register access.

## Mandatory Scope of Files in This Directory
- Implement the `apb_reg_block` module.
- Handle the core access semantics of the APB3 protocol.
- Implement register read/write decoding.
- Store software-configurable fields:
  - enable
  - cpol
  - cpha
  - cont
  - rx_en
  - tx_en
  - clkdiv
  - irq_en
- Generate command pulses:
  - `start_pulse`
  - `soft_reset_pulse`
- Generate FIFO access control signals:
  - `tx_fifo_wen`
  - `tx_fifo_wdata`
  - `rx_fifo_ren`
- Assemble the `PRDATA` return value.
- Map status registers, FIFO level, and IRQ raw/status signals.

## Functional Boundaries
The `apb_reg_block` module only handles the control plane.
It is not responsible for SPI execution, interrupt sticky bit latching, or FIFO storage implementation.

## Mandatory Considerations
- Fixed APB v1 semantics:
  - `PREADY=1`
  - `PSLVERR=0`
- Address decoding must be clear, stable, and maintainable.
- Pulse-type control bits must be self-clearing.
- The semantics of RO/RW/WO register fields must be strictly enforced without ambiguity.
- The write behavior of `TXDATA` and read behavior of `RXDATA` must be explicitly defined.
- Pending bits in the STATUS register are sourced from the event management plane, and shall not be generated internally within this module.
- Illegal address reads return 0, and illegal address writes are ignored.

## Out of Scope
- No SPI bit-level timing shall be implemented.
- No logic for generating `busy` or `cs_active` shall be implemented.
- No self-maintained sticky status for `done_raw` / `overflow_raw` shall be implemented.
- FIFO shall not be replaced with a register array.
- No debug output ports shall be added.

## Design Requirements
- Register field naming must have a one-to-one correspondence with the spec.
- Constants such as addresses, bit indices, and version numbers shall be sourced from the `pkg/` directory first.
- Outputs to downstream modules shall carry "configuration semantics" and "command semantics", not low-level APB implementation details.
- Code organization shall prioritize clear separation of the read path, write path, and pulse generation logic.
