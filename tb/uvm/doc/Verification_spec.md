# APB-SPI Master Controller v1 Verification Freeze Rules

**Status:** Frozen for v1  
**Audience:** Verification developer, future maintainer  
**Purpose:** Define the minimum stable verification strategy before detailed implementation begins.

---

## 1. Verification Role Partitioning

The following role split is frozen for v1:

- **APB agent** = active control-plane driver
- **SPI agent** = active or semi-reactive slave-side responder
- **Scoreboard** = frame-level and register-visible behavior checker
- **Coverage** = sampled from monitor transactions only
- **Test** = selects configuration and scenario only
- **Virtual sequence** = coordinates APB-side actions and SPI-side behavior

### Rules
- Do not move checking logic into tests.
- Do not move scenario logic into scoreboard.
- Do not move protocol sampling into sequences.
- Do not let agents absorb env or test responsibilities.

---

## 2. Frozen Initial Test Set

The first test set is intentionally small and fixed:

- `smoke_test`
- `mode_sweep_test`
- `fifo_basic_test`
- `irq_basic_test`

### Intent
- `smoke_test`: minimum end-to-end bring-up
- `mode_sweep_test`: CPOL/CPHA coverage across all four SPI modes
- `fifo_basic_test`: basic TX/RX FIFO visible behavior
- `irq_basic_test`: raw/status/clear/enable basic interrupt behavior

### Rules
- Do not add many tests before these four are stable.
- Do not start with heavy random regression.
- Do not split one simple feature into many thin tests unless debugging requires it.

---

## 3. Frozen Scoreboard Scope for v1

The first scoreboard implementation shall remain simple and deterministic.

### Required Checks
1. Bytes written through `TXDATA` must match bytes observed on SPI transmit.
2. Bytes returned by the SPI slave side must match bytes later read through `RXDATA`.
3. Continuous mode must preserve frame order.
4. Basic IRQ and STATUS behavior must be consistent with observed APB and SPI activity.

### Design Rules
- Prefer queue-based expected/actual comparison.
- Compare externally visible behavior first.
- Internal DUT hierarchy may assist debug, but must not be the primary correctness source.
- Error messages must be traceable and compact.

### Explicit Non-Goals for v1
- No heavyweight predictor.
- No deep cycle-accurate internal model.
- No attempt to reconstruct hidden implementation state unless needed for debug only.

---

## 4. Frozen Coverage Scope for v1

Coverage for v1 is limited to high-value functional buckets.

### Required Coverage Dimensions
- `CPOL x CPHA`
- `cont` on/off
- `tx_en x rx_en`
- basic TX FIFO states
- basic RX FIFO states
- basic IRQ type hits
- single-frame vs multi-frame activity

### Sampling Rule
- Coverage shall be sampled from monitor transactions whenever possible.
- Do not rely on raw DUT internal signals as the primary coverage source.

### Non-Goals
- No early coverage explosion.
- No large cross coverage without clear value.
- No coverage written only to chase numbers.

---

## 5. Frozen Helper API Strategy

Common operations shall be centralized in base sequences or base virtual sequences.

### Recommended Helper Tasks
- `apb_write_reg(addr, data)`
- `apb_read_reg(addr, data)`
- `push_tx_byte(byte)`
- `pop_rx_byte(byte)`
- `cfg_spi_mode(cpol, cpha)`
- `set_clkdiv(div)`
- `start_transfer()`
- `clear_irq(mask)`

### Rules
- Repeated APB access patterns must not be copy-pasted across tests.
- Scenario code should compose helpers, not reimplement them.
- Helpers should stay protocol-visible and not hide important control flow.

---

## 6. Build and Run Entry Freeze

The verification project has exactly one official build/run entry:

- `Makefile`
- `filelist.f`

### Rules
- Do not create multiple competing compile flows.
- Do not scatter ad hoc scripts as primary entry points.
- Keep output directory naming stable across tests and seeds.

---

## 7. Debug Strategy Freeze

### Primary Debug Sources
- monitor transactions
- scoreboard logs
- waveforms
- assertions

### Allowed Secondary Debug Source
- selective DUT internal hierarchy inspection

### Rules
- DUT internal hierarchy is allowed for debug support.
- DUT internal hierarchy is not the primary verification mechanism.
- No dedicated debug ports are required for v1 verification.

---

## 8. v1 Verification Non-Goals

The following items are explicitly out of scope for early v1:

- RAL model
- heavyweight reference model
- deep constrained-random stress
- performance benchmarking
- over-generalized reusable infrastructure before bring-up is stable

---

## 9. Expected Bring-Up Order

The recommended implementation order is frozen as follows:

1. project skeleton
2. interfaces
3. cfg objects
4. transaction classes
5. APB agent
6. SPI agent
7. env + virtual sequencer
8. scoreboard
9. smoke test
10. mode/fifo/irq basic tests
11. assertions
12. coverage refinement

### Rule
Do not optimize for completeness before basic end-to-end stability exists.

---

## 10. Final Guidance

v1 verification must prioritize:

- structural clarity
- deterministic debugging
- stable ownership boundaries
- visible functional correctness
- low-friction extension later

Any new mechanism added before basic bring-up should be justified by immediate debugging or verification value.
