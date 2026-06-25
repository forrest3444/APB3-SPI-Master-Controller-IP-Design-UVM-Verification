[English](COVERAGE_VTRACK.md) | **中文**

# 覆盖率跟踪 (VTrack)

本文档记录覆盖率审查中发现的空洞及关闭或豁免它们所采取的验证措施。RTL 规格书是功能真相源。现有验证计划规则优先于本跟踪文件。

## 字段标准

| 字段 | 含义 |
| --- | --- |
| ID | 稳定的跟踪编号 |
| 来源 | 覆盖率报告项或审查来源 |
| 覆盖率点 | Covergroup / 交叉 / bin 族 |
| 空洞 | 缺失或可疑的 bin |
| 规格状态 | 合法 (Legal)、规格排除 (Ignored)、或非法 (Illegal) |
| 措施 | 测试、ignore bin 或分析操作 |
| 归属文件 | 修复实施的文件 |
| 状态 | Open、Implemented、Verified 或 Waived |
| 备注 | 理由和后续行动 |

## 当前 / 近期记录

| ID | 来源 | 覆盖率点 | 空洞 | 规格状态 | 措施 | 归属文件 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| VTR-CFG-001 | 覆盖率审查 | `cfg_cg.mode_cross = {mode,cont,txrx}` | `txrx=0` 的全部 mode 和 cont 组合 | Ignored | 添加 `ignore_bins no_transfer` | `tb/env/apb_spi_coverage.sv` | Verified | `txrx={tx_en,rx_en}=2'b00` 属于 start 无操作场景；mode/cont 不代表任何 SPI 传输。 |
| VTR-CFG-002 | 覆盖率审查 | `cfg_cg.mode_cross = {mode,cont,txrx}` | `cont=1, txrx=1` 的全部 mode 组合 | Ignored | 添加 `ignore_bins rx_only_cont` | `tb/env/apb_spi_coverage.sv` | Verified | 仅接收的 dummy 传输即使 `cont=1` 也不会自动续帧；这些组合排除在连续模式的交叉收敛之外。 |
| VTR-CFG-003 | 覆盖率审查 | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{0,0,1}` | Legal | 添加定向仅接收单帧场景 | `cfg_cross_coverage_test` | Verified | 覆盖 mode 0、非连续、仅接收 dummy 传输。 |
| VTR-CFG-004 | 覆盖率审查 | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{1,0,1}`, `{2,0,1}`, `{3,0,1}` | Legal | 添加定向仅接收单帧场景 | `cfg_cross_coverage_test` | Verified | 完成各 mode 下合法的仅接收、非连续覆盖。 |
| VTR-CFG-005 | 覆盖率审查 | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{1,0,2}`, `{2,0,2}`, `{3,0,2}` | Legal | 添加定向仅发送单帧场景 | `cfg_cross_coverage_test` | Verified | Mode 0 仅发送非连续已由 `tx_rx_en_control_test` 覆盖；此项关闭 mode 1-3。 |
| VTR-CFG-006 | 覆盖率审查 | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{0,1,2}`, `{1,1,2}`, `{2,1,2}`, `{3,1,2}` | Legal | 添加定向仅发送连续两帧场景 | `cfg_cross_coverage_test` | Verified | 连续模式有意义，因为 `tx_en=1`；RX 被抑制。 |
| VTR-CFG-007 | 覆盖率审查 | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{1,1,3}`, `{2,1,3}`, `{3,1,3}` | Legal | 添加定向全双工连续两帧场景 | `cfg_cross_coverage_test` | Verified | Mode 0 全双工连续已由 `cont_mode_test` 覆盖；此项关闭 mode 1-3。 |
| VTR-CFG-008 | 覆盖率闭合检查 | `cfg_cg.mode_cross = {mode,cont,txrx}` | `{0,0,2}`, `{0,0,3}`, `{1,0,3}`, `{2,0,3}`, `{3,0,3}`, `{0,1,3}` | Legal | 复用各归属测试中现有的定向场景 | `tx_rx_en_control_test`, `mode_sweep_test`, `cont_mode_test` | Verified | 这些点位属于已有的使能控制、模式遍历和连续模式类别。合并闭合报告显示 `mode_cross` = 20/20 覆盖，`no_transfer` 和 `rx_only_cont` 已排除。 |
