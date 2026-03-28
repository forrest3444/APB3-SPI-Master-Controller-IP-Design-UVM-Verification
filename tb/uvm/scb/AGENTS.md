# Scoreboard

## Objective
This directory implements the core comparison logic for verifying the functional correctness of the DUT.

## What Files in This Directory Should Do
- Implement `apb_spi_scoreboard`
- Consume transactions from both the APB monitor and SPI monitor
- Perform critical checks on register behavior, frame operations, FIFO data integrity, etc.

## Functional Boundary
The scoreboard determines **whether the results are correct**; it does **not** generate stimulus or perform signal sampling.

## Mandatory Considerations
- Correlation between APB writes to TXDATA register and SPI transmitted bytes
- Correlation between SPI slave response data and RXDATA register reads
- Continuous multi-frame behavior in continuous mode
- Consistency between interrupt/status flags and actual bus operations
- Check granularity focused on frame-level and register-visible behavior

## Exclusions
- Do not drive DUT signals directly from the scoreboard
- Do not rely on hierarchical path reads of internal DUT states as the primary checking mechanism
- Do not mix coverage collection logic within the scoreboard

## Design Requirements
- Start with simple, reliable queue-based expected/actual comparison
- Prioritize debuggability and error localization over complex predictive modeling
- Error logs must be detailed enough to quickly identify root causes
