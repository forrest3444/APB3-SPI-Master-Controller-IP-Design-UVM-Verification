# RTL Root

## Objective
This directory houses all RTL design files for the APB-SPI Master Controller v1.

## General Design Principles
- For v1, priority is given to clear architecture, stable boundaries, and a fully closed functional loop.
- Strict separation of the control plane, execution plane, event plane, and buffer plane is mandatory.
- Formal functional ports shall be kept concise, with no debug ports exposed.
- Debugging is implemented via hierarchical reference to internal signals, without polluting external interfaces.
- Modules in each subdirectory must follow the single-responsibility principle; cross-layer duty encroachment is strictly prohibited.

## v1 Frozen Constraints
- APB3 slave interface with always-ready behavior
- Single chip select (CS) output
- Fixed 8-bit frame length
- MSB-first transmission only
- Support for all four CPOL/CPHA SPI modes
- Integrated TX and RX FIFO buffers
- Automatic chip select (CS) control
- Interrupt management follows the standard 4-register structure: raw, enable, status, and clear
- The `spi_ctrl` module only generates events and shall not store sticky interrupt status
- The `irq_ctrl` module is responsible for unified management of sticky bit latching, masking, and clear operations
- The `apb_reg_block` module only handles register storage and APB access mapping, and shall not implement SPI timing logic
- The `sync_fifo` module only serves as a data buffer and shall not carry any protocol-specific semantics

## Mandatory Considerations
- Stable module boundaries
- Consistent parameter propagation
- Unified naming conventions
- Consistent and predictable reset behavior
- Verifiability and observability: internal critical state signals must have clear, unambiguous naming
- Avoid magic numbers; all common definitions shall be placed in the `pkg/` or `include/` directory

## Out of Scope for v1
- Multi-chip select, DMA, variable frame length, LSB-first, and dual/quad SPI are not implemented in v1
- No functional ports shall be added for debugging purposes
- No implementation-specific detail logic shall be stacked in the top-level module
- No verification-specific logic shall be mixed into the main RTL functional code

## Subdirectory Responsibilities
- `top/`: Top-level integration and interconnection
- `reg_if/`: APB register interface and control plane
- `ctrl/`: SPI control and execution logic
- `fifo/`: Synchronous FIFO
- `irq/`: Interrupt and event management
- `pkg/`: Common packages, typedefs, and constants
- `include/`: Lightweight common macros and definitions; misuse is prohibited

### Fallback Reference Clause
Mandatory directives in AGENTS.md under each directory must always be strictly followed with the highest priority. The spec document in the doc directory may be used as a weak supplementary reference only when no corresponding mandatory rules are found in AGENTS.md, and may be omitted if you have sufficient confidence in the implementation.
