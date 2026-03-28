# Assertions

## Objective
This directory is responsible for protocol-level and critical timing-level assertions.

## What Files in This Directory Should Do
- Basic APB protocol assertions
- Basic SPI protocol / timing assertions
- Bind files

## Functional Boundary
SVA is responsible for checking invariants and timing constraints; it is **not** responsible for closed-loop functional scenario verification.

## Mandatory Considerations
- Basic validity of APB setup / access phases
- Consistency between SPI CS active window and SCLK behavior
- Fundamental relationship between busy and cs_active signals
- Appropriate coverage for key state machine / output constraints

## Exclusions
- Do not rely entirely on assertions for functional correctness.
- Do not write complex behavioral logic in bind files.
- Do not make SVA deeply dependent on test-specific scenarios.

## Design Requirements
- For v1, implement only high-value basic assertions first.
- Use clear bind relationships to avoid fragile hierarchical paths.
