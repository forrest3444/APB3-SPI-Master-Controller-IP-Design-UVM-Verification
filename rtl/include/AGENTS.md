# Include

## Objective
This directory is used to store lightweight common header files, such as simple macros, unified definitions, and conditional compilation flags.

## Mandatory Scope of Files in This Directory
- Place lightweight definition files such as `apb_spi_defs.svh`.
- Host a small number of truly necessary common preprocessing content.

## Functional Boundaries
The `include/` directory is not a second `pkg/`.
It is only suitable for placing "the minimal common content at the preprocessing level".

## Mandatory Considerations
- If a definition is suitable for a `package`, place it in `pkg/` first, not here.
- The content in include files must be sufficiently minimal, stable, and necessary.
- Conditional compilation flags, if present, must be simple and straightforward.

## Out of Scope
- No large blocks of behavioral logic shall be placed here.
- No main register map definitions shall be placed here; register constants shall be prioritized in `pkg/`.
- Macros shall not be abused to replace normal SystemVerilog constructs.
- No verification-specific content shall be stuffed here.
- No debug functional ports shall be added via macros.

## Design Requirements
- Avoid using macros whenever possible.
- Include files shall maintain low complexity; otherwise, subsequent maintenance will be poor.
- The content here shall be the type of files with the least changes in the entire project.
