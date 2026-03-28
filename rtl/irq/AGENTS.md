# Interrupt / Event Control

## Objective
This directory is responsible for the logic related to interrupt raw/status/clear/en, implementing event latching, masking, and irq output generation.

## Mandatory Scope of Files in This Directory
- Implement the `irq_ctrl` module.
- Accept two types of interrupt sources:
  - Event-type: `evt_done` / `evt_tx_underflow` / `evt_rx_overflow`
  - Level-type: `level_tx_empty` / `level_rx_not_empty`
- Generate the following signals:
  - `irq_raw`
  - `irq_status`
  - `irq`

## Functional Boundaries
The `irq_ctrl` module only handles event management.
It is not responsible for SPI timing, APB address decoding, or FIFO buffering.

## Mandatory Considerations
- Event-type raw bits are sticky.
- Level-type raw bits reflect real-time status and shall not be incorrectly latched.
- `irq_status = irq_raw & irq_en`.
- `irq_clear` is effective for sticky bits and may be ignored for level-type bits.
- `soft_reset_pulse` must clear all sticky status bits.
- Output semantics must strictly match the register definitions.

## Out of Scope
- No APB read/write decoding shall be implemented.
- No `busy` or `cs_active` signals shall be generated here.
- No frame transmission flow interpretation shall be implemented.
- No debug ports shall be exposed.

## Design Requirements
- Bit order must strictly match the definitions in the spec and `pkg/`.
- Event paths and level paths shall be implemented separately to avoid semantic confusion.
- Sticky logic, mask logic, and irq aggregation logic shall be clearly layered.
