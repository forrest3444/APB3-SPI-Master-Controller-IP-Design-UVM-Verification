# Environment

## Objective
This directory is responsible for top-level environment assembly, including the integration of agents, scoreboard, coverage collector, and virtual sequencer.

## What Files in This Directory Should Do
- Implement `apb_spi_env`
- Implement `apb_spi_virtual_sequencer`

## Functional Boundary
The env only handles component assembly and connection; it does **not** implement specific protocol operations or define test scenarios.

## Mandatory Considerations
- Create and instantiate the APB agent and SPI agent
- Create and connect the scoreboard and coverage collector
- Instantiate the virtual sequencer
- Maintain consistent configuration delivery via config_db or direct handle passing
- Establish clear analysis port connections

## Exclusions
- Do not write scenario code inside the env
- Do not implement register access flows directly in the env
- Do not embed scattered debug patches in the env

## Design Requirements
- The env serves as the structural center of the verification system
- All component connections should be clearly visible at a glance within the env
- The configuration distribution path must be stable
