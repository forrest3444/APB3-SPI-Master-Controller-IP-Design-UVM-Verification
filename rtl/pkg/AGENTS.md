# Package

## Objective
This directory is responsible for centrally housing shared definitions such as common typedefs, state machine types, address constants, bit indices, and version numbers.

## Mandatory Scope of Files in This Directory
- Implement the `apb_spi_pkg.sv` file.
- Provide the following shared definitions:
  - Register offsets
  - IRQ bit indices
  - VERSION constants
  - SPI state machine enum
  - Other cross-module shared typedefs / localparams

## Functional Boundaries
The `pkg/` directory only contains "shared definitions".
It shall not contain specific implementation logic, module behavior, or complex macro "magic".

## Mandatory Considerations
- All constants used by multiple modules shall be placed here first.
- Naming shall be unified and semantically straightforward.
- Enums / typedefs shall serve readability and consistency.
- Magic numbers shall be avoided from being repeated across modules.

## Out of Scope
- No module implementation shall be written here.
- No large combinational logic functions shall be placed here, unless absolutely necessary and sufficiently generic.
- No verification-specific content shall be mixed into the design package.
- No redundant definitions of the same semantic via parameter/localparam shall be abused.

## Design Requirements
- Definitions here shall be as stable as possible to avoid frequent changes that trigger full-project recompilation.
- Bit definitions must be one-to-one aligned with the register documentation.
- The package shall serve as the "single source of truth for constants" across the entire design.
