# Coverage

## Objective
This directory is responsible for functional coverage sampling and statistics collection.

## What Files in This Directory Should Do
- Implement `apb_spi_coverage`
- Consume transactions output by the APB / SPI monitors
- Sample key configuration and behavioral coverage points

## Functional Boundary
The coverage component **only performs statistics collection**; it does not perform result checking or signal driving.

## Mandatory Considerations
- Cross coverage for CPOL × CPHA modes
- Single frame vs. continuous transfer modes
- Combinations of tx_en / rx_en enable signals
- Basic clock divider (clkdiv) value bins
- Hit coverage for TX/RX FIFO empty/full states
- Coverage for basic IRQ types
- Basic frame transmit and receive scenarios

## Exclusions
- Do not implement complex comparison logic within the coverage collector
- Do not primarily sample internal signals via hierarchical sniffing; prioritize sampling monitor transactions
- Do not hardcode logic in components "just to hit coverage goals"

## Design Requirements
- Adopt a "coarse first, then refine" strategy for the coverage model
- Covergroup definitions must directly map to the verification plan
