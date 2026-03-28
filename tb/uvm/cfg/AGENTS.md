# Configuration Objects

## Objective
This directory manages the verification environment configuration objects, which store enable switches, parameters, and resource handles for the environment and agents.

## What Files in This Directory Should Do
- Define `apb_spi_env_cfg`
- Define `apb_agent_cfg`
- Define `spi_agent_cfg`

## Functional Boundary
Configuration objects (cfg) only store configuration data; they do **not** execute business logic.

## Mandatory Considerations
- Active/passive mode enable switches
- Virtual interface handles
- Enable flags for coverage, scoreboard, and assertions
- Default SPI mode and clock-related parameters (if required by the verification environment)
- Support for future randomized configuration extensions

## Exclusions
- Do not store runtime status information in cfg objects.
- Do not store transaction buffers in cfg objects.
- Do not use cfg objects to make decisions on behalf of environments or agents.
- Do not implement complex tasks or functions in cfg objects.

## Design Requirements
- Configuration objects serve as "environment configuration inputs," not global storage bins.
- Field names must clearly reflect their purpose.
- The top-level test creates and distributes cfg objects; child components only consume them.
