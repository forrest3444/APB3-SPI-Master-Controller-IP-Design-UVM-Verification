# APB3 SPI 主控制器

[English](README.md) | **简体中文**

本项目实现了一个 APB3 风格的 SPI 主控制器，包含可综合的 SystemVerilog RTL 和完整的 UVM 验证环境。

## 主要特性

- Always-ready 的 32 位 APB 寄存器接口
- 支持 SPI Mode 0–3、固定 8 位帧和 MSB first
- 可编程时钟分频与自动片选控制
- 独立的 8 深度 TX/RX FIFO
- 支持单帧和连续传输模式
- 支持 raw、masked、level 和 sticky 中断语义
- 支持硬件复位与软件复位
- 提供 UVM Agent、RAL、Scoreboard、功能覆盖率和 SVA

## 目录结构

```text
rtl/          可综合 RTL 与设计规格
tb/           UVM 环境、测试、序列、RAL、覆盖率与断言
tb/doc/       验证计划
doc/          工程文档资源
```

## 快速开始

当前仿真流程基于 Synopsys VCS 和 UVM 1.2。请在仓库根目录执行：

```bash
# 编译并运行冒烟测试
make -C tb sim TESTNAME=smoke_test SEED=1

# 运行回归测试
make -C tb regression BUILD_NAME=regression

# 清理仿真生成文件
make -C tb clean_all
```

常用开关包括 `COV=0`、`FSDB=0`、`ASSERT=0`、`DEBUG=1` 和 `VERB=UVM_HIGH`。

## 文档

- [设计规格 — English](rtl/doc/apb_spi_master_controller_v1_spec_en.md)
- [设计规格 — 中文](rtl/doc/apb_spi_master_controller_v1_spec_cn.md)
- [验证计划 — 中文](tb/doc/VERIFICATION_PLAN_V1_CN.md)

## 许可证

本项目采用 [MIT License](LICENSE)。
