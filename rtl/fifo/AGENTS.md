# FIFO

## Objective
This directory is responsible for the implementation of a generic synchronous FIFO, which provides buffering for the TX/RX data paths.

## Mandatory Scope of Files in This Directory
- Implement the parameterized `sync_fifo` module.
- Provide the minimum required interface:
  - `w_en`
  - `w_data`
  - `full`
  - `r_en`
  - `r_data`
  - `empty`
  - `level`

## Functional Boundaries
The FIFO only serves as a data buffer.
It is not responsible for SPI protocol, APB protocol, interrupt semantics, or state machine scheduling.

## Mandatory Considerations
- Single-clock synchronous FIFO architecture.
- Stable, consistent semantics for the `full`, `empty`, and `level` signals.
- Well-defined post-reset state:
  - `empty=1`
  - `full=0`
  - `level=0`
- Behavior during simultaneous read and write operations must be consistently and explicitly defined.
- The bit width of the `level` signal must match the `DEPTH` parameter.
- The implementation must be suitable for reuse as both the TX FIFO and RX FIFO.

## Out of Scope
- No `almost_full` or `almost_empty` signals shall be implemented.
- No protocol-specific side effects shall be added.
- No interrupt logic shall be implemented.
- No debug output ports shall be added.
- No high-level semantics such as "frame" or "transaction" shall be interpreted within the FIFO.

## Design Requirements
- The FIFO shall remain generic, with no dependency on APB-SPI specific naming or logic.
- If First-Word Fall-Through (FWFT) or non-FWFT semantics are adopted, the implementation must be consistent throughout with no ambiguous behavior.
- The timing relationship between the output data `r_data` and read enable `r_en` must be clearly defined, to ensure straightforward integration with the downstream register and control modules.
