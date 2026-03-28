# Sequence Library

## Objective
This directory organizes sequences and virtual sequences, defining all stimulus scenarios for the verification environment.

## What Files in This Directory Should Do
- Implement base sequences
- Implement APB / SPI sub-sequences
- Implement virtual sequencer
- Implement virtual sequences
- Define test scenarios: smoke, mode, FIFO, IRQ, etc.

## Functional Boundary
Sequences define **what scenarios to generate**; they do **not** handle protocol sampling or final result comparison.

## Mandatory Considerations
- Base virtual sequence (vseq) must uniformly obtain environment cfg and p_sequencer.
- Abstract APB configuration flows into reusable helper tasks.
- SPI slave response behavior can coordinate with APB operations in virtual sequences.
- Tests should not contain excessive timing details; scenario specifics should be encapsulated in sequences.

## Exclusions
- Do not hardcode scoreboard checks within sequences.
- Do not let tests directly replace sequences.
- Avoid overly complex random constraints; v1 prioritizes controllable directed tests.

## Design Requirements
- Names must clearly reflect the scenario purpose.
- Prioritize reusable helper tasks:
  - Register write/read
  - FIFO fill/drain
  - Start transfer
  - IRQ clear/check
