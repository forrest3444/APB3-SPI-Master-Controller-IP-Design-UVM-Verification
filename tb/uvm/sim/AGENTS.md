# Simulation Output

## Objective
This directory is used to organize all simulation-generated files.

## What Files in This Directory Should Do
- `out/`: Run directories partitioned by test name and seed
- `log/`: Simulation log files
- `wave/`: Waveform databases
- `cov/`: Coverage databases and reports

## Functional Boundary
This directory stores **only runtime outputs**, no source code.

## Mandatory Considerations
- Stable directory structure for easy script access
- No overwriting between different tests / seeds
- Separate storage for logs, waveforms, and coverage

## Exclusions
- Do not place temporary source files here
- Do not store manual patches here
- Do not scatter fragmented compile scripts

## Design Requirements
- Directory naming consistent with the Makefile
- Logs should be preserved as much as possible even if simulation fails
