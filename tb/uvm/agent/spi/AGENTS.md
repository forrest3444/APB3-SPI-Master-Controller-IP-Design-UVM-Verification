# SPI Agent

## Objective
This directory implements the SPI slave-side verification components, which respond to SPI master transfers initiated by the DUT and collect frame-level transaction results.

## What Files in This Directory Should Do
- Implement `spi_agent`
- Implement `spi_driver`
- Implement `spi_monitor`
- Implement `spi_sequencer`

## Functional Boundary
The SPI agent is only concerned with the behavior on the SPI bus; it does **not** handle APB configuration flows.

## Mandatory Considerations
- The DUT acts as the SPI master, so the verification-side SPI driver essentially functions as a **slave responder**.
- The SPI monitor must collect transactions on a per-frame basis, capturing:
  - SPI mode (CPOL/CPHA)
  - TX byte (transmitted by the DUT)
  - RX byte (responded by the slave)
- Clear definition of **Chip Select (CS)** frame boundaries.
- Unified modeling of sampling and driving edges for all CPOL/CPHA modes.

## Exclusions
- Do not implement register configuration flows in the SPI driver.
- Do not directly read internal DUT registers in the SPI monitor.
- Do not overload the monitor with exhaustive protocol checks.

## Design Requirements
- The SPI agent should start with a minimal slave model to establish a closed-loop verification environment first.
- Monitoring granularity is primarily **frame-based**; bit-level transaction objects are not required initially.
