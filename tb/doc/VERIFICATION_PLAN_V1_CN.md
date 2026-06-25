**中文** | [English](VERIFICATION_PLAN_V1_EN.md)

# APB-SPI Master Controller v1 — 验证计划

**DUT：** `apb_spi_master_top`

**文档版本：** 1.1

**状态：** v1 评审基线

**验证方法：** SystemVerilog / UVM 1.2

---

## 1. 文档概述

### 1.1 目的

本文档定义 APB-SPI Master Controller v1 的功能验证范围、验证环境、功能点、测试、覆盖率、断言、回归和签核标准。验证预期以 RTL SPEC 为唯一功能基线；当 SPEC、RTL 和测试预期不一致时，必须先解决规格差异，不能通过修改 checker 隐藏问题。

### 1.2 参考文档

| 编号 | 文档 |
| --- | --- |
| R1 | [RTL SPEC — 中文](../../rtl/doc/apb_spi_master_controller_v1_spec_cn.md) |
| R2 | [RTL SPEC — English](../../rtl/doc/apb_spi_master_controller_v1_spec_en.md) |
| R3 | `rtl/apb_spi_pkg.sv` |
| R4 | `tb/ral/apb_spi_reg_block.sv` |

### 1.3 基线优先级

验证预期按以下优先级确定：

1. RTL SPEC 中的冻结功能和软件可见语义。
2. RTL SPEC 引用但未覆盖的 APB3/SPI 通用协议规则。
3. `apb_spi_pkg.sv` 和 RAL 仅用于检查地址、位宽和字段映射是否与 SPEC 一致。
4. 当前 RTL、UVM 环境、测试结果和覆盖率报告仅用于记录实现状态及缺口，不得反向修改验证期望。

发现低优先级资料与高优先级基线冲突时，应登记问题并按 SPEC 编写预期；在冲突关闭前不得将相关功能标记为已签核。

### 1.4 范围

**范围内：**

- 12 个软件可见寄存器及 RW/RO/WO/reserved 语义
- APB3-style 零等待访问和非法地址错误响应
- 四种 SPI CPOL/CPHA 模式、8-bit、MSB-first 收发
- CLKDIV、TX/RX FIFO、单帧和连续传输
- 5 个中断源的 raw/mask/clear/irq 行为
- 冷复位、软件复位和规定的错误场景
- 功能覆盖率、代码覆盖率和 SVA

**范围外：**

- 门级仿真、STA、功耗、DFT 和形式验证
- DMA、多 CS、可变帧长、LSB-first、dual/quad SPI
- SPEC 定义为不支持的传输中动态配置行为

---

## 2. DUT 与规格基线

### 2.1 接口与架构

| 接口 | 关键语义 |
| --- | --- |
| APB | 12-bit 地址、32-bit 数据、`PREADY=1`；非法访问完成周期 `PSLVERR=1` |
| SPI | 单 CS、Mode 0–3、8-bit、MSB-first |
| IRQ | `irq = \|(IRQ_RAW & IRQ_EN)` |

DUT 由 `apb_reg_block`、`spi_ctrl`、两个 `sync_fifo` 和 `irq_ctrl` 组成。验证以 APB/SPI 外部行为为主，内部信号仅用于 SVA、覆盖率和 debug。

### 2.2 必须保持一致的规格语义

- 复位后 `CTRL=0x0000_0060`、`STATUS=0x0000_000A`、`CLKDIV=1`。
- 复位后 `IRQ_RAW=0x0000_0002`，因为 `tx_empty_raw` 是实时电平源；`IRQ_STATUS=0`。
- `TXDATA` 和 `IRQ_CLEAR` 读取返回 0；RO 写和 reserved 写被忽略。
- 未映射或非对齐地址读取返回 0，写入无副作用，并在完成周期返回 `PSLVERR=1`；合法地址访问返回 `PSLVERR=0`。
- 写 RO、读 WO、RXDATA 空读和 TXDATA 满写均属于已定义寄存器语义，不产生 `PSLVERR`。
- `effective_div = (CLKDIV == 0) ? 1 : CLKDIV`，`T_SCLK = 2 × effective_div × T_PCLK`。
- start 仅在 `IDLE` 接受；busy 期间的 start 被忽略。
- enable=1、tx_en=1 且 TX FIFO 空时 start 产生 underflow，不启动帧。
- tx_en=0、rx_en=1 时发送 dummy `0x00`；tx_en=rx_en=0 时 start 被忽略。
- cont=1 且 tx_en=1 时，一次 start 可连续发送 FIFO 中的多帧；FIFO 排空正常结束且不产生 underflow。
- start 与 soft_reset 同次写入时 soft_reset 优先。
- 软件复位中止传输、清空 FIFO 和 sticky IRQ；CLKDIV、IRQ_EN 不变，CTRL RW 位采用同次 CTRL 写入值。
- sticky event 与 IRQ_CLEAR 同周期时 clear 优先；level IRQ 不受 IRQ_CLEAR 影响。

---

## 3. 验证目标

| ID | 目标 | 验收重点 |
| --- | --- | --- |
| OBJ-REG | 寄存器语义 | 复位值、RW/RO/WO、reserved、VERSION、非法地址 |
| OBJ-APB | APB 协议 | setup/access、zero-wait completion、合法/非法响应、背靠背访问 |
| OBJ-SPI | SPI 数据与时序 | 四模式、8-bit、MSB-first、CS/SCLK/MOSI/MISO |
| OBJ-CLK | 分频器 | 0/1 等效、典型值、随机值、最大值 |
| OBJ-FIFO | FIFO | 顺序、level、empty/full、满写忽略、空读、RX overflow |
| OBJ-IRQ | 中断 | sticky/level、mask、clear 优先级、组合 irq |
| OBJ-CONT | 连续模式 | 一次 start、多帧同一 CS 窗口、正常结束 |
| OBJ-RST | 复位 | 冷复位安全值、运行中软复位、配置保留和恢复 |
| OBJ-ROB | 鲁棒性 | start 拒绝条件、underflow/overflow、随机压力、无挂死 |

所有功能错误必须由自检查 sequence、scoreboard 或 assertion 自动检测。人工看波形只用于 debug，不作为 PASS 条件。

---

## 4. 验证架构与实现参考

本节描述计划采用的验证架构，并记录当前仓库中的实现载体。组件存在与否不改变第 2、3、7 节由 SPEC 派生的验证要求。

### 4.1 组件

| 组件 | 作用 |
| --- | --- |
| APB agent | 驱动两相 APB 事务并发布已完成访问 |
| SPI agent | 作为 reactive slave 驱动 MISO，并监测 SPI 帧 |
| Virtual sequencer | 协调 APB 和 SPI sequence |
| RAL model | 描述 12 个寄存器、字段访问类型和 frontdoor 映射 |
| Scoreboard | 比较 TXDATA→MOSI、MISO→RXDATA，并预测 FIFO/IRQ 状态 |
| Coverage collector | 从 APB/SPI monitor 事务采样功能覆盖率 |
| SVA | 检查 APB、SPI 和关键内部不变量 |

### 4.2 检查原则

- 数据检查采用 in-order 队列，测试结束时不得遗留未消费期望事务。
- 状态检查必须使用 SPEC 语义，不能复制 DUT 实现表达式作为唯一参考。
- RAL 用于地址和字段访问；WO/RO 副作用和非法地址使用原始 APB 事务检查。
- coverage 只证明场景被命中，不替代结果 checker。
- 所有超时必须与帧数及 `effective_div` 有界关联。

### 4.3 当前文件组织

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

## 5. 验证方法

| 方法 | 使用范围 |
| --- | --- |
| 定向测试 | 寄存器、模式、边界、复位和明确错误场景 |
| 受约束随机 | CLKDIV、IRQ mask/clear 顺序和长序列压力 |
| Scoreboard | 端到端数据、FIFO 和 IRQ 预测 |
| SVA | 周期级协议及内部不变量 |
| 功能覆盖率 | 追踪功能场景和关键交叉组合 |
| 代码覆盖率 | 发现未激励 RTL；不能单独证明功能正确 |

“错误注入”在本计划中指通过合法软件操作触发 underflow/overflow，不使用 force 修改 DUT 内部状态，因此测试类型统一称为“负向定向”。

---

## 6. 可追溯性规则

每个 Feature 必须至少映射到一个可执行 test 和一个自动 checker。逻辑 TC 可以合并到同一 executable test；文档使用以下关系：

```text
SPEC requirement → Feature ID → Logical TC ID → executable UVM test
                 → checker/assertion → coverage bin
```

标记为 `GAP` 的项目是计划要求但当前尚无完整自动化实现，签核前必须实现或形成正式 waiver。

---

## 7. Feature List

### 7.1 优先级

| 优先级 | 定义 |
| --- | --- |
| P0 | 核心功能；所有回归和发布必须通过 |
| P1 | 重要边界和鲁棒性；发布前必须通过 |
| P2 | 增强压力或诊断能力；允许经评审延期 |

### 7.2 功能项

本表只描述由 SPEC 派生的规范性验证要求，不表达当前实现完成度；实现映射和 GAP 单独列在第 8 节。

| Feature | SPEC 派生要求 | 优先级 | 逻辑 TC |
| --- | --- | ---: | --- |
| F-REG-01 | 12 个寄存器复位可观察值，包括 IRQ_RAW=0x2 | P0 | TC-REG-01 |
| F-REG-02 | CTRL/CLKDIV/IRQ_EN RW 与 reserved 位 | P0 | TC-REG-02/03 |
| F-REG-03 | start/soft_reset/TXDATA/IRQ_CLEAR WO 副作用及读零 | P0 | TC-REG-04 |
| F-REG-04 | STATUS/RXDATA/IRQ/FIFO_LVL/VERSION RO 写忽略 | P0 | TC-REG-05 |
| F-REG-05 | 非法及非对齐地址读零、写无副作用且完成周期 PSLVERR=1 | P0 | TC-REG-06 |
| F-REG-06 | VERSION=0x0001_0000 | P1 | TC-REG-07 |
| F-APB-01 | setup→access、PREADY=1、合法访问 PSLVERR=0、错误响应仅在非法访问完成周期有效 | P0 | TC-APB-01 |
| F-APB-02 | 合法背靠背读写和读写切换 | P1 | TC-APB-02 |
| F-SPI-01 | Mode 0/1/2/3 的采样沿、移位沿和空闲电平 | P0 | TC-SPI-01 |
| F-SPI-02 | 单帧 8-bit、MSB-first、CS 边界和 done | P0 | TC-SPI-02 |
| F-SPI-03 | tx_en/rx_en 四组合及 dummy/no-op 行为 | P1 | TC-SPI-03 |
| F-SPI-04 | start 接受/拒绝、busy start 忽略、命令优先级 | P1 | TC-SPI-04 |
| F-CLK-01 | `2×effective_div×T_PCLK`，覆盖 0/1/典型/随机 | P0 | TC-CLK-01 |
| F-CLK-02 | CLKDIV=0 与 1 等效，最大值可完成 | P1 | TC-CLK-02 |
| F-FIFO-01 | TX/RX FIFO 顺序和 level | P0 | TC-FIFO-01 |
| F-FIFO-02 | TX 满写忽略、empty/full 边界 | P1 | TC-FIFO-02 |
| F-FIFO-03 | RX 满时丢弃新字节并产生 overflow sticky | P1 | TC-FIFO-03 |
| F-CONT-01 | cont=1 一次 start 连续多帧且 CS 保持 | P0 | TC-CONT-01 |
| F-CONT-02 | cont=0 每帧独立 start 和 CS 窗口 | P0 | TC-CONT-02 |
| F-IRQ-01 | done sticky 生命周期 | P0 | TC-IRQ-01 |
| F-IRQ-02 | tx_empty/rx_not_empty level 实时行为 | P0 | TC-IRQ-02 |
| F-IRQ-03 | underflow/overflow sticky 与清除 | P1 | TC-IRQ-03 |
| F-IRQ-04 | IRQ_EN mask 和组合 irq | P0 | TC-IRQ-04 |
| F-IRQ-05 | level clear 无效、event 与 clear 同周期 clear 优先 | P1 | TC-IRQ-05 |
| F-RST-01 | 冷复位寄存器值和 SPI/irq 安全输出 | P0 | TC-RST-01 |
| F-RST-02 | 活跃传输中软件复位及恢复 | P0 | TC-RST-02 |
| F-RST-03 | 软件复位保留 CLKDIV/IRQ_EN 和同次 CTRL 配置 | P1 | TC-RST-03 |

---

## 8. 测试用例与实现映射

### 8.1 当前可执行测试

| Executable test | 覆盖的逻辑 TC | 主要检查 |
| --- | --- | --- |
| `smoke_test` | TC-SPI-02 | 基本 APB→SPI→RX 闭环 |
| `apb_reg_access_test` | TC-REG-01/02/03/04/05/07 | 完整寄存器访问和副作用 |
| `apb_reg_semantics_test` | TC-REG-01/04/05/06/07 | 复位、WO/RO、非法地址数据/副作用、VERSION |
| `pslverr_test` | TC-REG-06, TC-APB-01 | 非法/非对齐地址完成周期 PSLVERR=1；合法地址和合法特殊访问 PSLVERR=0 |
| `apb_back_to_back_test` | TC-APB-02 | 合法 APB 背靠背读写、连续读写和读写方向切换 |
| `mode_sweep_test` | TC-SPI-01/02, TC-CONT-02 | 四种 SPI 模式的单帧传输 |
| `tx_rx_en_control_test` | TC-SPI-03 | tx_en/rx_en 四组合、dummy 发送、RX 抑制和双禁用 no-op |
| `start_rejection_test` | TC-SPI-04 | start 接受、disable/双禁用拒绝、underflow、busy 忽略及 reset 优先级 |
| `clkdiv_test` | TC-CLK-01/02 | 分频公式、0/1/最大值和随机值 |
| `fifo_basic_test` | TC-FIFO-01, TC-CONT-01 | 连续 TX/RX FIFO 顺序 |
| `fifo_boundary_test` | TC-FIFO-02/03, TC-IRQ-03 | FIFO 满边界、overflow、underflow |
| `cont_mode_test` | TC-CONT-01 | 多帧同一 CS 窗口及结束释放 |
| `irq_basic_test` | TC-IRQ-01/04 | underflow、done、mask/clear 基本路径 |
| `irq_stress_test` | TC-IRQ-01/02/03/04 | 多 IRQ 源、mask 切换、clear、软件复位 |
| `irq_clear_priority_test` | TC-IRQ-05 | level clear 无效；sticky event 与 IRQ_CLEAR 同周期时 clear 优先 |
| `soft_reset_test` | TC-RST-02/03 | 活跃传输软件复位和恢复 |
| `cold_reset_test` | TC-RST-01 | 复位期间/释放后的安全输出及全部 12 个寄存器默认值 |

### 8.2 签核前需补充的定向场景

| 场景 | 期望结果 |
| --- | --- |
| 非对齐地址 `0x01/0x03/0x31` | 读 0、写无副作用、完成周期 PSLVERR=1 |
| 合法特殊访问：写 RO、读 WO、RX 空读、TX 满写 | 执行已定义语义且 PSLVERR=0 |
| event 与 IRQ_CLEAR 同周期 | sticky 位保持清零 |
| cont=0 多帧 | 每次等待 IDLE 后 start，每帧独立 CS 窗口 |

随机测试必须记录 seed；失败必须可用单一 seed 重放。

### 8.3 APB 错误响应状态

- `apb_reg_block` 按 SPEC 对非法/非对齐访问在完成周期返回 `PSLVERR=1`，合法地址返回 `PSLVERR=0`。
- APB driver、monitor、transaction 和 RAL adapter 已能传递 `slverr`。
- `apb_protocol_sva` 检查合法地址无错误、非法地址有错误，以及 `PSLVERR` 只在非法访问完成周期有效。
- `pslverr_test` 覆盖非法 aligned/unaligned 地址、合法特殊访问以及非法写无副作用。

F-REG-05 和 F-APB-01 的基本定向检查由 `pslverr_test` 关闭。

---

## 9. 覆盖率计划

### 9.1 当前功能覆盖率实现

| Covergroup | 当前覆盖内容 | 限制 |
| --- | --- | --- |
| `cfg_cg` | mode、cont、tx/rx enable 及其交叉；CLKDIV 粗分档 | CLKDIV=0 未独立；交叉需增加 ignore_bins |
| `fifo_cg` | TX/RX empty、partial、full | 由 STATUS 读触发，不能证明每次边界转换正确 |
| `irq_cg` | 5 类 IRQ 源出现 | 尚未覆盖 mask/clear/优先级生命周期 |
| `frame_cg` | single/multi frame | 需明确连续窗口帧数 bins |

### 9.2 必须补充的覆盖点

- 12 个合法地址、非法对齐地址、非对齐地址。
- 合法/非法 × read/write × PSLVERR 响应；PSLVERR 仅在完成周期有效。
- RW/RO/WO/reserved 访问类型及结果检查完成事件。
- CLKDIV bins：0、1、2–7、8–63、64–254、255。
- start 结果：accepted、disabled、underflow、both-disabled、busy-ignored、reset-priority。
- TX/RX FIFO 的 empty↔partial↔full 转换。
- 每个 IRQ source 的 assert、masked、unmasked、clear 和 level-clear-no-effect。
- soft reset 时机：IDLE、SHIFT、FRAME_DONE；FIFO empty/partial/full。
- CPOL/CPHA × cont，以及 CPOL/CPHA × CLKDIV 关键档位。

交叉覆盖率只保留有意义且可达的组合；对无意义或规格禁止的组合使用 `ignore_bins`。功能覆盖率目标为所有 P0/P1 有效 bins 100%，但必须同时满足对应 checker 通过。

### 9.3 代码覆盖率

| 类型 | 目标 |
| --- | ---: |
| Line | ≥95% |
| Branch | ≥90% |
| Toggle | ≥90% |
| FSM state/合法 transition | 100% |

常量、不可达防御分支和工具生成逻辑可以 waiver，但必须记录理由、RTL 版本和审批人。

---

## 10. 断言计划

### 10.1 当前已实现

| Assertion | 检查 |
| --- | --- |
| APB setup→access | setup 后下一周期进入 access |
| APB always-ready | access 时 PREADY=1 |
| APB legal no-error | 合法地址完成周期 PSLVERR=0 |
| APB illegal error | 非法/非对齐地址完成周期 PSLVERR=1，且 PSLVERR 不在其他周期置位 |
| CS/status 一致 | `status_cs_active == !spi_cs_n` |
| busy/CS 一致 | busy 时 CS active |
| idle SCLK | CS 无效时 SCLK=CPOL |

### 10.2 签核前需补充

| ID | 检查 | 优先级 |
| --- | --- | ---: |
| AS-APB-01 | `PENABLE -> PSEL` | P0 |
| AS-APB-02 | setup 到 access 期间 PADDR/PWRITE/PWDATA 稳定 | P0 |
| AS-APB-03 | 合法访问完成时 PSLVERR=0 | P0 |
| AS-APB-04 | 非法/非对齐访问完成时 PSLVERR=1，其他周期为 0 | P0 |
| AS-SPI-01 | SCLK 只在 CS 有效时翻转 | P0 |
| AS-SPI-02 | 每帧恰好 8 个 sample edge | P0 |
| AS-SPI-03 | MOSI 在 sample edge 稳定，仅在帧首预装或 shift edge 更新 | P0 |
| AS-SPI-04 | SHIFT 期间 SCLK 半周期符合 effective_div | P0 |
| AS-FIFO-01 | FIFO level 始终在 0..DEPTH | P0 |
| AS-FIFO-02 | full 时不接受写、empty 时不接受读 | P1 |
| AS-IRQ-01 | `irq == \|(irq_raw & irq_en)` | P0 |
| AS-IRQ-02 | sticky set/clear 优先级符合 SPEC | P1 |
| AS-RST-01 | soft reset 后限定周期内 CS/busy/FIFO/sticky 清除 | P0 |
| AS-X-01 | 复位释放后所有外部输出无 X/Z | P0 |

当前 SVA 未实现独立 S0/S1 严重度编码，因此回归对任何 assertion failure 都按 FAIL 处理。

---

## 11. 回归计划

### 11.1 Smoke

每次 RTL/TB 提交或 PR 执行，目标在 5 分钟内完成：

```text
apb_reg_semantics_test
pslverr_test
apb_back_to_back_test
smoke_test
mode_sweep_test
fifo_basic_test
irq_basic_test
irq_clear_priority_test
soft_reset_test
cold_reset_test
```

要求 100% 通过，零 UVM_ERROR/FATAL，零 assertion failure。

### 11.2 Base

- 每日执行 `tb/tests/` 下除 `apb_spi_base_test` 外的全部 17 个可执行测试。
- 定向测试至少 seed 1；包含随机化的测试至少执行 5 个固定、可重放 seed。
- 必须 100% 通过；不使用“允许 2% 失败”规则。
- 归档失败日志、seed、提交 ID 和仿真器版本。

### 11.3 Full

- 每周和发布前执行全部 Base 测试及补充 GAP 测试。
- 随机测试至少 20 seeds，并合并代码/功能覆盖率。
- 所有测试、assertion 和 P0/P1 覆盖目标均通过。
- 未达目标只能通过正式 waiver，不得通过删除 bins 或降低 checker 严重度规避。

回归脚本应使用显式 smoke/base/full manifest；自动发现所有 `*_test.sv` 只可作为 Base 默认行为。

---

## 12. Pass/Fail 标准

### 12.1 单测试

出现以下任一条件即 FAIL：

- 编译、elaboration 或仿真进程非零退出。
- `UVM_ERROR` 或 `UVM_FATAL` 计数非零。
- 任意 assertion failure。
- shell timeout、仿真 watchdog 或有界协议超时。
- Scoreboard 数据不匹配、期望队列未清空或出现非预期事务。
- 自检查 sequence 读回、状态或副作用不匹配。
- 必检外部信号出现 X/Z。

PASS 必须满足上述条件全部为零，并完成测试定义的所有 checker。波形文件只作为 debug 证据，不作为人工 PASS 门槛。

### 12.2 回归

| 层级 | 测试通过率 | Assertion | 覆盖率 |
| --- | ---: | --- | --- |
| Smoke | 100% | 零失败 | 不作为门槛 |
| Base | 100% | 零失败 | 生成并跟踪趋势 |
| Full | 100% | 零失败 | P0/P1 功能 bins 和代码目标达成 |

Waiver 必须包含未达项、原因、风险、适用 RTL 版本、批准人和失效条件。

---

## 13. 签核清单

| ID | 签核项 |
| --- | --- |
| SF-01 | SPEC、RTL、RAL 和验证计划寄存器定义一致 |
| SF-02 | 所有 P0/P1 Feature 有 test、checker 和 coverage 映射 |
| SF-03 | Full 回归 100% 通过，所有 seed 可追溯 |
| SF-04 | 功能覆盖率和代码覆盖率达到第 9 节目标 |
| SF-05 | 零未豁免 assertion failure |
| SF-06 | 零未关闭 P0/P1 bug |
| SF-07 | 所有 waiver 已评审并归档 |
| SF-08 | 回归日志、覆盖率报告、提交 ID 和工具版本已归档 |

---

## 14. Bug 管理

| 等级 | 定义 | 发布要求 |
| --- | --- | --- |
| Critical | DUT 不可用、数据损坏或核心协议错误 | 必须修复 |
| Major | P0/P1 功能错误 | 必须修复 |
| Minor | 非关键 corner case，有明确规避方法 | 修复或正式 waiver |
| Trivial | 不影响功能的诊断/文档问题 | 经评审处理 |

生命周期：New → Assigned → Fixed → Verified → Closed。

---

## 15. 风险与限制

| ID | 风险/限制 | 应对 |
| --- | --- | --- |
| RK-01 | SPI slave 模型与 DUT 使用相同 CPOL/CPHA 抽象，可能存在共同模式错误 | 增加独立边沿 SVA 和定向时序检查 |
| RK-02 | 当前功能覆盖率模型少于计划目标 | 按第 9.2 节补齐后再签核 |
| RK-03 | 当前断言仅覆盖基础 APB/SPI 不变量 | 按第 10.2 节补齐 |
| RK-04 | Scoreboard 不是 cycle-accurate 黄金模型 | 用端到端检查和独立 SVA互补 |
| RK-05 | 不执行门级仿真 | 时序由 STA 和后续集成流程负责 |

RAL 已存在并用于寄存器 frontdoor 访问；不得再将“无 RAL”列为项目限制。

---

## 16. 交付物

| 交付物 | 路径 |
| --- | --- |
| 中文验证计划 | `tb/doc/VERIFICATION_PLAN_V1_CN.md` |
| English verification plan | `tb/doc/VERIFICATION_PLAN_V1_EN.md` |
| UVM 环境与测试 | `tb/` |
| RAL | `tb/ral/` |
| SVA | `tb/sva/` |
| Coverage model | `tb/env/apb_spi_coverage.sv` |
| Scoreboard | `tb/env/apb_spi_scoreboard.sv` |
| 构建与回归 | `tb/Makefile`, `tb/run_regression.sh` |
