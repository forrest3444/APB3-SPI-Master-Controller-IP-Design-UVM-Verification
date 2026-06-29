# APB3 SPI 主控制器

[English](README.md) | **简体中文**

本项目实现了一个 APB3 风格的 SPI 主控制器，包含可综合的 SystemVerilog RTL 和完整的 UVM 验证环境。

## 主要特性

- Always-ready 的 32 位 APB 寄存器接口，非法访问返回 PSLVERR
- 支持 SPI Mode 0–3、固定 8 位帧和 MSB first
- 可编程时钟分频与自动片选控制
- 独立的 8 深度 TX/RX FIFO
- 支持单帧和连续传输模式
- 支持 raw、masked、level 和 sticky 中断语义
- 支持硬件复位与软件复位
- 提供 UVM Agent、RAL、Scoreboard、功能覆盖率和 SVA

## 验证

18 个定向 + 受约束随机测试覆盖全部 28 个规格派生特性。
两级回归（常规 + 协议负向），默认 ASSERT=1 下 18/18 通过。

| 原始覆盖率 | 豁免后覆盖率 |
|---|---|
| ![raw](tb/doc/fig/cov_raw.png) | ![waived](tb/doc/fig/cov_waivered.png) |

- **功能覆盖率**: 4 个 covergroup（cfg、fifo、irq、frame）— P0/P1 100%
- **代码覆盖率**（仅 DUT）: SCORE 95.53, LINE 99.51, COND 91.87, FSM 100, BRANCH 98.89
- **Waiver 配套**: vtrack、YAML waiver 源文件、DVE `.el` 文件

## 目录结构

```text
rtl/          可综合 RTL 与设计规格
tb/           UVM 环境、测试、序列、RAL、覆盖率与断言
tb/doc/       验证计划、vtrack、waiver 文件、覆盖率截图
```

## 快速开始

当前仿真流程基于 Synopsys VCS 和 UVM 1.2。请在仓库根目录执行：

```bash
# 编译并运行冒烟测试
make -C tb sim TESTNAME=smoke_test SEED=1

# 运行常规回归测试
make -C tb normal_regression

# 运行全量回归测试（常规 + corner）
make -C tb all_regression

# 清理所有仿真生成文件
make -C tb clean_all
```

常用开关包括 `COV=0`、`FSDB=0`、`ASSERT=0`、`DEBUG=1` 和 `VERB=UVM_HIGH`。

## 文档

- [设计规格 — English](rtl/doc/apb_spi_master_controller_v1_spec_en.md)
- [设计规格 — 中文](rtl/doc/apb_spi_master_controller_v1_spec_cn.md)
- [验证计划 — English](tb/doc/VERIFICATION_PLAN_V1_EN.md)
- [验证计划 — 中文](tb/doc/VERIFICATION_PLAN_V1_CN.md)
- [覆盖率跟踪 — English](tb/doc/COVERAGE_VTRACK.md)
- [覆盖率跟踪 — 中文](tb/doc/COVERAGE_VTRACK_CN.md)

## 许可证

本项目采用 [MIT License](LICENSE)。
