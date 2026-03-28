# Verification Package

## Objective
This directory manages the organization and unified import of the top-level verification package.

## What Files in This Directory Should Do
- Implement `apb_spi_uvm_pkg.sv`
- Perform a unified `import uvm_pkg::*`
- `include` all configuration, sequence item, agent, environment, and test files
- Unified import of design packages

## Functional Boundary
The package only handles verification file organization and shared imports; it does **not** implement specific verification behaviors.

## Mandatory Considerations
- Maintain a stable `include` order.
- Clearly define dependencies: items/configurations first, then agents/environments, then tests.
- All verification code should be accessed by upper layers primarily through this package.

## Exclusions
- Do not implement actual driver/monitor logic here.
- Do not embed randomization scripts here.
- Do not redefine constants that already exist in the design package; prioritize reuse of the design package.

## Design Requirements
- The package serves as the "unified entry point" for the verification project.
- Minimize fragile file-order dependencies in the filelist.
