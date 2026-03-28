# SPI Control / Execution

## Objective
This directory is responsible for the execution core of the SPI Master, including the state machine, clock division, edge event generation, data shifting, sampling, chip select (CS) control, and frame completion handling.

## Mandatory Scope of Files in This Directory
- Implement the `spi_ctrl` module.
- Execute SPI master behavior according to configuration parameters:
  - CPOL
  - CPHA
  - cont
  - tx_en
  - rx_en
  - clkdiv
- Generate the following SPI interface signals:
  - `spi_sclk`
  - `spi_mosi`
  - `spi_cs_n`
- Consume data from the TX FIFO.
- Generate write requests to the RX FIFO.
- Output status signals:
  - `status_busy`
  - `status_cs_active`
- Output event signals:
  - `evt_done`
  - `evt_tx_underflow`
  - `evt_rx_overflow`

## Functional Boundaries
The `spi_ctrl` module belongs to the execution plane.
It is not responsible for APB register access, interrupt masking/clearing/sticky bit latching, or internal FIFO storage implementation.

## Mandatory Considerations
- Fixed 8-bit frame length for v1.
- A unified abstraction must be implemented for the four SPI modes, with no scattered conditional checks for CPOL/CPHA across the code.
- Explicit abstraction of the following signals is recommended:
  - `leading_edge_pulse`
  - `trailing_edge_pulse`
  - `sample_edge_pulse`
  - `shift_edge_pulse`
- The idle level of SCLK must strictly match the `cpol` configuration.
- CS must remain asserted between frames in continuous (cont) mode.
- Dummy data (8'h00) shall be transmitted when `tx_en=0`.
- Valid received data shall not be written to the RX FIFO when `rx_en=0`.
- Event outputs shall be instantaneous single-cycle pulses; no sticky bit latching shall be implemented within this module.
- The `soft_reset_pulse` must reliably abort and clear the internal execution state.

## Out of Scope
- No APB address decoding shall be implemented.
- No interrupt raw/status state shall be latched or stored.
- No software register mirroring shall be implemented.
- TX/RX FIFO shall not be replaced with an internal array.
- No debug ports shall be exposed.

## Design Requirements
- The main state machine is recommended to be kept concise, with the states: `IDLE / LOAD / SHIFT / FRAME_DONE`.
- Internal critical state signals must have clear, unambiguous naming to facilitate hierarchical debugging.
- The logic for the bit counter, divider counter, shift register, CS active state, and SCLK generation shall be separated.
- For any exception paths, priority shall be given to ensuring the state machine can reliably converge back to the IDLE state.
