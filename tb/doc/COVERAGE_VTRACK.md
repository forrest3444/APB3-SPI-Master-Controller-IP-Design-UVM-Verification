**English** | [中文](COVERAGE_VTRACK_CN.md)

# Coverage VTrack

This file records coverage holes found during review and the verification action
taken to close or justify them. The RTL specification is the functional source
of truth. Existing verification-plan rules take precedence over this tracker.

## Field Standard

| Field | Meaning |
| --- | --- |
| ID | Stable tracking ID |
| Source | Coverage report item or review source |
| Coverage point | Covergroup / cross / bin family |
| Hole | Missing or suspicious bin |
| Spec status | Legal, ignored, or illegal according to the spec |
| Action | Test, ignore bin, or analysis action |
| Owner test / file | Where the fix is implemented |
| Status | Open, Implemented, Verified, or Waived |
| Notes | Rationale and follow-up |

## Open / Recent Items

| ID | Source | Coverage point | Hole | Spec status | Action | Owner test / file | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| VTR-CFG-001 | Coverage review | `cfg_cg.mode_cross = {mode,cont,txrx}` | `txrx=0` for all modes and cont values | Ignored | Add `ignore_bins no_transfer` | `tb/env/apb_spi_coverage.sv` | Verified | `txrx={tx_en,rx_en}=2'b00` is a no-op start case; mode/cont do not represent an SPI transfer. |
| VTR-CFG-002 | Coverage review | `cfg_cg.mode_cross = {mode,cont,txrx}` | `cont=1, txrx=1` for all modes | Ignored | Add `ignore_bins rx_only_cont` | `tb/env/apb_spi_coverage.sv` | Verified | Receive-only dummy transfer does not auto-continue even when `cont=1`; this is excluded from continuous-mode cross closure. |
| VTR-CFG-003 | Coverage review | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{0,0,1}` | Legal | Add directed RX-only single-frame scenario | `cfg_cross_coverage_test` | Verified | Covers mode 0, cont off, receive-only dummy transfer. |
| VTR-CFG-004 | Coverage review | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{1,0,1}`, `{2,0,1}`, `{3,0,1}` | Legal | Add directed RX-only single-frame scenarios | `cfg_cross_coverage_test` | Verified | Completes legal receive-only, cont-off coverage across modes. |
| VTR-CFG-005 | Coverage review | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{1,0,2}`, `{2,0,2}`, `{3,0,2}` | Legal | Add directed TX-only single-frame scenarios | `cfg_cross_coverage_test` | Verified | Mode 0 TX-only cont-off was already covered by `tx_rx_en_control_test`; this closes modes 1-3. |
| VTR-CFG-006 | Coverage review | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{0,1,2}`, `{1,1,2}`, `{2,1,2}`, `{3,1,2}` | Legal | Add directed TX-only continuous two-frame scenarios | `cfg_cross_coverage_test` | Verified | Continuous mode is meaningful because `tx_en=1`; RX is suppressed. |
| VTR-CFG-007 | Coverage review | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{1,1,3}`, `{2,1,3}`, `{3,1,3}` | Legal | Add directed full-duplex continuous two-frame scenarios | `cfg_cross_coverage_test` | Verified | Mode 0 full-duplex continuous is already covered by `cont_mode_test`; this closes modes 1-3. |
| VTR-CFG-008 | Coverage closure check | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{0,0,2}`, `{0,0,3}`, `{1,0,3}`, `{2,0,3}`, `{3,0,3}`, `{0,1,3}` | Legal | Reuse existing directed scenarios in their owning tests | `tx_rx_en_control_test`, `mode_sweep_test`, `cont_mode_test` | Verified | These points belong to existing enable-control, mode-sweep, and continuous-mode categories. The merged closure report shows `mode_cross` = 20/20 covered with `no_transfer` and `rx_only_cont` excluded. |
