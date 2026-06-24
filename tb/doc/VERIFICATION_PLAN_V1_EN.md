[中文](VERIFICATION_PLAN_V1_CN.md) | **English**

# APB-SPI Master Controller v1 — Verification Plan

**DUT:** `apb_spi_master_top`

**Document version:** 1.1

**Status:** v1 review baseline

**Methodology:** SystemVerilog / UVM 1.2

---

## 1. Overview

### 1.1 Purpose

This document defines the functional verification scope, environment, features, tests, coverage, assertions, regressions, and sign-off criteria for APB-SPI Master Controller v1. The RTL specification is the sole functional baseline. A disagreement between the specification, RTL, and a test expectation must be resolved as a specification issue first; checkers must not be weakened to hide it.

### 1.2 References

| ID | Document |
| --- | --- |
| R1 | [RTL specification — 中文](../../rtl/doc/apb_spi_master_controller_v1_spec_cn.md) |
| R2 | [RTL specification — English](../../rtl/doc/apb_spi_master_controller_v1_spec_en.md) |
| R3 | `rtl/apb_spi_pkg.sv` |
| R4 | `tb/ral/apb_spi_reg_block.sv` |

### 1.3 Baseline Precedence

Verification expectations are determined in this order:

1. Frozen functional and software-visible semantics in the RTL specification.
2. General APB3/SPI protocol rules referenced but not overridden by the specification.
3. `apb_spi_pkg.sv` and RAL are used only to check that addresses, widths, and field mappings agree with the specification.
4. Current RTL, UVM environment, test results, and coverage reports are implementation-status references only and must not redefine expected behavior.

When a lower-priority source conflicts with a higher-priority baseline, record the issue and derive the checker expectation from the specification. The affected feature cannot be signed off until the conflict is closed.

### 1.4 Scope

**In scope:**

- All 12 software-visible registers and their RW/RO/WO/reserved semantics
- APB3-style always-ready transfers and illegal-address behavior
- Four SPI CPOL/CPHA modes, 8-bit MSB-first transfers
- CLKDIV, TX/RX FIFOs, single-frame and continuous transfers
- Raw, mask, clear, and output behavior of all five interrupt sources
- Cold reset, software reset, and specified error scenarios
- Functional coverage, code coverage, and SVA

**Out of scope:**

- Gate-level simulation, STA, power, DFT, and formal verification
- DMA, multiple chip selects, variable frame size, LSB-first, dual/quad SPI
- Dynamic reconfiguration during a transfer, which the specification declares unsupported

---

## 2. DUT and Specification Baseline

### 2.1 Interfaces and Architecture

| Interface | Key semantics |
| --- | --- |
| APB | 12-bit address, 32-bit data, `PREADY=1`, `PSLVERR=0` |
| SPI | One CS, modes 0–3, 8-bit, MSB-first |
| IRQ | `irq = \|(IRQ_RAW & IRQ_EN)` |

The DUT consists of `apb_reg_block`, `spi_ctrl`, two `sync_fifo` instances, and `irq_ctrl`. Verification primarily uses APB/SPI externally visible behavior. Internal signals are used only by assertions, coverage, and debug.

### 2.2 Normative Semantics

- After reset, `CTRL=0x0000_0060`, `STATUS=0x0000_000A`, and `CLKDIV=1`.
- After reset, `IRQ_RAW=0x0000_0002` because `tx_empty_raw` is a live level source; `IRQ_STATUS=0`.
- Reads of `TXDATA` and `IRQ_CLEAR` return zero. Writes to RO or reserved fields are ignored.
- Reads from unmapped or unaligned addresses return zero; writes have no side effect; `PSLVERR` remains zero.
- `effective_div = (CLKDIV == 0) ? 1 : CLKDIV`, and `T_SCLK = 2 × effective_div × T_PCLK`.
- Start is accepted only in `IDLE`; start while busy is ignored.
- With enable=1, tx_en=1, and an empty TX FIFO, start reports underflow and does not start a frame.
- With tx_en=0 and rx_en=1, the controller transmits dummy `0x00`. With tx_en=rx_en=0, start is ignored.
- With cont=1 and tx_en=1, one start may drain multiple FIFO entries. Normal FIFO-empty termination does not report underflow.
- Software reset wins when start and soft_reset are written together.
- Software reset aborts the transfer and clears FIFOs and sticky IRQs. CLKDIV and IRQ_EN remain unchanged; CTRL RW fields take the values from the same CTRL write.
- Clear wins when a sticky event and IRQ_CLEAR occur in the same cycle. IRQ_CLEAR does not affect level interrupts.

---

## 3. Verification Objectives

| ID | Objective | Acceptance focus |
| --- | --- | --- |
| OBJ-REG | Register semantics | Reset, RW/RO/WO, reserved, VERSION, illegal addresses |
| OBJ-APB | APB protocol | Setup/access, always-ready, no error, back-to-back transfers |
| OBJ-SPI | SPI data and timing | Four modes, 8-bit, MSB-first, CS/SCLK/MOSI/MISO |
| OBJ-CLK | Divider | Equivalent 0/1, typical, random, and maximum values |
| OBJ-FIFO | FIFOs | Ordering, level, empty/full, ignored full write, empty read, RX overflow |
| OBJ-IRQ | Interrupts | Sticky/level, mask, clear priority, combined irq |
| OBJ-CONT | Continuous mode | One start, multiple frames in one CS window, normal termination |
| OBJ-RST | Reset | Cold-reset outputs, active software reset, retention, and recovery |
| OBJ-ROB | Robustness | Start rejection, underflow/overflow, random stress, no deadlock |

All functional errors must be detected automatically by a self-checking sequence, scoreboard, or assertion. Manual waveform inspection is for debug only and is not a PASS criterion.

---

## 4. Verification Architecture and Implementation Reference

This section describes the planned verification architecture and identifies its current repository implementation. Component availability does not change the specification-derived requirements in Sections 2, 3, and 7.

### 4.1 Components

| Component | Responsibility |
| --- | --- |
| APB agent | Drives two-phase APB transfers and publishes completed accesses |
| SPI agent | Acts as a reactive slave, drives MISO, and monitors SPI frames |
| Virtual sequencer | Coordinates APB and SPI sequences |
| RAL model | Describes 12 registers, field access policies, and frontdoor mapping |
| Scoreboard | Compares TXDATA→MOSI and MISO→RXDATA and predicts FIFO/IRQ state |
| Coverage collector | Samples functional coverage from APB/SPI monitor transactions |
| SVA | Checks APB, SPI, and selected internal invariants |

### 4.2 Checking Principles

- Data checking uses in-order queues; no expected transaction may remain at test completion.
- State prediction must implement specification semantics rather than simply copy DUT expressions.
- RAL is used for mapped register and field access. Raw APB transactions check WO/RO side effects and illegal addresses.
- Coverage proves that a scenario occurred; it does not replace a result checker.
- Every timeout must be bounded using frame count and `effective_div`.

### 4.3 Repository Organization

```text
tb/
├── agent/       APB/SPI agents
├── env/         environment, scoreboard, coverage, virtual sequencer
├── ral/         register model and adapter
├── seq_lib/     virtual sequences
├── tests/       executable UVM tests
├── sva/         assertions and bind
├── tb_top/      interfaces and testbench top
├── Makefile
└── run_regression.sh
```

---

## 5. Verification Methods

| Method | Application |
| --- | --- |
| Directed tests | Registers, modes, boundaries, reset, and explicit error scenarios |
| Constrained random | CLKDIV, IRQ mask/clear ordering, and long-sequence stress |
| Scoreboard | End-to-end data, FIFO, and IRQ prediction |
| SVA | Cycle-level protocols and internal invariants |
| Functional coverage | Feature scenarios and meaningful cross combinations |
| Code coverage | Finds unexercised RTL; it cannot prove functional correctness by itself |

“Error injection” in this plan means triggering underflow or overflow through legal software operations. No DUT internal state is forced, so these tests are classified as negative directed tests.

---

## 6. Traceability Rules

Every feature must map to at least one executable test and one automated checker. Multiple logical TCs may be combined into one executable UVM test:

```text
SPEC requirement → Feature ID → Logical TC ID → executable UVM test
                 → checker/assertion → coverage bin
```

An item marked `GAP` is required by this plan but is not fully automated yet. It must be implemented or formally waived before sign-off.

---

## 7. Feature List

### 7.1 Priority

| Priority | Definition |
| --- | --- |
| P0 | Core behavior; must pass every release regression |
| P1 | Important boundary or robustness behavior; required before release |
| P2 | Additional stress or diagnostics; may be deferred after review |

### 7.2 Features

This table contains only normative verification requirements derived from the specification. Current completion and GAP status are listed separately in Section 8.

| Feature | Specification-derived requirement | Priority | Logical TC |
| --- | --- | ---: | --- |
| F-REG-01 | Observable reset values of all 12 registers, including IRQ_RAW=0x2 | P0 | TC-REG-01 |
| F-REG-02 | CTRL/CLKDIV/IRQ_EN RW and reserved fields | P0 | TC-REG-02/03 |
| F-REG-03 | start/soft_reset/TXDATA/IRQ_CLEAR WO effects and read-as-zero | P0 | TC-REG-04 |
| F-REG-04 | Ignored writes to STATUS/RXDATA/IRQ/FIFO_LVL/VERSION | P0 | TC-REG-05 |
| F-REG-05 | Zero reads and side-effect-free writes for illegal/unaligned addresses | P0 | TC-REG-06 |
| F-REG-06 | VERSION=0x0001_0000 | P1 | TC-REG-07 |
| F-APB-01 | Setup→access, PREADY=1, PSLVERR=0 | P0 | TC-APB-01 |
| F-APB-02 | Legal back-to-back reads/writes and direction changes | P1 | TC-APB-02 |
| F-SPI-01 | Sampling edge, shift edge, and idle level in modes 0–3 | P0 | TC-SPI-01 |
| F-SPI-02 | Single-frame 8-bit MSB-first transfer, CS boundary, and done | P0 | TC-SPI-02 |
| F-SPI-03 | All tx_en/rx_en combinations and dummy/no-op behavior | P1 | TC-SPI-03 |
| F-SPI-04 | Start acceptance/rejection, busy-start ignore, command priority | P1 | TC-SPI-04 |
| F-CLK-01 | `2×effective_div×T_PCLK` for 0/1/typical/random values | P0 | TC-CLK-01 |
| F-CLK-02 | Equivalent CLKDIV 0/1 and completion at maximum value | P1 | TC-CLK-02 |
| F-FIFO-01 | TX/RX ordering and level | P0 | TC-FIFO-01 |
| F-FIFO-02 | Ignored full TX write and empty/full boundaries | P1 | TC-FIFO-02 |
| F-FIFO-03 | Drop newest RX byte and latch overflow when full | P1 | TC-FIFO-03 |
| F-CONT-01 | One start, multiple frames, CS held in cont=1 | P0 | TC-CONT-01 |
| F-CONT-02 | One start and independent CS window per frame in cont=0 | P0 | TC-CONT-02 |
| F-IRQ-01 | Done sticky lifecycle | P0 | TC-IRQ-01 |
| F-IRQ-02 | Live tx_empty/rx_not_empty level behavior | P0 | TC-IRQ-02 |
| F-IRQ-03 | Underflow/overflow sticky behavior and clear | P1 | TC-IRQ-03 |
| F-IRQ-04 | IRQ_EN mask and combined irq | P0 | TC-IRQ-04 |
| F-IRQ-05 | No effect when clearing level IRQ; clear wins same-cycle event | P1 | TC-IRQ-05 |
| F-RST-01 | Cold-reset register values and safe SPI/irq outputs | P0 | TC-RST-01 |
| F-RST-02 | Software reset during an active transfer and recovery | P0 | TC-RST-02 |
| F-RST-03 | Software-reset retention of CLKDIV/IRQ_EN and same-write CTRL values | P1 | TC-RST-03 |

---

## 8. Test and Implementation Mapping

### 8.1 Current Executable Tests

| Executable test | Logical TCs | Main checks |
| --- | --- | --- |
| `smoke_test` | TC-SPI-02 | Basic APB→SPI→RX loop |
| `apb_reg_access_test` | TC-REG-01/02/03/04/05/07 | Broad register access and side effects |
| `apb_reg_semantics_test` | TC-REG-01/04/05/06/07 | Reset, WO/RO, illegal address, VERSION |
| `mode_sweep_test` | TC-SPI-01/02, TC-CONT-02 | Single frame in each SPI mode |
| `clkdiv_test` | TC-CLK-01/02 | Divider equation, 0/1/max, random values |
| `fifo_basic_test` | TC-FIFO-01, TC-CONT-01 | Continuous TX/RX FIFO ordering |
| `fifo_boundary_test` | TC-FIFO-02/03, TC-IRQ-03 | Full boundaries, overflow, underflow |
| `cont_mode_test` | TC-CONT-01 | Multiple frames in one CS window |
| `irq_basic_test` | TC-IRQ-01/04 | Basic underflow, done, mask, and clear path |
| `irq_stress_test` | TC-IRQ-01/02/03/04/05 | Multiple sources, mask changes, clear, software reset |
| `soft_reset_test` | TC-RST-02/03 | Active software reset and recovery |

### 8.2 Directed Scenarios Required Before Sign-off

| Scenario | Expected result |
| --- | --- |
| Unaligned addresses `0x01/0x03/0x31` | Read zero, no write effect, PSLVERR=0 |
| Start with enable=0 | No transfer and no underflow |
| Start with tx_en=rx_en=0 | No transfer and no underflow |
| tx_en=0, rx_en=1 | MOSI=0x00 and one received frame; cont=1 does not auto-continue |
| tx_en=1, rx_en=0 | Normal transmit and no RX FIFO increment |
| Start while busy | Current frame unaffected and no extra frame |
| start and soft_reset in one write | Reset wins and no frame starts |
| Event and IRQ_CLEAR in one cycle | Sticky bit remains clear |
| Multiple cont=0 frames | Wait for IDLE before each start; independent CS windows |
| Cold-reset outputs | CS=1, MOSI=0, SCLK=reset CPOL, irq=0, no X/Z |

Randomized tests must record their seed and be reproducible with one seed.

---

## 9. Coverage Plan

### 9.1 Current Functional Coverage

| Covergroup | Current content | Limitation |
| --- | --- | --- |
| `cfg_cg` | mode, cont, tx/rx enables, cross, coarse CLKDIV | No explicit CLKDIV=0; cross needs ignore_bins |
| `fifo_cg` | TX/RX empty, partial, full | STATUS-read sampling does not prove every transition |
| `irq_cg` | Occurrence of five IRQ sources | No mask/clear/priority lifecycle |
| `frame_cg` | Single/multiple frame | Continuous-window frame-count bins need definition |

### 9.2 Required Additions

- All 12 legal addresses, illegal aligned addresses, and unaligned addresses.
- RW/RO/WO/reserved access type plus completed-result events.
- CLKDIV bins: 0, 1, 2–7, 8–63, 64–254, 255.
- Start result: accepted, disabled, underflow, both-disabled, busy-ignored, reset-priority.
- TX/RX FIFO empty↔partial↔full transitions.
- Assert, masked, unmasked, clear, and level-clear-no-effect for every IRQ source.
- Software reset in IDLE, SHIFT, and FRAME_DONE with empty/partial/full FIFOs.
- CPOL/CPHA × cont and CPOL/CPHA × key CLKDIV ranges.

Cross coverage must contain only meaningful reachable combinations, using `ignore_bins` for irrelevant or specification-forbidden combinations. The target is 100% of valid P0/P1 functional bins, with every associated checker passing.

### 9.3 Code Coverage

| Type | Target |
| --- | ---: |
| Line | ≥95% |
| Branch | ≥90% |
| Toggle | ≥90% |
| FSM state/legal transition | 100% |

Constants, unreachable defensive branches, and tool-generated logic may be waived only with a recorded rationale, RTL revision, and approver.

---

## 10. Assertion Plan

### 10.1 Currently Implemented

| Assertion | Check |
| --- | --- |
| APB setup→access | Access follows setup on the next cycle |
| APB always-ready | PREADY=1 during access |
| APB no-error | PSLVERR=0 during access |
| CS/status consistency | `status_cs_active == !spi_cs_n` |
| Busy/CS consistency | CS is active while busy |
| Idle SCLK | SCLK=CPOL while CS is inactive |

### 10.2 Required Before Sign-off

| ID | Check | Priority |
| --- | --- | ---: |
| AS-APB-01 | `PENABLE -> PSEL` | P0 |
| AS-APB-02 | Stable PADDR/PWRITE/PWDATA from setup through access | P0 |
| AS-SPI-01 | SCLK changes only while CS is active | P0 |
| AS-SPI-02 | Exactly eight sample edges per frame | P0 |
| AS-SPI-03 | MOSI stable at sample edge and updated only by frame preload or shift edge | P0 |
| AS-SPI-04 | SCLK half-period matches effective_div during SHIFT | P0 |
| AS-FIFO-01 | FIFO level always within 0..DEPTH | P0 |
| AS-FIFO-02 | No accepted write when full and no accepted read when empty | P1 |
| AS-IRQ-01 | `irq == \|(irq_raw & irq_en)` | P0 |
| AS-IRQ-02 | Sticky set/clear priority matches the specification | P1 |
| AS-RST-01 | CS/busy/FIFOs/sticky sources clear within a bounded reset interval | P0 |
| AS-X-01 | No X/Z on external outputs after reset release | P0 |

The current SVA suite has no independent S0/S1 severity encoding. Therefore, every assertion failure fails the regression.

---

## 11. Regression Plan

### 11.1 Smoke

Run on each RTL/TB commit or pull request, targeting completion within five minutes:

```text
apb_reg_semantics_test
smoke_test
mode_sweep_test
fifo_basic_test
irq_basic_test
soft_reset_test
```

The pass requirement is 100%, with zero UVM_ERROR/FATAL and zero assertion failures.

### 11.2 Base

- Run all 11 executable tests under `tb/tests/`, excluding `apb_spi_base_test`, every day.
- Directed tests run at least seed 1. Tests containing randomization run at least five fixed reproducible seeds.
- The required pass rate is 100%; there is no “2% allowed failure” rule.
- Archive the failure log, seed, commit ID, and simulator version.

### 11.3 Full

- Run the complete Base set and all added GAP tests weekly and before release.
- Run randomized tests with at least 20 seeds and merge code and functional coverage.
- All tests, assertions, and P0/P1 coverage targets must pass.
- A shortfall requires a formal waiver; removing bins or reducing checker severity is not an acceptable workaround.

Regression tooling should use explicit smoke/base/full manifests. Automatic discovery of all `*_test.sv` files is acceptable only as the default Base behavior.

---

## 12. Pass/Fail Criteria

### 12.1 Individual Test

Any of the following is a FAIL:

- Non-zero compile, elaboration, or simulation process exit.
- Any UVM_ERROR or UVM_FATAL.
- Any assertion failure.
- Shell timeout, simulation watchdog, or bounded protocol timeout.
- Scoreboard mismatch, non-empty expected queue, or unexpected transaction.
- Self-checking sequence mismatch in data, state, or side effects.
- X/Z on an output required to be known.

PASS requires all conditions above to remain clear and every test-defined checker to complete. Waveforms are debug evidence only and do not require manual approval.

### 12.2 Regression

| Level | Test pass rate | Assertions | Coverage |
| --- | ---: | --- | --- |
| Smoke | 100% | Zero failures | Not a gate |
| Base | 100% | Zero failures | Generate and track trend |
| Full | 100% | Zero failures | P0/P1 functional bins and code targets met |

A waiver must record the shortfall, rationale, risk, applicable RTL revision, approver, and expiry condition.

---

## 13. Sign-off Checklist

| ID | Requirement |
| --- | --- |
| SF-01 | Register definitions agree across specification, RTL, RAL, and this plan |
| SF-02 | Every P0/P1 feature maps to a test, checker, and coverage item |
| SF-03 | Full regression passes 100% and every seed is traceable |
| SF-04 | Functional and code coverage meet Section 9 targets |
| SF-05 | No unwaived assertion failure |
| SF-06 | No open P0/P1 bug |
| SF-07 | Every waiver is reviewed and archived |
| SF-08 | Logs, coverage reports, commit ID, and tool versions are archived |

---

## 14. Bug Management

| Severity | Definition | Release requirement |
| --- | --- | --- |
| Critical | DUT unusable, data corruption, or core protocol failure | Must fix |
| Major | P0/P1 functional failure | Must fix |
| Minor | Non-critical corner case with a documented workaround | Fix or formally waive |
| Trivial | Diagnostic or documentation issue with no functional impact | Review and disposition |

Lifecycle: New → Assigned → Fixed → Verified → Closed.

---

## 15. Risks and Limitations

| ID | Risk/limitation | Mitigation |
| --- | --- | --- |
| RK-01 | SPI slave model and DUT use similar CPOL/CPHA abstractions, risking a common-mode error | Add independent edge assertions and directed timing checks |
| RK-02 | Current functional coverage is smaller than the planned model | Complete Section 9.2 before sign-off |
| RK-03 | Current assertions cover only basic APB/SPI invariants | Complete Section 10.2 |
| RK-04 | Scoreboard is not a cycle-accurate golden model | Combine end-to-end checking with independent SVA |
| RK-05 | Gate-level simulation is not performed | Timing remains the responsibility of STA and integration flows |

RAL exists and is used for register frontdoor access. “No RAL” must not be listed as a project limitation.

---

## 16. Deliverables

| Deliverable | Path |
| --- | --- |
| Chinese verification plan | `tb/doc/VERIFICATION_PLAN_V1_CN.md` |
| English verification plan | `tb/doc/VERIFICATION_PLAN_V1_EN.md` |
| UVM environment and tests | `tb/` |
| RAL | `tb/ral/` |
| SVA | `tb/sva/` |
| Coverage model | `tb/env/apb_spi_coverage.sv` |
| Scoreboard | `tb/env/apb_spi_scoreboard.sv` |
| Build and regression | `tb/Makefile`, `tb/run_regression.sh` |
