# Agents

## Objective
This directory hosts protocol-level agents that encapsulate protocol-specific stimulus generation and signal observation.

## General Principles
- Each agent encapsulates a **sequencer**, **driver**, and **monitor**.
- The APB agent and SPI agent are **strictly separated**.
- The **monitor** is exclusively responsible for transaction collection, while the **driver** only handles signal driving; their roles must not be mixed.
- The agent defaults to determining its **active/passive** mode via the configuration object (cfg).

## Subdirectories
- `apb/`: APB master agent
- `spi/`: SPI slave-side agent / model
