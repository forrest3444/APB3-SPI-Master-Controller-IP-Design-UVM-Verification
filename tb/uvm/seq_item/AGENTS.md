# Sequence Items

## Objective
This directory defines the transaction objects used as the common exchange format between drivers, monitors, and scoreboards.

## What Files in This Directory Should Do
- Define `apb_trans`
- Define `spi_frame`
- Define lightweight virtual sequence items only if absolutely necessary

## Functional Boundary
Transactions only describe **what happened**; they do **not** specify **who will do it** or **how to do it**.

## Mandatory Considerations
- APB transaction must include at minimum:
  - Address
  - Read/write command
  - Write data
  - Read data
  - Optional response/metadata
- SPI frame must include at minimum:
  - CPOL/CPHA mode
  - Transmit byte
  - Receive byte
  - Frame index / chip-select window metadata (if required)
- Complete implementations of `do_copy`, `do_compare`, and `convert2string`
- Monitor output format must be directly usable by the scoreboard and coverage collector

## Exclusions
- Do not store driver private state in items
- Do not embed complex reference model behavior in items
- Do not store interface handles in items

## Design Requirements
- Transaction fields should be stable to avoid frequent format changes
- Define each semantic only once; avoid redundant definitions across multiple directories
