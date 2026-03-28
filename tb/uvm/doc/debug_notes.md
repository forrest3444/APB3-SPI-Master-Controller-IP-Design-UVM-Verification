# Debug Notes

## Initial Bring-Up Notes
- The initial environment keeps the scoreboard queue-based and register-visible by design.
- SPI slave behavior is intentionally minimal and reactive so the first closed loop is easy to debug.
- Coverage is coarse and tied to monitor/APB-visible activity, matching the frozen v1 guidance.

## Known Gaps
- No RAL model
- No deep constrained-random stress
- IRQ/status checking is basic and aligned to visible v1 behavior only
