# Tests

## Objective
This directory contains the UVM test classes that select configuration and launch the frozen v1 scenarios.

## What Files in This Directory Should Do
- Implement `apb_spi_base_test`
- Implement `smoke_test`
- Implement `mode_sweep_test`
- Implement `fifo_basic_test`
- Implement `irq_basic_test`

## Functional Boundary
Tests choose environment configuration and which virtual sequence to run. They do not reimplement protocol stimulus or checking logic.

## Mandatory Considerations
- Keep the four frozen v1 tests as the initial stable test set
- Build and distribute the top-level env cfg object
- Start one virtual sequence per test unless a stronger reason appears later

## Exclusions
- Do not duplicate APB helper code in tests
- Do not move scoreboard logic into tests
- Do not add a large random regression layer before bring-up stabilizes
