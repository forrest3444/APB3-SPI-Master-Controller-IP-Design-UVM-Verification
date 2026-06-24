[中文](VERIFICATION_PLAN_V1_CN.md) | **English**

# APB-SPI Master Controller v1 — Verification Plan

**Level:** 标准级 (Standard)
**DUT:** `apb_spi_master_top`
**Document Version:** 1.0
**Status:** Frozen for v1

---

## 1. 文档概述

### 1.1 文档目的

本文档为 `apb_spi_master_top` 定义 v1 验证策略，包括：

- 验证目标和测试理念
- 验证环境架构（UVM agent、scoreboard、coverage model）
- 功能覆盖率点和收敛标准
- 定向和受约束随机测试用例列表
- 回归和签核要求

### 1.2 适用范围

| 范围 | 描述 |
| ---- | ---- |
| DUT | `apb_spi_master_top` |
| 验证层级 | Block-level |
| 验证类型 | 功能验证（定向 + 受约束随机） |
| 验证语言 | SystemVerilog / UVM |
| 主要方法学 | 覆盖率驱动验证（CDV） |

**范围内：**

- 所有 12 个寄存器的复位值、读写语义
- APB3 always-ready 协议合规
- SPI master 四模式（CPOL/CPHA）功能正确性
- 8-bit 帧收发、MSB-first
- TX/RX FIFO 缓冲行为及边界条件
- 5 个中断源的 raw/status/enable/clear 行为
- 连续传输模式（cont）
- 可编程时钟分频器
- 软复位恢复
- 错误条件处理（TX underflow、RX overflow）

**范围外：**

- 门级时序仿真
- 形式验证
- 功耗估算
- DFT 验证
- DMA、多 CS、可变帧长、LSB-first、dual/quad SPI（v1 未实现）

### 1.3 参考文档

| 编号 | 文档 | 说明 |
| ---- | ---- | ---- |
| [R1] | `rtl/doc/apb_spi_master_controller_v1_spec_en.md` | v1 设计规格书（Frozen） |
| [R2] | `tb/doc/test_matrix.md` | 测试矩阵 |
| [R3] | `rtl/apb_spi_pkg.sv` | 寄存器地址、位索引、常量、FSM 枚举定义 |

---

## 2. DUT 概述

### 2.1 DUT 功能简介

`apb_spi_master_top` 是一个 AMBA APB3 外设式 SPI Master 控制器 IP。上游通过 APB3 slave 接口接收配置和读写数据，下游通过 SPI master 串行接口驱动外部 SPI slave 设备。

**主要功能：**

- APB3 slave 寄存器访问（always-ready 语义）
- SPI master 模式，单 CS 输出
- 全部四种 CPOL/CPHA 模式
- 可编程 SCLK 分频器
- 固定 8-bit 帧收发，MSB-first
- TX FIFO + RX FIFO 数据缓冲
- 自动 CS 控制
- 5 源中断管理（事件型 sticky + 电平型直通）
- 连续传输模式
- 软复位

### 2.2 DUT 结构框图

```text
+-------------------------------------------------------------+
|                    apb_spi_master_top                        |
|                                                              |
|   +------------------+     +------------------+              |
|   |  apb_reg_block   |     |    spi_ctrl      |              |
|   |  (Control Plane) |<--->|  (Execution Plane)|             |
|   |                  |     |                  |              |
|   |  Register File   |     |  FSM: IDLE/LOAD  |---+          |
|   |  Address Decode  |     |  /SHIFT/DONE     |   |          |
|   |  Pulse Generate  |     |  SCLK Divider    |   |          |
|   +--------|---------+     |  Edge Pulse Gen  |   |          |
|            |               +--------|---------+   |          |
|            v                        |             |          |
|   +------------------+    +--------|---------+   |          |
|   |    irq_ctrl      |    | TX FIFO  | RX FIFO|   |          |
|   |  (Event Plane)   |    | (Buffer) |(Buffer)|   |          |
|   |                  |    +------------------+   |          |
|   | Sticky Latch     |                           |   SPI bus|
|   | Mask & Clear     |                           |  (sclk,  |
|   | IRQ Generation   |                           |   mosi,  |
|   +--------|---------+                           |   miso,  |
|            |                                     |   cs_n)  |
|            v                                     |          |
|          irq                                     +----------+
|                                                              |
+-------------------------------------------------------------+
          |                                        |
       APB bus                                SPI pins
   (PSEL,PENABLE,                          (spi_sclk,spi_mosi,
    PWRITE,PADDR,                           spi_miso,spi_cs_n)
    PWDATA,PRDATA,
    PREADY,PSLVERR)
```

**数据流：**

1. 软件通过 APB 写 `TXDATA` → `apb_reg_block` → TX FIFO 入队
2. 软件写 `CTRL.start` → `spi_ctrl` 启动传输
3. `spi_ctrl` 从 TX FIFO 取数据 → 移位输出到 MOSI
4. `spi_ctrl` 从 MISO 采样 → RX FIFO 入队
5. 软件通过 APB 读 `RXDATA` → `apb_reg_block` → RX FIFO 出队
6. `spi_ctrl` 产生事件脉冲 → `irq_ctrl` 锁存/屏蔽 → `irq` 输出

### 2.3 DUT 接口列表

| 端口 | 方向 | 位宽 | 描述 |
| ---- | ---- | ---: | ---- |
| **APB Interface** | | | |
| `PCLK` | input | 1 | APB 时钟 |
| `PRESETn` | input | 1 | APB 复位，低有效 |
| `PSEL` | input | 1 | APB 设备选择 |
| `PENABLE` | input | 1 | APB 使能 |
| `PWRITE` | input | 1 | APB 读写选择（1=写） |
| `PADDR` | input | 12 | APB 地址总线 |
| `PWDATA` | input | 32 | APB 写数据 |
| `PRDATA` | output | 32 | APB 读数据 |
| `PREADY` | output | 1 | APB ready，固定为 1 |
| `PSLVERR` | output | 1 | APB 错误，固定为 0 |
| **SPI Interface** | | | |
| `spi_sclk` | output | 1 | SPI 串行时钟 |
| `spi_mosi` | output | 1 | SPI 主发从收 |
| `spi_miso` | input | 1 | SPI 主收从发 |
| `spi_cs_n` | output | 1 | SPI 片选，低有效 |
| **Interrupt** | | | |
| `irq` | output | 1 | 中断输出 |

---

## 3. 验证目标

### 3.1 功能正确性

| 编号 | 目标 | 描述 |
| ---- | ---- | ---- |
| FC-01 | Register / CSR 访问 | 验证全部 12 个寄存器的复位默认值、RW/RO/WO 语义、reserved 位行为、非法地址访问返回 0 |
| FC-02 | SPI 主数据通路 | 验证 TXDATA→MOSI 字节正确、MISO→RXDATA 字节正确；全双工模式下同时收发正确 |
| FC-03 | CPOL/CPHA 四模式 | 验证 Mode 0/1/2/3 下 SCLK 空闲电平、采样沿、移位沿、帧时序均正确 |
| FC-04 | 时钟分频器 | 验证 `CLKDIV` 寄存器控制 SCLK 频率；边界值（0→等效于 1、最大值）；min/典型/随机值 |
| FC-05 | FIFO 缓冲行为 | TX FIFO：写满后写入被忽略、空时读禁止。RX FIFO：读空返回 0、满时溢出事件。level 计数正确 |
| FC-06 | 中断生成与清除 | 验证 5 个中断源（done / tx_empty / rx_not_empty / tx_underflow / rx_overflow）的 raw→status→irq 路径；sticky 位锁存与清除；level 位直通；mask 位控制 |
| FC-07 | 连续传输模式 | 验证 `cont=1` 时 CS 跨帧保持；TX FIFO 排空后 CS 释放。`cont=0` 时一帧一 CS |
| FC-08 | 复位行为 | 冷复位：所有输出安全值、内部状态归零。软复位：传输中复位清空 FIFO/IRQ、允许干净重启 |
| FC-09 | tx_en / rx_en 控制 | `tx_en=0` 时发送 dummy 0x00；`rx_en=0` 时不写 RX FIFO；独立控制正确 |
| FC-10 | 错误处理 | TX underflow 检测（enable + tx_en + FIFO 空时 start）；RX overflow 检测（RX FIFO 满时接收完成） |

### 3.2 协议正确性

| 编号 | 目标 | 描述 |
| ---- | ---- | ---- |
| PC-01 | APB always-ready | PREADY 恒为 1；PSLVERR 恒为 0；setup phase + access phase 两相时序正确 |
| PC-02 | SPI 帧时序 | CS 从帧开始到帧结束的正确窗口；SCLK 仅在 CS 有效期间翻转 |
| PC-03 | SPI 边沿规范 | CPOL/CPHA 决定采样/移位在 leading 或 trailing edge；数据在采样沿前后稳定 |

### 3.3 边界条件

| 编号 | 目标 | 描述 |
| ---- | ---- | ---- |
| BC-01 | CLKDIV=0 边界 | `clkdiv=0` 等效于 `clkdiv=1`，不出现除零或异常行为 |
| BC-02 | CLKDIV 最大 | `clkdiv=2^CLKDIV_W-1` 时 SCLK 频率最低，计数器不溢出 |
| BC-03 | TX FIFO 满/空 | 满时写被忽略、空时读禁止、level 在边界正确 |
| BC-04 | RX FIFO 满/空 | 满时接收触发 overflow 事件；读空返回 0 |
| BC-05 | 计数器回绕 | bit_cnt 在 0-7 之间、clkdiv_cnt 正确回绕 |
| BC-06 | IRQ 清除竞态 | 清除与事件同时到达时的优先级正确（事件优先于清除） |

### 3.4 鲁棒性

| 编号 | 目标 | 描述 |
| ---- | ---- | ---- |
| RB-01 | 连续背靠背传输 | 持续填 TX → start → 轮询 done → 读 RX → 循环，长周期无数据损坏 |
| RB-02 | 随机寄存器压力 | 随机合法配置序列长时间运行；验证 DUT 不挂死、状态一致 |
| RB-03 | 随机时刻复位 | 活跃传输中随机时刻置位软复位；验证干净中断和恢复 |
| RB-04 | 中断压力 | 快速触发/清除多个中断源；验证 sticky 不丢、mask 切换不产生毛刺 |

---

## 4. 验证范围

### 4.1 In Scope

| 编号 | 范围项 | 描述 |
| ---- | ------ | ---- |
| IS-01 | 定向测试 | 针对寄存器访问、SPI 模式、FIFO 边界、中断、连续模式的手写测试 |
| IS-02 | 受约束随机测试 | 分频器随机值、IRQ 掩码组合、CPOL/CPHA 遍历的覆盖率驱动随机 |
| IS-03 | 寄存器验证 | 全部 12 个寄存器的复位值、RW/RO/WO 语义、非法地址读 |
| IS-04 | 协议合规 | APB always-ready 两相时序、SPI CPOL/CPHA 时序 |
| IS-05 | 数据通路正确性 | TXDATA→MOSI、MISO→RXDATA 端到端检查 |
| IS-06 | FIFO 边界 | 满写忽略、空读返回 0、overflow/underflow 事件 |
| IS-07 | 中断检查 | raw/status/enable/clear 四寄存器模型、IRQ 输出 |
| IS-08 | 复位和初始化 | 冷复位默认值、软复位清除和恢复 |
| IS-09 | 错误注入 | TX underflow（start 时 FIFO 空）、RX overflow（FIFO 满时完成接收） |
| IS-10 | 模式切换 | CPOL/CPHA 动态切换、cont 与非 cont 切换、tx_en/rx_en 切换 |
| IS-11 | 功能覆盖率 | 覆盖组覆盖寄存器访问类型、SPI 模式、FIFO 状态、IRQ 源、分频器范围 |
| IS-12 | 断言检查 | APB 协议断言、SPI 时序断言、FSM 合法状态断言 |
| IS-13 | 回归 | 自动化回归套件：smoke / base / full |

### 4.2 Out of Scope

| 编号 | 范围项 | 理由 |
| ---- | ------ | ---- |
| OS-01 | 形式验证 | v1 不计划 |
| OS-02 | 门级仿真 | 仅 RTL 级功能验证 |
| OS-03 | 功耗/DFT | 不在验证范围 |
| OS-04 | UVM RAL 模型 | v1 不建立 RAL，寄存器访问通过 APB agent 直接读写 |
| OS-05 | 重参考模型 | Scoreboard 基于队列比较，不建 cycle-accurate 黄金模型 |
| OS-06 | 深度约束随机压力 | v1 优先可控定向测试 |

---

## 5. 验证策略

### 5.1 验证层级

| 层级 | 范围 | 方法 | 目标 |
| ---- | ---- | ---- | ---- |
| L1 — 模块级 | 单个 DUT 实例，APB + SPI agent 驱动 | 定向 + 受约束随机 | 验证所有寄存器、SPI 模式、FIFO、IRQ 行为。功能覆盖率 100% |
| L2 — 系统闭环 | APB 配置 → SPI 帧 → RX 读回完整闭环 | 端到端定向测试 | 验证端到端数据完整性和中断反馈 |
| L3 — 稳定性 | 随机种子回归 + 覆盖率驱动 | 浸泡 + 随机 | 功能覆盖率收敛；无挂死；代码覆盖率达标 |

**层级退出标准：**

| 层级 | 退出标准 |
| ---- | -------- |
| L1 | 所有 12 个寄存器验证通过；四 SPI 模式通过；FIFO 边界通过；5 个 IRQ 源通过 |
| L2 | smoke_test 通过；mode_sweep / fifo_basic / irq_basic 通过；软复位恢复通过 |
| L3 | 所有 10 测试通过多个种子；功能覆盖率 ≥ 95%；代码覆盖率 Line ≥ 95%、Toggle ≥ 90%、FSM 100% |

### 5.2 验证方法

| 方法 | 描述 | 应用层级 |
| ---- | ---- | -------- |
| 定向测试 | 针对特定场景的手写激励。每个测试有单一明确的通过/失败标准 | L1, L2 |
| 受约束随机测试 | 分频器值、IRQ 掩码组合随机化；覆盖率模型驱动 | L1, L3 |
| 基于断言的验证 (SVA) | APB 协议断言、SPI 时序断言、FSM 合法状态断言 | 所有层级 |
| 功能覆盖率 | 覆盖组跟踪：寄存器类型、SPI 模式、FIFO 状态、IRQ 源、分频器范围 | 所有层级 |
| Scoreboard | 队列式比较：TXDATA 写 ↔ MOSI 帧字节、MISO 字节 ↔ RXDATA 读 | L1, L2 |
| 错误注入 | 强制 TX underflow（FIFO 空时 start）、RX overflow（FIFO 满时完成接收） | L1 |
| 浸泡测试 | 连续多帧传输、随机配置、长时间运行 | L3 |
| 代码覆盖率 | 行、翻转、FSM、分支覆盖率作为基础检查 | 所有层级 |

### 5.3 验证环境文件组织

```text
tb/
├── env/
│   ├── apb_spi_env.sv           # 顶层 UVM environment
│   ├── apb_spi_env_cfg.sv        # Environment 配置对象
│   ├── apb_spi_scoreboard.sv     # Scoreboard（队列式比对）
│   ├── apb_spi_coverage.sv       # 功能覆盖组
│   └── apb_spi_vseq_item.sv      # Virtual sequence item
├── agent/
│   ├── apb_agent/
│   │   ├── apb_agent.sv          # APB master agent
│   │   ├── apb_agent_cfg.sv      # APB agent 配置
│   │   ├── apb_trans.sv          # APB 事务
│   │   ├── apb_driver.sv         # APB 驱动（两相时序）
│   │   ├── apb_monitor.sv        # APB 监测
│   │   ├── apb_sequencer.sv      # APB sequencer
│   │   └── apb_base_seq.sv       # APB 基础 sequence
│   └── spi_agent/
│       ├── spi_agent.sv          # SPI slave agent
│       ├── spi_agent_cfg.sv      # SPI agent 配置
│       ├── spi_frame.sv          # SPI 帧事务
│       ├── spi_driver.sv         # SPI slave 响应器
│       ├── spi_monitor.sv        # SPI 监测（帧级）
│       ├── spi_sequencer.sv      # SPI sequencer
│       └── spi_base_seq.sv       # SPI 基础 sequence
├── seq_lib/
│   ├── apb_spi_base_vseq.sv      # 基础 virtual sequence
│   ├── apb_reg_access_vseq.sv    # 寄存器访问 virtual sequence
│   ├── smoke_vseq.sv             # Smoke virtual sequence
│   ├── mode_sweep_vseq.sv        # 模式遍历 virtual sequence
│   ├── fifo_basic_vseq.sv        # FIFO 基本 virtual sequence
│   ├── irq_basic_vseq.sv         # IRQ 基本 virtual sequence
│   ├── clkdiv_test_vseq.sv       # 分频器测试 virtual sequence
│   ├── cont_mode_vseq.sv         # 连续模式 virtual sequence
│   ├── soft_reset_vseq.sv        # 软复位 virtual sequence
│   └── irq_stress_vseq.sv        # IRQ 压力 virtual sequence
├── tests/
│   ├── apb_spi_base_test.sv      # 基础 test
│   ├── smoke_test.sv             # Smoke 测试
│   ├── apb_reg_access_test.sv    # 寄存器访问测试
│   ├── mode_sweep_test.sv        # 模式遍历测试
│   ├── fifo_basic_test.sv        # FIFO 基本测试
│   ├── fifo_boundary_test.sv     # FIFO 边界测试
│   ├── irq_basic_test.sv         # IRQ 基本测试
│   ├── irq_stress_test.sv        # IRQ 压力测试
│   ├── clkdiv_test.sv            # 分频器测试
│   ├── cont_mode_test.sv         # 连续模式测试
│   └── soft_reset_test.sv        # 软复位测试
├── sva/
│   ├── apb_protocol_sva.sv       # APB 协议断言
│   ├── spi_protocol_sva.sv       # SPI 时序断言
│   └── apb_spi_bind.sv          # Bind 文件
├── tb_top/
│   ├── tb_top.sv                 # 顶层 testbench
│   ├── apb_if.sv                 # APB SystemVerilog interface
│   └── spi_if.sv                 # SPI SystemVerilog interface
├── pkg/
│   └── apb_spi_uvm_pkg.sv        # 统一验证 package
├── Makefile                      # 构建/运行入口
├── filelist.f                    # 文件列表
└── run_regression.sh             # 回归脚本
```

### 5.4 检查机制

| 机制 | 检查内容 | 错误响应 |
| ---- | -------- | -------- |
| Scoreboard | TXDATA 写 → MOSI 帧字节一一对应；MISO 字节 → RXDATA 读一一对应；连续模式帧序正确 | `uvm_error` 附期望值 vs 实际值 |
| Scoreboard | STATUS 寄存器位（busy/tx_empty/rx_empty 等）与当前传输状态一致 | `uvm_error` |
| Scoreboard | IRQ_RAW/STATUS/irq 与触发事件一致 | `uvm_error` |
| 协议断言 (SVA) | APB setup/access 两相时序；PSEL→PENABLE 顺序 | 违规周期 `$error` |
| 协议断言 (SVA) | SPI SCLK 仅在 CS 有效期间翻转；CS 无效时 SCLK 保持 cpol 电平 | `$error` |
| FSM 断言 (SVA) | spi_ctrl 状态在 {IDLE, LOAD, SHIFT, FRAME_DONE} 内 | `$error` |
| 自检查 Sequence | 寄存器复位值在复位后立即读回比对；写入后读回验证 | `uvm_error` |
| 性能 Monitor | busy 持续时间与 clkdiv × 16 周期一致 | 超出阈值时 Warning |

---

## 6. 验证环境说明

### 6.1 验证环境架构

```text
+-----------------------------------------------------------+
|                      UVM Testbench Top                     |
|                                                            |
|   +----------------------------------------------------+  |
|   |                  apb_spi_env                        |  |
|   |                                                     |  |
|   |   +----------------+   +----------------+           |  |
|   |   |  APB Agent     |   |  SPI Agent     |           |  |
|   |   |  (active)      |   |  (passive/     |           |  |
|   |   |                |   |   reactive)    |           |  |
|   |   | Sequencer ---> |   |                |           |  |
|   |   | Driver     --->|   | Driver   --->  |           |  |
|   |   | Monitor    --->|   | Monitor  --->  |           |  |
|   |   +-------|--------+   +-------|--------+           |  |
|   |           |                    |                     |  |
|   |           v                    v                     |  |
|   |   +--------------------------------------------+    |  |
|   |   |              Scoreboard                     |    |  |
|   |   |  APB TXDATA queue  →  SPI MOSI byte queue  |    |  |
|   |   |  SPI MISO byte queue →  APB RXDATA queue   |    |  |
|   |   |  STATUS / IRQ consistency check            |    |  |
|   |   +--------------------------------------------+    |  |
|   |                         |                           |  |
|   |                         v                           |  |
|   |   +--------------------------------------------+    |  |
|   |   |           Coverage Collector               |    |  |
|   |   |  cg_cpol_cpha  cg_fifo_state  cg_irq_type  |    |  |
|   |   |  cg_cont_mode  cg_clkdiv_range             |    |  |
|   |   +--------------------------------------------+    |  |
|   |                                                     |  |
|   |   +--------------------------------------------+    |  |
|   |   |         SVA (bind to DUT + interfaces)     |    |  |
|   |   |  APB protocol  |  SPI timing  |  FSM state |    |  |
|   |   +--------------------------------------------+    |  |
|   +----------------------------------------------------+  |
|                           |                                |
|                           v                                |
|   +----------------------------------------------------+  |
|   |  Virtual Interface: apb_if.sv  |  spi_if.sv         |  |
|   +----------------------------------------------------+  |
|                           |                                |
|                           v                                |
|   +----------------------------------------------------+  |
|   |            DUT: apb_spi_master_top                  |  |
|   +----------------------------------------------------+  |
+-----------------------------------------------------------+
```

**组件概要：**

| 组件 | 类型 | 描述 |
| ---- | ---- | ---- |
| APB Agent | UVM active agent | 驱动 APB 读写事务；监测 APB 事务进行覆盖率采集。遵循两相时序 + always-ready |
| SPI Agent | UVM reactive agent | SPI slave 侧响应器：根据 CPOL/CPHA 接收 MOSI 并驱动 MISO；监测 SPI 帧事务 |
| Scoreboard | 比较器 | 队列式比对：APB 写入队列 ↔ SPI 发送队列、SPI 接收队列 ↔ APB 读出队列；STATUS/IRQ 一致性检查 |
| Coverage | 覆盖组 | 在 monitor 事务和 DUT 状态上采样：CPOL×CPHA、FIFO 状态、IRQ 类型、分频器范围、cont 模式 |
| SVA | bind 断言 | APB 两相协议、SPI SCLK/CS 时序、FSM 合法状态 |

**未使用第三方 VIP。所有 agent 均为自主开发。**

### 6.2 Agent 划分

| Agent | 类型 | 接口 | 功能 |
| ----- | ---- | ---- | ---- |
| `apb_agent` | Active | APB | 通过 sequencer 驱动 APB 寄存器读写；监测 APB 事务进行协议检查和覆盖率采集 |
| `spi_agent` | Passive/Reactive | SPI | SPI slave 响应器（driver）+ SPI 帧监测（monitor）；按帧粒度采集 TX/RX byte |

**Agent 配置：**

| Agent | 含 Sequencer | 含 Driver | 含 Monitor | 含 Coverage |
| ----- | :----------: | :-------: | :--------: | :--------: |
| `apb_agent` | 是 | 是 | 是 | 否（在 env 层采集） |
| `spi_agent` | 是 | 是 | 是 | 否（在 env 层采集） |

### 6.3 Scoreboard

| 属性 | 描述 |
| ---- | ---- |
| 比对粒度 | Per-frame (8-bit SPI 帧) |
| 输入来源 | 期望值：APB monitor (TXDATA 写入队列)；实际值：SPI monitor (MOSI 帧字节) |
| | 期望值：SPI monitor (MISO 响应字节)；实际值：APB monitor (RXDATA 读出) |
| 比对策略 | In-order 队列比较 |
| 不匹配行为 | `uvm_error` 并详细 dump 期望值 vs 实际值 |
| FIFO 状态检查 | TX/RX FIFO level、empty、full 信号与队列深度一致性 |
| IRQ 一致性检查 | IRQ_RAW/IRQ_STATUS/irq 与触发事件和 IRQ_EN 掩码一致性 |

**v1 Scoreboard 设计原则：**
- 基于外部可见行为（APB + SPI monitor 事务）
- 不依赖 DUT 内部层次路径（内部信号仅作 debug 辅助）
- 队列式简单比较，不建立复杂预测模型

---

## 7. Feature List / 验证项

### 7.1 优先级定义

| 优先级 | 含义 | 描述 |
| ------ | ---- | ---- |
| P0 | 必须项 | 关键功能，必须在任何发布前完成验证 |
| P1 | 应做项 | 重要功能，最终发布前必须完成 |
| P2 | 可做项 | 非关键功能，进度允许时验证 |

### 7.2 验证项表

| Feature ID | 功能点描述 | 优先级 | 验证方法 | 覆盖点 | 用例 ID |
| ---------: | ---------- | ------ | -------- | ------ | ------- |
| F-01 | 寄存器复位默认值：CTRL=0x60, STATUS=0x0A, CLKDIV=0x01, 其余为 0 | P0 | 定向：复位后读所有寄存器比对 | `cg_reg_reset` | TC-REG-01 |
| F-02 | 寄存器 RW 语义：CTRL enable/cpha/cpol/cont/rx_en/tx_en 写入回读一致 | P0 | 定向 + 随机写入读回 | `cg_reg_rw` | TC-REG-02, TC-REG-03 |
| F-03 | 寄存器 WO 语义：CTRL start/soft_reset 为脉冲写入；TXDATA 只写；IRQ_CLEAR 只写 | P0 | 定向：写后读对应 RO/STATUS 寄存器验证效果 | `cg_reg_wo` | TC-REG-04 |
| F-04 | 寄存器 RO 语义：STATUS 所有位只读；RXDATA/FIFO_LVL/VERSION/IRQ_RAW/IRQ_STATUS 只读 | P0 | 定向：尝试写 RO 寄存器后读回验证不变 | `cg_reg_ro` | TC-REG-05 |
| F-05 | 非法地址读返回 0；非法地址写无副作用 | P1 | 定向：读写未映射地址 | `cg_reg_illegal` | TC-REG-06 |
| F-06 | SPI Mode 0 (CPOL=0,CPHA=0)：空闲 SCLK=0，采样在 leading edge | P0 | 定向：配置后启动传输，波形验证 | `cg_cpol_cpha` | TC-MOD-01 |
| F-07 | SPI Mode 1 (CPOL=0,CPHA=1)：空闲 SCLK=0，采样在 trailing edge | P0 | 定向 | `cg_cpol_cpha` | TC-MOD-01 |
| F-08 | SPI Mode 2 (CPOL=1,CPHA=0)：空闲 SCLK=1，采样在 leading edge | P0 | 定向 | `cg_cpol_cpha` | TC-MOD-01 |
| F-09 | SPI Mode 3 (CPOL=1,CPHA=1)：空闲 SCLK=1，采样在 trailing edge | P0 | 定向 | `cg_cpol_cpha` | TC-MOD-01 |
| F-10 | 单帧传输：一次 start → 8 bits → CS 释放 → done 事件 | P0 | 定向 | `cg_single_frame` | TC-DP-01 |
| F-11 | 多帧传输：多次 start 连续多帧 | P0 | 定向 | `cg_multi_frame` | TC-DP-02 |
| F-12 | TX FIFO 写入和读取顺序正确（先入先出） | P0 | 定向：写 N 字节 → start N 次 → 验证 MOSI 顺序 | `cg_fifo_order` | TC-FIFO-01 |
| F-13 | TX FIFO 满：写满后额外写入被忽略，full 标志正确 | P1 | 定向 | `cg_fifo_bound` | TC-FIFO-02 |
| F-14 | RX FIFO 满溢出：RX FIFO 满时完成接收触发 evt_rx_overflow | P1 | 定向：不读 RX 连续接收 > DEPTH 帧 | `cg_fifo_overflow` | TC-FIFO-03 |
| F-15 | TX underflow：enable+tx_en+FIFO空时 start 触发 evt_tx_underflow | P1 | 定向 | `cg_tx_underflow` | TC-ERR-01 |
| F-16 | 中断 done：帧完成后 sticky 置位；读 STATUS.done_pending 可见；写 IRQ_CLEAR 清除 | P0 | 定向 | `cg_irq_done` | TC-INT-01 |
| F-17 | 中断 tx_empty：level 型，反映 TX FIFO 空状态；mask 后影响 irq | P0 | 定向 | `cg_irq_tx_empty` | TC-INT-02 |
| F-18 | 中断 rx_not_empty：level 型，反映 RX FIFO 非空；mask 后影响 irq | P0 | 定向 | `cg_irq_rx_not_empty` | TC-INT-02 |
| F-19 | 中断 tx_underflow/rx_overflow：事件型 sticky；清除后不误触发 | P1 | 定向 + 错误注入 | `cg_irq_error` | TC-INT-03 |
| F-20 | IRQ_EN mask：mask=0 时 irq 不输出；mask=1 时 irq = raw & en | P0 | 定向：遍历 mask 组合 | `cg_irq_mask` | TC-INT-04 |
| F-21 | 连续模式 cont=1：CS 跨帧保持；FIFO 排空后 CS 释放 | P1 | 定向 | `cg_cont_mode` | TC-CONT-01 |
| F-22 | 连续模式 cont=0：每帧后 CS 释放，需重新 start | P0 | 定向 | `cg_single_cs` | TC-CONT-02 |
| F-23 | 分频器 CLKDIV：SCLK 周期 = 2 × (clkdiv+1) × PCLK | P0 | 定向：min/典型值/随机验证 | `cg_clkdiv` | TC-CLK-01 |
| F-24 | CLKDIV=0 等效于 CLKDIV=1 | P1 | 定向边界测试 | `cg_clkdiv_bound` | TC-CLK-02 |
| F-25 | tx_en=0 发送 dummy 0x00；rx_en=0 不写 RX FIFO | P1 | 定向 | `cg_tx_rx_en` | TC-MOD-02 |
| F-26 | 软复位：清除 FIFO 内容、IRQ sticky 位、终止活跃传输、返回 IDLE | P0 | 定向：传输中途软复位 | `cg_soft_reset` | TC-RST-01 |
| F-27 | 冷复位：所有输出安全值；CTRL=0x60, STATUS=0x0A, CLKDIV=0x01 | P0 | 定向 | `cg_cold_reset` | TC-RST-02 |
| F-28 | VERSION 寄存器值 = 0x0001_0000 | P1 | 定向读回 | `cg_version` | TC-REG-07 |

---

## 8. 测试用例列表

### 8.1 测试类型说明

| 类型 | 描述 |
| ---- | ---- |
| 定向测试 | 针对特定场景的手写激励。确定性通过/失败 |
| 受约束随机 | 合法约束范围内的随机激励。覆盖率驱动 |
| 错误注入 | 强制将非法条件注入 DUT；验证检测和恢复 |

### 8.2 测试用例表

| 用例 ID | 测试名称 | 目标 Feature | 类型 | 描述 | 通过/失败标准 |
| ------: | -------- | ------------ | ---- | ---- | ------------- |
| TC-REG-01 | `test_reg_reset_defaults` | F-01 | 定向 | 复位后通过 APB 读全部 12 个寄存器；与 SPEC 复位值比对 | **通过：** CTRL=0x60, STATUS=0x0A, CLKDIV=0x01, RXDATA=0, IRQ_EN=0, IRQ_RAW=0, IRQ_STATUS=0, TXFIFO_LVL=0, RXFIFO_LVL=0, VERSION=0x0001_0000。**失败：** 任何字段不匹配 |
| TC-REG-02 | `test_reg_rw_access` | F-02 | 定向 | 向 CTRL 的各 RW 位写入 0→1→0 序列；回读验证。向 CLKDIV 写入特征值 0xA5；回读。向 IRQ_EN 写入 0x1F 后回读 | **通过：** 所有 RW 位写入值回读正确。**失败：** 任何回读不匹配 |
| TC-REG-03 | `test_reg_random_access` | F-02 | 受约束随机 | 随机化合法字段值写入所有 RW 寄存器；每次写入后读回比对 | **通过：** 所有随机序列读写一致。**失败：** 任何不匹配 |
| TC-REG-04 | `test_reg_wo_semantics` | F-03 | 定向 | 写 CTRL.start=1 → 验证 start_pulse 效果（发起一帧传输）；写 CTRL.soft_reset=1 → 验证软复位效果；写 TXDATA → 验证 FIFO 中有数据；写 IRQ_CLEAR → 验证 IRQ 被清除 | **通过：** WO 操作产生预期效果。**失败：** 效果不符合 SPEC |
| TC-REG-05 | `test_reg_ro_semantics` | F-04 | 定向 | 尝试向 STATUS / RXDATA / FIFO_LVL / VERSION / IRQ_RAW / IRQ_STATUS 地址写入数据；读回验证值不变 | **通过：** 所有 RO 寄存器写入无效。**失败：** 任何 RO 寄存器被写入修改 |
| TC-REG-06 | `test_reg_illegal_addr` | F-05 | 定向 | 读写未映射地址（0x30, 0x34, 0xFF）；验证读返回 0；写不影响已映射寄存器 | **通过：** 非法地址读返回 0；已映射寄存器值不变。**失败：** 非法地址返回非零或影响其他寄存器 |
| TC-REG-07 | `test_reg_version` | F-28 | 定向 | 读 VERSION 寄存器 | **通过：** 返回 0x0001_0000。**失败：** 值不匹配 |
| TC-DP-01 | `test_single_frame` | F-10, F-06–09 | 定向 | 配置 CPOL/CPHA=Mode0；写 TXDATA=0xA5；start；等待 done；读 RXDATA；四模式各执行一次 | **通过：** 每个模式下：MOSI 输出 0xA5 的每一位对应正确 SCLK 边沿；CS 帧边界正确；done 事件产生。**失败：** 任何数据位或时序不匹配 |
| TC-DP-02 | `test_multi_frame` | F-11 | 定向 | 连续写 4 字节到 TX FIFO；连续 start 4 次；验证每次 done 和 RX 回读 | **通过：** 4 帧顺序正确；每帧 8 bits 正确。**失败：** 任何帧数据错误或顺序错误 |
| TC-MOD-01 | `test_mode_sweep` | F-06–09 | 定向 | CPOL={0,1} × CPHA={0,1} 共四种模式；每模式配置后执行一帧传输 | **通过：** 每种模式 SCLK 空闲电平、采样沿、移位沿符合 SPI 规范。**失败：** 任何模式时序错误 |
| TC-MOD-02 | `test_tx_rx_en_control` | F-25 | 定向 | tx_en=0,rx_en=1 → 验证 MOSI 输出全 0（dummy）；tx_en=1,rx_en=0 → 验证 RX FIFO 为空（无数据写入） | **通过：** tx_en=0 时 dummy 字节正确；rx_en=0 时 RX FIFO level 保持 0。**失败：** 行为不符 |
| TC-CLK-01 | `test_clkdiv_basic` | F-23 | 定向 | CLKDIV=1（2周期 per toggle）→ 验证 SCLK 周期 = 4×PCLK。CLKDIV=3 → 验证 SCLK 周期 = 8×PCLK | **通过：** SCLK 周期 = 2×(clkdiv+1)×T_PCLK。**失败：** 周期不匹配 |
| TC-CLK-02 | `test_clkdiv_boundary` | F-24, F-23 | 受约束随机 | 随机合法 CLKDIV 值（含 0、最大值）；验证 SCLK 周期公式 | **通过：** CLKDIV=0 等效于 1；所有随机值满足周期公式。**失败：** 任何偏差 |
| TC-FIFO-01 | `test_fifo_basic_order` | F-12 | 定向 | 连续写 0x01,0x02,0x03 到 TX FIFO；连续 start 3 次；验证 MOSI 输出顺序与写入一致。SPI slave 响应 0xAA,0xBB,0xCC；读 RXDATA 验证顺序一致 | **通过：** TX 和 RX FIFO 均保持 FIFO 顺序。**失败：** 任何乱序 |
| TC-FIFO-02 | `test_fifo_boundary_full` | F-13 | 定向 | 写 TX FIFO 至满（DEPTH 次写入）；验证 STATUS.tx_full=1；再写一次验证写入被忽略；start 排空后验证 tx_full→0 | **通过：** full 标志在边界正确；溢出写被忽略。**失败：** full 标志错误或溢出写未忽略 |
| TC-FIFO-03 | `test_fifo_overflow` | F-14 | 定向 | 写满 RX FIFO（不读 RXDATA 连续接收 DEPTH+1 次）；验证第 DEPTH+1 帧触发 evt_rx_overflow；IRQ_RAW.rx_overflow 置位 | **通过：** overflow 被正确检测和锁存。**失败：** overflow 未检测或数据被错误覆盖 |
| TC-INT-01 | `test_irq_done` | F-16 | 定向 | 启动一帧传输；等待 done 事件；读 IRQ_RAW.done=1；读 IRQ_STATUS.done（取决于 IRQ_EN）；读 STATUS.done_pending=1；写 IRQ_CLEAR.done=1；验证 irq 和 raw 清除 | **通过：** done 中断完整生命周期正确。**失败：** 任何阶段错误 |
| TC-INT-02 | `test_irq_level_type` | F-17, F-18 | 定向 | TX FIFO 空：验证 IRQ_RAW.tx_empty=1（实时）。写字节后验证变为 0。RX FIFO 非空：接收一帧后验证 IRQ_RAW.rx_not_empty=1；读 RXDATA 后验证变为 0 | **通过：** level 型中断实时反映 FIFO 状态。**失败：** level 不正确或被错误锁存 |
| TC-INT-03 | `test_irq_error_events` | F-19 | 错误注入 | TX underflow：使能+tx_en+FIFO 空时 start → 验证 evt_tx_underflow sticky。RX overflow：写满 RX FIFO 后继续接收 → 验证 evt_rx_overflow sticky。清除后验证不再误触发 | **通过：** 错误事件 sticky 锁存并正确清除。**失败：** 漏检、误清除或重复误触发 |
| TC-INT-04 | `test_irq_mask` | F-20 | 定向 | 设置 IRQ_EN 从 0x00 遍历到 0x1F；在每个 mask 下触发对应中断；验证 irq 输出 = |(IRQ_RAW & IRQ_EN) | **通过：** mask 行为正确。**失败：** 任何 mask 位不符合 |
| TC-INT-05 | `test_irq_stress` | F-16–20 | 受约束随机 | 随机 IRQ_EN 配置 + 随机触发多个中断源 + 随机清除；连续迭代 N 次；验证无 sticky 丢失、mask 切换无毛刺、irq 输出始终正确 | **通过：** 所有迭代通过。**失败：** 任何断言失败或数据不一致 |
| TC-CONT-01 | `test_cont_mode_cs_hold` | F-21 | 定向 | cont=1；写 3 字节到 TX FIFO；start；验证 CS 在三帧间保持低电平；FIFO 排空后 CS 释放 | **通过：** cont 模式下 CS 跨帧保持；排空后释放。**失败：** CS 中间意外释放或未释放 |
| TC-CONT-02 | `test_single_transfer_cs` | F-22 | 定向 | cont=0；写 3 字节；start 3 次；验证每帧后 CS 释放并重新拉低 | **通过：** 每帧独立 CS 窗口。**失败：** CS 未按预期释放 |
| TC-RST-01 | `test_soft_reset` | F-26 | 定向 | 启动传输（CS 活跃期间）；写 CTRL.soft_reset=1；验证：CS 释放、busy=0、TX/RX FIFO 清空（level=0, empty=1）、IRQ sticky 清空、状态机返回 IDLE；再启动一帧验证恢复 | **通过：** 软复位完全清除状态；复位后可正常重启。**失败：** 任何残留状态或无法重启 |
| TC-RST-02 | `test_cold_reset` | F-27 | 定向 | 上电后 PRESETn=0→1；验证所有寄存器为复位默认值；验证输出初始安全状态（SCLK=cpol, mosi=0, cs_n=1, irq=0） | **通过：** 所有初始状态符合 SPEC。**失败：** 任何初始状态异常 |
| TC-ERR-01 | `test_tx_underflow` | F-15 | 错误注入 | 配置 enable=1,tx_en=1；FIFO 空时写 CTRL.start=1；验证 evt_tx_underflow 置位；IRQ_RAW.tx_underflow 锁存；STATUS.tx_underflow_pending 可见 | **通过：** underflow 正确检测和上报。**失败：** 未检测到或上报错误 |

---

## 9. 覆盖率计划

### 9.1 功能覆盖率

| Covergroup | 描述 | 采样位置 | 覆盖率点 | 目标 |
| ---------: | ---- | -------- | -------- | ---: |
| `cg_reg_reset` | 寄存器复位默认值 | APB monitor（复位后首次读） | 每个寄存器字段一个 bin | 100% |
| `cg_reg_rw` | 寄存器读写访问 | APB monitor | RW 字段：写入=回读；RO 字段：写入被忽略；WO 字段：产生预期效果 | 100% |
| `cg_reg_addr` | 寄存器地址空间 | APB monitor | 12 个合法地址 + 若干非法地址 bin | 100% |
| `cg_cpol_cpha` | SPI 模式覆盖 | SPI monitor | CPOL × CPHA 四模式交叉；每个至少一次传输 | 100% |
| `cg_fifo_tx_state` | TX FIFO 状态 | Scoreboard / SPI monitor | empty / partial / full 各至少命中一次 | 100% |
| `cg_fifo_rx_state` | RX FIFO 状态 | Scoreboard / APB monitor | empty / partial / full 各至少命中一次 | 100% |
| `cg_irq_type` | IRQ 源类型覆盖 | Scoreboard | 每个 IRQ 源（done / tx_empty / rx_not_empty / tx_underflow / rx_overflow）被触发和清除 | 100% |
| `cg_irq_mask` | IRQ 掩码覆盖 | Scoreboard | irq_en 的每个位独立置位/清零；关键组合（0x00, 0x1F, 各单 bit 使能） | 100% |
| `cg_cont_mode` | 连续模式覆盖 | SPI monitor | cont=0 和 cont=1 各至少一次完整传输 | 100% |
| `cg_clkdiv_range` | 分频器覆盖 | Scoreboard | bin：[0], [1], [2–7], [8–63], [64–255] | 100% |
| `cg_tx_rx_en` | tx_en/rx_en 组合 | SPI monitor | {00, 01, 10, 11} 四种组合各至少一次 | 100% |
| `cg_frame_count` | 帧数覆盖 | SPI monitor | 单帧 / 2–4 帧 / 5+ 帧连续传输 | 100% |
| `cg_soft_reset` | 软复位场景 | Scoreboard | 复位时机：IDLE / LOAD / SHIFT / FRAME_DONE | 100% |
| `cg_error_event` | 错误事件覆盖 | Scoreboard | TX underflow 触发；RX overflow 触发；清除后恢复 | 100% |

### 9.2 交叉覆盖率

| 交叉 Covergroup | 交叉变量 | 描述 | 目标 |
| --------------: | -------- | ---- | ---: |
| `cg_cross_cpol_cpha_x_cont` | `cpol_cpha` × `cont_mode` | 验证四种 SPI 模式在 cont=0 和 cont=1 下均正确 | 100% |
| `cg_cross_cpol_cpha_x_clkdiv` | `cpol_cpha` × `clkdiv_range` | 验证每种 SPI 模式下关键分频器范围正确 | 100% |
| `cg_cross_irq_x_mask` | `irq_source` × `irq_en_bit` | 验证每个中断源在 mask/unmask 下的行为 | 100% |
| `cg_cross_fifo_state_x_reset` | `fifo_state` × `reset_timing` | 验证 FIFO 在各状态下软复位的正确性 | 100% |

### 9.3 代码覆盖率

| 覆盖类型 | 目标 | 描述 |
| -------- | ---: | ---- |
| 行/语句 (Line) | ≥ 95% | 每行可执行代码至少被执行一次 |
| 翻转 (Toggle) | ≥ 90% | 每个单比特信号完成 0→1 和 1→0 翻转 |
| 状态机 (FSM) | 100% | spi_ctrl 四状态全部访问；所有合法转换被覆盖 |
| 分支 (Branch) | ≥ 90% | 每个 if/else 和 case 分支被覆盖 |

---

## 10. 断言计划

### 10.1 严重级别定义

| 级别 | 标签 | 描述 |
| ---- | ---- | ---- |
| S0 | Fatal | 协议违规或数据损坏。必须立即修复 |
| S1 | Error | 功能错误。发布前必须修复 |
| S2 | Warning | 可疑但不一定错误。必须评审 |

### 10.2 断言列表

| 断言 ID | 检查内容 | 级别 | 接口/范围 | 类型 |
| ------: | -------- | ---- | --------- | ---- |
| AS-01 | APB 访问仅在 PSEL=1 时有效 | S0 | APB 接口 | 协议 |
| AS-02 | APB access phase 需要 PSEL && PENABLE 同时为 1 | S0 | APB 接口 | 协议 |
| AS-03 | PREADY 始终为 1（always-ready 语义） | S1 | APB 接口 | 协议 |
| AS-04 | PSLVERR 始终为 0 | S1 | APB 接口 | 协议 |
| AS-05 | SPI SCLK 仅在 CS 有效（cs_active_q=1）时翻转 | S0 | SPI 接口 | 协议 |
| AS-06 | CS 无效时 SCLK 保持 cpol 电平 | S1 | SPI 接口 | 协议 |
| AS-07 | spi_ctrl FSM 状态始终在 {IDLE, LOAD, SHIFT, FRAME_DONE} 内 | S0 | 内部 | 状态不变量 |
| AS-08 | bit_cnt 始终在 [0, 7] 范围内 | S1 | 内部 | 边界 |
| AS-09 | TX FIFO level 不超出 DEPTH | S1 | 内部存储 | 边界 |
| AS-10 | RX FIFO level 不超出 DEPTH | S1 | 内部存储 | 边界 |
| AS-11 | 复位释放后所有控制信号无 X/Z | S1 | 所有接口 | 信号完整性 |
| AS-12 | irq = |(irq_raw & irq_en) 始终成立 | S0 | 中断接口 | 行为 |

---

## 11. 回归测试计划

### 11.1 Smoke 回归

| 属性 | 描述 |
| ---- | ---- |
| 目的 | 每次提交后快速检查基本功能 |
| 触发 | 每次 RTL 或 TB 提交 |
| 测试数量 | 7 个 |
| 最大运行时间 | < 5 分钟 |
| 通过标准 | 100% 测试通过；无 S0/S1 SVA 失败 |
| 失败响应 | 阻止提交 |

**Smoke 测试列表：**

| 用例 ID | 入选理由 |
| ------- | -------- |
| TC-REG-01 | 寄存器复位默认值 — 基础结构检查 |
| TC-REG-02 | 寄存器 RW 访问 — 核心读写 |
| TC-DP-01 | 单帧传输 — 核心 SPI 功能 |
| TC-MOD-01 | 四模式遍历 — SPI 协议 |
| TC-FIFO-01 | FIFO 基本顺序 — 数据通路 |
| TC-INT-01 | IRQ done 生命周期 — 中断通路 |
| TC-RST-02 | 冷复位 — 初始状态 |

### 11.2 Base 回归

| 属性 | 描述 |
| ---- | ---- |
| 目的 | 验证所有 P0 + P1 功能 |
| 触发 | 每日 CI |
| 测试数量 | ~20–22 个（所有定向测试 + 随机种子） |
| 最大运行时间 | < 1 小时 |
| 通过标准 | ≥ 98% 测试通过；所有 P0 测试必须通过；无 S0 SVA 失败 |
| 失败响应 | 当日内分类 |

### 11.3 Full 回归

| 属性 | 描述 |
| ---- | ---- |
| 目的 | 发布前完整验证 |
| 触发 | 每周 + 发布前 |
| 测试数量 | 全部 22+ 测试 × 多个随机种子 |
| 最大运行时间 | < 4 小时 |
| 通过标准 | 100% 测试通过；所有覆盖率目标达成；零 SVA 失败 |
| 失败响应 | 阻止发布 |

---

## 12. Pass/Fail 标准

### 12.1 单测试 Pass/Fail

| Checker | PASS 条件 | FAIL 条件 |
| ------- | --------- | --------- |
| Scoreboard | 队列比较零不匹配；STATUS/IRQ 一致性检查通过 | 任何不匹配标记为 `uvm_error` |
| SVA 断言 | S0/S1 级别零断言失败 | 任何 S0 或 S1 断言触发 |
| 自检查 Sequence | 寄存器读回值与期望值一致 | `uvm_error` |
| 测试超时 | 测试在 `RUN_TIME` 内完成 | 超时被 kill |
| DUT 挂死 | busy 在无活动后超时释放 | busy 持续超过预期 |
| 波形验证 | 对定向测试：至少人工确认关键信号波形与 SPEC 一致 | 波形明显不符 |

### 12.2 回归 Pass/Fail

| 回归层级 | 通过阈值 | P0 测试要求 | 允许的 SVA 级别 |
| -------- | -------: | ----------- | --------------- |
| Smoke | 100% | 全部必须通过 | 不允许 S0/S1 失败 |
| Base | ≥ 98% | 全部必须通过 | 不允许 S0 失败 |
| Full | 100% | 全部必须通过 | 零 SVA 失败 |

---

## 13. 签核

### 13.1 签核检查表

| 编号 | 检查项 | 标准 | 状态 |
| ---- | ------ | ---- | ---- |
| SF-01 | 所有 P0 测试通过 | Full 回归中 100% 通过 | ☐ |
| SF-02 | 所有 P1 测试通过 | Full 回归中 100% 通过 | ☐ |
| SF-03 | 功能覆盖率 | 所有 covergroup 达到目标（P0/P1: 100%） | ☐ |
| SF-04 | 交叉覆盖率达标 | 所有交叉 covergroup 达到 100% | ☐ |
| SF-05 | 代码覆盖率基线 | Line ≥ 95%, Toggle ≥ 90%, FSM 100%, Branch ≥ 90% | ☐ |
| SF-06 | 所有 S0/S1 断言通过 | Full 回归中零 S0/S1 SVA 失败 | ☐ |
| SF-07 | 所有已知 bug 已关闭或豁免 | 无未关闭 P0/P1 bug | ☐ |
| SF-08 | 验证计划已评审 | 计划与实际执行一致 | ☐ |
| SF-09 | 回归日志已归档 | 所有回归日志可追溯 | ☐ |

---

## 14. Bug 管理

### 14.1 Bug 等级定义

| 等级 | 标签 | 描述 | 解决 SLA |
| ---- | ---- | ---- | -------- |
| S0 | Critical | DUT 不可用；基本功能损坏 | 24 小时内 |
| S1 | Major | 关键功能损坏 | 下次 Weekly 回归前 |
| S2 | Minor | 非关键功能；有变通方案 | 发布前；可豁免 |
| S3 | Trivial | 外观或低概率 corner case | 时间允许时 |

### 14.2 Bug 生命周期

New → Assigned → In Progress → Fixed → Verified（关闭）

---

## 15. 风险与限制

### 15.1 已知风险

| 风险 ID | 描述 | 影响 | 严重程度 | 应对措施 |
| ------- | ---- | ---- | -------- | -------- |
| RK-01 | SPI slave 模型过于简单，可能未覆盖所有时序 corner case | 漏检 SPI 时序违规 | Medium | 定向测试覆盖四模式关键时序波形；SVA 补充检查 |
| RK-02 | 无 RAL 模型，寄存器验证依赖 APB 直接读写 | 寄存器访问验证粒度较粗 | Low | 定向测试逐个验证寄存器语义；满足 v1 需求 |
| RK-03 | 验证环境不覆盖门级仿真 | 时序相关问题无法捕获 | Low | v1 仅 RTL 级功能验证；STA 覆盖时序 |

### 15.2 已知限制

| 限制 ID | 描述 | 接受理由 |
| ------- | ---- | -------- |
| LM-01 | 无 UVM RAL | v1 寄存器数量少（12 个），APB agent 直接读写足够 |
| LM-02 | 无重参考模型 | Scoreboard 基于队列式外部行为比较，满足 v1 需求 |
| LM-03 | SPI agent 为最小 slave 模型 | 先建立闭环；后续版本可扩展为完整 VIP |
| LM-04 | 无深度约束随机压力 | v1 优先可控定向测试；覆盖率驱动随机作为补充 |

---

## 16. 交付物

| 交付物 | 描述 | 路径 |
| ------ | ---- | ---- |
| 验证计划 | 本文档 | `tb/doc/VERIFICATION_PLAN_V1_CN.md` |
| 验证环境 | UVM testbench 源代码 | `tb/` 目录 |
| 测试套件 | 全部 22+ 测试用例 | `tb/tests/`, `tb/seq_lib/` |
| 断言套件 | APB + SPI + FSM 断言 | `tb/sva/` |
| Coverage Model | 功能覆盖组 | `tb/env/apb_spi_coverage.sv` |
| Scoreboard | 队列式数据比对 | `tb/env/apb_spi_scoreboard.sv` |
| 回归脚本 | 自动化回归 | `tb/run_regression.sh` |
| 构建入口 | Makefile + filelist | `tb/Makefile`, `tb/filelist.f` |
