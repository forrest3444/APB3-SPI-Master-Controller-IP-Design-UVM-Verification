# Interfaces

## Objective
This directory defines the SystemVerilog interfaces on the verification side, used to connect the DUT with UVM components.

## What Files in This Directory Should Do
- Define `apb_if.sv`
- Define `spi_if.sv`
- Provide clocking blocks / modports within the interfaces (if required)

## Functional Boundary
Interfaces are only responsible for signal grouping and timing abstraction; they do **not** handle protocol business logic or scenario generation.

## Mandatory Considerations
- The APB interface must cover all APB signals of the DUT.
- The SPI interface must cover all SPI signals of the DUT.
- Maintain stable naming and signal directions for clocking blocks.
- If modports are used, clearly distinguish between driver and monitor perspectives.
- Lightweight assertions or tasks may be placed inside interfaces, but sparingly.

## Exclusions
- Do not implement transaction semantics within interfaces.
- Do not implement complex scoreboard logic within interfaces.
- Do not embed numerous temporary debug tasks within interfaces.
- Do not turn interfaces into a secondary driver.

## Design Requirements
- Interfaces serve as the only official entry point for timing access on the verification side.
- Minimize direct driving of DUT ports by components via hierarchical paths.
- Implementation should minimize dependencies on the tb_top hierarchy for future agent replacement.
