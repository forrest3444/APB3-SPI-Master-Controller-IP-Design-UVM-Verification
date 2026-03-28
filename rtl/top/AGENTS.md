# Top-Level Integration

## Objective
This directory is responsible for the integration and interconnection of the top-level module `apb_spi_master_top`.

## Mandatory Scope of Files in This Directory
- Define the formal external functional ports of the DUT.
- Instantiate all first-level submodules:
  - `apb_reg_block`
  - `spi_ctrl`
  - `irq_ctrl`
  - `sync_fifo` x2
- Complete the interconnection of control flow, data flow, and event flow.
- Propagate top-level parameters down to submodules.

## Functional Boundaries
The top-level module only performs "integration" and "signal routing".
It is not responsible for the implementation of specific protocol behaviors, register operations, state machine logic, FIFO storage, or interrupt sticky logic.

## Mandatory Considerations
- Top-level ports must be kept clean, with only the following interfaces retained:
  - APB
  - SPI
  - IRQ
  - clk/reset
- Reset connections must be consistent across all submodules.
- Signal direction between submodules must be clearly defined to avoid ambiguity in bidirectional signal handling.
- The level, empty, and full status signals of the TX/RX FIFO must be correctly fed back to the register, interrupt, and control paths.
- The propagation boundary of the `soft_reset_pulse` signal must be explicitly defined.

## Out of Scope
- No complex combinational or sequential functional logic shall be implemented in the top-level module.
- No APB address decoding shall be implemented in the top-level module.
- No SPI shift and sample logic shall be implemented in the top-level module.
- No interrupt raw or sticky status shall be latched or stored in the top-level module.
- No debug ports shall be exported.

## Design Requirements
- Top-level signal naming must directly reflect its interconnection relationship.
- Interconnections shall use semantic signals only, with no unnecessary internal detail signals propagated.
- For any proposed new top-level signal, the following question must first be answered: does this signal represent true module boundary information?
