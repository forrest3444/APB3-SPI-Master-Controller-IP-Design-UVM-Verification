# Testbench Top

## Objective
This directory is responsible for testbench top-level instantiation, interface connections, clock/reset generation, and config_db configuration injection.

## What Files in This Directory Should Do
- Instantiate the DUT.
- Instantiate APB / SPI interfaces.
- Generate clock and reset signals.
- Inject virtual interfaces into the test/env via `uvm_config_db`.
- Bind SVA modules (if using the bind methodology).
- Invoke `run_test()` to start the UVM test.

## Functional Boundary
The tb_top only performs system assembly; it does **not** generate stimulus, conduct transaction comparison, or implement complex protocol checks.

## Mandatory Considerations
- Maintain one-to-one port connections for the DUT.
- Ensure stable reset initial value and release timing.
- Use consistent naming for APB / SPI interfaces.
- Use fixed paths for all virtual interface injections.
- For hierarchical debugging, tb_top is the **only** location permitted to reference internal DUT paths centrally.

## Exclusions
- Do not write directed test cases in tb_top.
- Do not implement scoreboard logic in tb_top.
- Do not include coverage collection logic in tb_top.
- Do not add excessive print statements in tb_top.

## Design Requirements
- Keep the tb_top as lightweight as possible.
- Ensure interface and DUT connections are clear and readable.
- Pass all environment-dependent resources exclusively through config_db or explicit binding.
