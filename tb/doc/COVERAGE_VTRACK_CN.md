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
| VTR-FSM-001 | 代码覆盖率审查 | `spi_ctrl.state_q` FSM transition | `SPI_ST_LOAD -> SPI_ST_IDLE` | 合法 reset 跳转 | 在 APB START 后的单周期 LOAD 窗口内添加定向 cold reset 脉冲 | `cold_reset_test` / `tb/seq_lib/cold_reset_vseq.sv` | Verified | soft reset 通过 APB 无法合法命中 LOAD，因为下一笔 APB 写需要 setup/access 周期。定向场景在 START 后 1ns、下一次 PCLK 上升沿前拉低 `PRESETn`。本地报告 `tb/sim/cold_reset_load_cov_report/mod1.html` 显示 `SPI_ST_LOAD->SPI_ST_IDLE` 已覆盖。 |
| VTR-CODE-001 | 代码覆盖率审查 | `sync_fifo` condition coverage，`tb_top.dut.u_tx_fifo`，line 34 | `r_en=1, !empty=0` on `r_en && !empty` | 防御性 / 合法上游控制不可达 | 添加代码覆盖率 waiver | `tb/cov_waivers/code_coverage_waivers.yml`, `tb/cov_waivers/dve_waivers.el` | Proposed | 该点表示 TX FIFO 空时读请求。`spi_ctrl` 通过 start/continue 条件要求 `!tx_fifo_empty` 后才产生 `tx_fifo_ren`；合法 APB/SPI 操作不应驱动到 FIFO 内部保护路径。关闭条件是人工在 DVE 审查、由 DVE 导出 `.el`，并在原始 merged coverage database 上加载该 `.el`。 |
| VTR-CODE-002 | 代码覆盖率审查 | `sync_fifo` condition coverage，`tb_top.dut.u_rx_fifo`，line 33 | `w_en=1, !full=0` on `w_en && !full` | 防御性 / 合法上游控制不可达 | 添加代码覆盖率 waiver | `tb/cov_waivers/code_coverage_waivers.yml`, `tb/cov_waivers/dve_waivers.el` | Proposed | 该点表示 RX FIFO 满时写请求。`spi_ctrl` 在 `rx_fifo_full` 时上报 overflow 并抑制 `rx_fifo_wen`；合法操作不应驱动到 FIFO 内部保护路径。关闭条件是人工在 DVE 审查、由 DVE 导出 `.el`，并在原始 merged coverage database 上加载该 `.el`。 |
| VTR-CODE-003 | 代码覆盖率审查 | `spi_ctrl` condition coverage，`tb_top.dut.u_spi_ctrl`，line 173，`cfg_cont && cfg_enable && cfg_tx_en && !tx_fifo_empty` | `1011`: `cfg_cont=1, cfg_enable=0, cfg_tx_en=1, !tx_fifo_empty=1` | 规格不支持 / 合法激励不可达 | 添加代码覆盖率 waiver | `tb/cov_waivers/code_coverage_waivers.yml`, `tb/cov_waivers/dve_waivers.el` | Proposed | 该向量要求已进入连续 TX 传输的 `FRAME_DONE` 续帧判断点，但此时观测到 `cfg_enable=0`。按规格，除 `soft_reset` 外，CTRL 配置字段只能在控制器空闲时更新；帧中途关闭 `enable` 不属于架构支持激励。关闭条件是人工在 DVE 审查并在原始 merged coverage database 上加载导出的 `.el`。 |
| VTR-CODE-004 | 代码覆盖率审查 | `spi_ctrl` condition coverage，`tb_top.dut.u_spi_ctrl`，line 173，`cfg_cont && cfg_enable && cfg_tx_en && !tx_fifo_empty` | `1101`: `cfg_cont=1, cfg_enable=1, cfg_tx_en=0, !tx_fifo_empty=1` | 合法 / 可达 | 扩展定向 RX-only dummy 场景，且 TX FIFO 非空 | `tx_rx_en_control_test` / `tb/seq_lib/tx_rx_en_control_vseq.sv` | Implemented | 不应 waiver。测试已先预装 TX FIFO，再配置 `cont=1, enable=1, tx_en=0, rx_en=1` 并发起一次 start。按规格，RX-only dummy 传输即使 `cont=1` 也只执行一帧；TX FIFO 不被消耗，因此 `FRAME_DONE` 可观测到 `!tx_fifo_empty=1`，同时 `cfg_tx_en=0` 使续帧条件为假。待覆盖率复跑后标记 Verified。 |
| VTR-CODE-005 | 代码覆盖率审查 | `spi_ctrl` condition coverage，`tb_top.dut.u_spi_ctrl`，line 110，`cfg_enable && cfg_tx_en && tx_fifo_empty` | `011`: `cfg_enable=0, cfg_tx_en=1, tx_fifo_empty=1` | 合法 / 可达 | 添加定向 disabled 控制器 start 拒绝场景 | `start_rejection_test` / `tb/seq_lib/start_rejection_vseq.sv` | Verified | 控制器 disabled 且 TX FIFO 空；start 写入被忽略，无 CS 活动、无 done/underflow/overflow 事件，TXFIFO_LVL 保持 0。单测覆盖率运行 `BUILD_NAME=start_rejection_011` 确认命中。 |
| VTR-CODE-006 | 代码覆盖率审查 | `spi_ctrl` condition coverage，`tb_top.dut.u_spi_ctrl`，line 193，`cs_active_q \|\| (state_q == SPI_ST_FRAME_DONE)` | `01`: `cs_active_q=0, (state_q==FRAME_DONE)=1` | 不可达 — 结构性 | 添加代码覆盖率 waiver | `tb/cov_waivers/dve_waivers.el` | Waived | `cs_active_q` 和 `state_q` 在 `FRAME_DONE` 同一拍同时更新：`cs_active_q <= 1'b0` 和 `state_q <= SPI_ST_IDLE` 同时发生。不存在 `cs_active_q` 已变为 0 而 `state_q` 仍为 `SPI_ST_FRAME_DONE` 的周期。`01` 向量是编码风格产物，不是功能缺口。 |
| VTR-CODE-005 | 代码覆盖率审查 | `spi_ctrl` condition coverage，`tb_top.dut.u_spi_ctrl`，line 110，`cfg_enable && cfg_tx_en && tx_fifo_empty` | `110`: `cfg_enable=1, cfg_tx_en=1, tx_fifo_empty=0` | 当前分支结构不可达 | 添加代码覆盖率 waiver | `tb/cov_waivers/code_coverage_waivers.yml`, `tb/cov_waivers/dve_waivers.el` | Proposed | 该向量对普通 TX start 是合法组合，但无法到达 line 110 的 underflow `else if` 条件，因为此时 `can_start` 已为真，FSM 会优先进入 `SPI_ST_LOAD`。waiver 仅针对该分支局部 condition vector，不代表该信号组合全局不可达。关闭条件是人工在 DVE 审查并在原始 merged coverage database 上加载导出的 `.el`。 |
