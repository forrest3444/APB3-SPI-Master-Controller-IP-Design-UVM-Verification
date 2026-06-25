[English](apb_spi_master_controller_v1_spec_en.md) | **中文**

# APB-SPI Master Controller v1
**面向开发者的顶层设计规格书**
**文档状态：** v1 架构冻结
**目标读者：** RTL 设计者、验证工程师、后续维护者
**范围：** v1 架构、模块划分、寄存器模型、信号契约、实现边界
**范围外：** 详细 RTL 代码、testbench 代码、固件驱动代码

---

## 1. 设计目标与定位

### 1.1 项目定位
本项目实现一个 APB 外设式 SPI Master Controller IP。

上游通过 APB3 slave 接口进行配置和数据访问，下游通过 SPI master 串行接口驱动外部 SPI slave 设备。

v1 的目标不仅仅是构建一个最小可运行 demo，而是交付一个具备以下特征的可集成 IP：

- 结构清晰
- 层级稳定
- 强可验证性
- 显式可扩展性
- 为未来 v2/v3 演进预留架构空间

### 1.2 v1 设计原则
v1 遵循以下原则。

**原则 A：优先构建完整、可闭合的架构**
优先考虑：

- 完整的功能闭环
- 稳定的接口语义
- 清晰的模块边界
- 易于验证和调试

而非一开始就追求功能数量最大化。

**原则 B：控制面与执行面分离**

- APB 寄存器访问、配置存储和状态映射属于**控制面**
- SPI 时序生成、移位和采样属于**执行面**
- 中断 sticky 锁存、屏蔽和清除属于**事件管理面**
- FIFO 仅用作缓冲区，不得携带协议语义

**原则 C：保持业务端口简洁**
正式的 DUT 顶层仅暴露：

- APB 接口
- SPI 接口
- IRQ
- 时钟与复位

不暴露专用调试端口。调试通过层次化引用内部信号实现。

**原则 D：冻结 v1 若干核心约束**
为控制复杂度，v1 显式冻结以下关键约束：

- 单芯片选择
- 固定 8-bit 帧
- 仅 MSB-first
- APB 零等待完成，并对非法访问返回 `PSLVERR`
- 无 DMA
- 无多主
- 无 wait-state 扩展
- 无可变帧长

---

## 2. v1 范围定义

### 2.1 v1 必备功能
v1 必须支持以下功能：

- APB3 slave 寄存器访问
- SPI master 模式
- 单芯片选择输出
- 全部四种 CPOL/CPHA 模式
- 可编程 SCLK 分频器
- 8-bit 帧收发
- TX FIFO
- RX FIFO
- 自动芯片选择控制
- Busy/状态上报
- 原始中断状态 / 使能 / 屏蔽状态 / 清除
- 连续传输模式

### 2.2 v1 显式排除项
以下功能不在 v1 范围内：

- 多芯片选择
- 多主仲裁
- Dual/Quad SPI
- LSB-first
- 可编程帧长
- DMA 请求 / 描述符模式
- APB wait-state / 可变 ready
- 硬件自动突发长度配置
- 超时 / 看门狗
- 高级错误恢复
- 复杂软件握手协议

---

## 3. 顶层架构策略

### 3.1 架构概览
v1 顶层采用四个一级功能子系统：

1. 寄存器与 APB 接口子系统
2. SPI 控制与执行子系统
3. FIFO 数据缓冲子系统
4. 中断与事件管理子系统

四个部分由顶层模块集成。

### 3.2 顶层模块名称
顶层模块名称冻结为：

`apb_spi_master_top`

其职责严格限于：

- 端口定义
- 子模块实例化
- 子模块间信号互联
- 参数向下传播

顶层不得包含复杂的协议行为逻辑。

### 3.3 子系统划分

#### 3.3.1 寄存器与 APB 接口子系统
**模块名称：** `apb_reg_block`

**职责：**

- APB slave 接口访问
- 地址译码
- 控制寄存器存储
- 状态寄存器读出组织
- 数据寄存器访问接口
- 控制脉冲生成
- 中断寄存器访问映射

**不负责：**

- SPI 时序生成
- 中断 sticky 状态存储
- FIFO 存储实现

#### 3.3.2 SPI 控制与执行子系统
**模块名称：** `spi_ctrl`

**职责：**

- SPI master 控制 FSM
- 分频器计数
- SCLK 翻转控制
- Leading/trailing 边沿生成
- MOSI 移位
- MISO 采样
- 自动 CS 控制
- 帧边界处理
- 连续模式调度
- `done` / overflow / underflow 事件生成

**不负责：**

- APB 地址译码
- 中断使能和 sticky 状态管理
- FIFO 内部存储实现

#### 3.3.3 FIFO 子系统
**通用模块名称：** `sync_fifo`

实例化两份：

- `u_tx_fifo`
- `u_rx_fifo`

**职责：**

- 数据缓冲
- `full` / `empty` / `level` 上报

**不负责：**

- SPI 协议语义
- 事务调度
- 中断逻辑

#### 3.3.4 中断与事件管理子系统
**模块名称：** `irq_ctrl`

**职责：**

- 接收事件型和电平型中断源
- 原始状态生成
- Sticky 锁存
- 屏蔽
- 清除
- `irq` 输出生成

**不负责：**

- SPI 时序
- APB 地址访问
- FIFO 存储

---

## 4. 顶层接口规格

### 4.1 APB 接口
v1 使用 APB3 风格接口。

**输入**

- `PCLK`
- `PRESETn`
- `PSEL`
- `PENABLE`
- `PWRITE`
- `PADDR[APB_ADDR_W-1:0]`
- `PWDATA[31:0]`

**输出**

- `PRDATA[31:0]`
- `PREADY`
- `PSLVERR`

**冻结的 v1 语义**

- `PREADY = 1'b1`；所有 APB 传输均无等待周期完成
- `PSLVERR` 仅在非法访问的完成周期置 1
- 除已完成的非法访问外，`PSLVERR = 1'b0`

**说明**

- v1 不实现 wait-state 插入
- 寄存器偏移地址按字对齐。任何不与已定义偏移精确匹配的地址（包括未对齐地址）均为非法地址
- 非法地址读返回 `32'h0000_0000`，非法地址写被忽略；两者均以
  `PSLVERR = 1'b1` 完成
- 已定义地址的访问以 `PSLVERR = 1'b0` 完成，包括写 RO、读 WO、RXDATA
  空读和 TXDATA 满写。这些情况遵循各自寄存器语义，不属于 APB 错误

### 4.2 SPI 接口
**输出**

- `spi_sclk`
- `spi_mosi`
- `spi_cs_n`

**输入**

- `spi_miso`

**冻结的 v1 语义**

- 单芯片选择
- 仅 master 模式
- `spi_cs_n` 低有效
- 空闲 `spi_sclk` 电平由 `cpol` 决定

### 4.3 中断接口
**输出**

- `irq`

`irq` 由 `irq_ctrl` 根据 `irq_raw & irq_en` 生成。

---

## 5. 顶层数据流与控制流

### 5.1 写数据通路
APB 写 `TXDATA`
→ `apb_reg_block` 生成 `tx_fifo_wen / tx_fifo_wdata`
→ `u_tx_fifo` 入队数据
→ `spi_ctrl` 启动帧时出队
→ 加载发送移位寄存器
→ 通过 MOSI 输出

### 5.2 读数据通路
`spi_ctrl` 完成 8-bit 接收
→ 形成 `rx_fifo_wdata`
→ `u_rx_fifo` 入队数据
→ APB 读 `RXDATA`
→ `apb_reg_block` 生成 `rx_fifo_ren`
→ 从 `u_rx_fifo` 弹出一字节

### 5.3 控制通路
APB 写 `CTRL / CLKDIV`
→ `apb_reg_block` 存储配置
→ 输出 `cfg_*` 至 `spi_ctrl`

APB 写 `CTRL.start`
→ `apb_reg_block` 生成 `start_pulse`
→ `spi_ctrl` 根据当前条件决定是否启动帧

APB 写 `CTRL.soft_reset`
→ `apb_reg_block` 生成 `soft_reset_pulse`
→ 作用于 `spi_ctrl`、`irq_ctrl` 和 FIFO 复位路径

### 5.4 中断通路
`spi_ctrl` 生成脉冲型事件：

- `evt_done`
- `evt_tx_underflow`
- `evt_rx_overflow`

FIFO 状态生成电平型事件：

- `level_tx_empty`
- `level_rx_not_empty`

这些信号送入 `irq_ctrl`，生成：

- `irq_raw`
- `irq_status`
- `irq`

---

## 6. v1 软件可见寄存器架构

### 6.1 寄存器设计策略
采用以下设计规则：

- 所有寄存器 32-bit 宽
- 地址按字对齐
- 控制位与状态位分离
- 中断采用四寄存器组：
  - `IRQ_EN`
  - `IRQ_RAW`
  - `IRQ_STATUS`
  - `IRQ_CLEAR`
- 数据寄存器独立：
  - `TXDATA`
  - `RXDATA`
- 写 RO 寄存器和 reserved 位被忽略
- Reserved 位读返回零
- 读 WO 寄存器（`TXDATA` 和 `IRQ_CLEAR`）返回 `32'h0000_0000` 且无副作用

### 6.2 寄存器映射概要

| 偏移 | 名称 | 访问 | 复位值 | 描述 |
|---|---|---|---|---|
| 0x00 | CTRL | RW/WO | 0x0000_0060 | 控制寄存器 |
| 0x04 | STATUS | RO | 0x0000_000A | 状态寄存器 |
| 0x08 | CLKDIV | RW | 0x0000_0001 | 时钟分频寄存器 |
| 0x0C | TXDATA | WO | - | 发送数据入口 |
| 0x10 | RXDATA | RO | 0x0000_0000 | 接收数据出口 |
| 0x14 | IRQ_EN | RW | 0x0000_0000 | 中断使能 |
| 0x18 | IRQ_RAW | RO | 0x0000_0002 | 原始中断状态；含实时电平源 |
| 0x1C | IRQ_STATUS | RO | 0x0000_0000 | 屏蔽后中断状态 |
| 0x20 | IRQ_CLEAR | WO | - | 写 1 清除中断 |
| 0x24 | TXFIFO_LVL | RO | 0x0000_0000 | TX FIFO 水位 |
| 0x28 | RXFIFO_LVL | RO | 0x0000_0000 | RX FIFO 水位 |
| 0x2C | VERSION | RO | 0x0001_0000 | 版本号 |

**复位值说明**

`CTRL` 复位值为 `0x0000_0060`，对应：

- `rx_en = 1`
- `tx_en = 1`
- 其余控制位复位为 0

`STATUS` 复位值为 `0x0000_000A`，对应：

- `tx_empty = 1`
- `rx_empty = 1`

`IRQ_RAW` 复位释放后读数为 `0x0000_0002`，因为 `tx_empty_raw` 是实时电平型源而复位后 TX FIFO 为空。三个存储型 sticky 源（`done_raw`、`tx_underflow_raw` 和 `rx_overflow_raw`）复位为零。`IRQ_STATUS` 和 `irq` 保持为零，因为 `IRQ_EN` 复位为零。

`TXDATA` 和 `IRQ_CLEAR` 不含可读存储，其复位项因此标记为 `-`，其 APB 读值定义为零。

---

## 7. 详细寄存器定义

### 7.1 CTRL 寄存器
**地址：** `0x00`

| 位 | 字段 | 访问 | 复位 | 描述 |
|---|---|---|---|---|
| 0 | enable | RW | 0 | 模块使能 |
| 1 | start | WO 脉冲 | 0 | 启动一次传输 |
| 2 | cpha | RW | 0 | SPI 相位配置 |
| 3 | cpol | RW | 0 | SPI 极性配置 |
| 4 | cont | RW | 0 | 连续传输模式 |
| 5 | rx_en | RW | 1 | 接收使能 |
| 6 | tx_en | RW | 1 | 发送使能 |
| 7 | soft_reset | WO 脉冲 | 0 | 软件复位 |
| 31:8 | reserved | - | 0 | 保留 |

**语义说明**

- 当 `enable = 0` 时，不得启动新事务
- `start` 和 `soft_reset` 是只写命令位。写 1 产生一个 PCLK 周期脉冲；读 CTRL 时这些位始终返回零
- 每次 CTRL 写入同时从同一写数据更新全部六个 RW 字段。软件在发出命令时应保持其期望值
- `start` 仅在 SPI 控制器处于 `IDLE` 时被接受。在 `LOAD`、`SHIFT` 或 `FRAME_DONE` 期间写入的 start 被忽略
- 若 `start` 和 `soft_reset` 在同一次 APB 传输中写入 1，软件复位优先，不启动帧
- `cont = 1` 表示一次 start 后，若 TX FIFO 仍有数据，CS 保持有效且后续帧自动继续
- 除 `soft_reset` 外，软件应在控制器空闲时更新 CTRL 配置字段和 CLKDIV。不支持帧中途更改配置，其 SPI 波形无架构保证

### 7.2 STATUS 寄存器
**地址：** `0x04`

| 位 | 字段 | 访问 | 复位 | 描述 |
|---|---|---|---|---|
| 0 | busy | RO | 0 | 传输正在进行中 |
| 1 | tx_empty | RO | 1 | TX FIFO 为空 |
| 2 | tx_full | RO | 0 | TX FIFO 已满 |
| 3 | rx_empty | RO | 1 | RX FIFO 为空 |
| 4 | rx_full | RO | 0 | RX FIFO 已满 |
| 5 | cs_active | RO | 0 | 芯片选择当前有效 |
| 6 | done_pending | RO | 0 | 完成事件待清除 |
| 7 | tx_underflow_pending | RO | 0 | TX 下溢事件待清除 |
| 8 | rx_overflow_pending | RO | 0 | RX 上溢事件待清除 |
| 31:9 | reserved | - | 0 | 保留 |

**说明**
后三个字段实质上映射自 `irq_ctrl` 内部的 sticky raw 位，便于软件快速观察关键事件状态。

### 7.3 CLKDIV 寄存器
**地址：** `0x08`

| 位 | 字段 | 访问 | 复位 | 描述 |
|---|---|---|---|---|
| 7:0 | div_value | RW | 1 | SPI SCLK 分频值 |
| 31:8 | reserved | - | 0 | 保留 |

**语义**

- 定义 `effective_div = (div_value == 0) ? 1 : div_value`
- 帧移位期间，`spi_sclk` 每 `effective_div` 个 PCLK 周期翻转一次
- 一个完整 SCLK 周期需要两次翻转
- 因此 `T_SCLK = 2 * effective_div * T_PCLK`
- 因此 `div_value = 0` 与 `div_value = 1` 产生相同的 SCLK 速率

### 7.4 TXDATA 寄存器
**地址：** `0x0C`

| 位 | 字段 | 访问 | 描述 |
|---|---|---|---|
| 7:0 | tx_byte | WO | 写入一字节到 TX FIFO |
| 31:8 | reserved | - | 保留 |

**语义**

- 若 TX FIFO 未满，写入成功
- 若 TX FIFO 已满，写入被忽略
- v1 不通过 APB 错误或额外 sticky 错误位上报 TX 写满行为

### 7.5 RXDATA 寄存器
**地址：** `0x10`

| 位 | 字段 | 访问 | 描述 |
|---|---|---|---|
| 7:0 | rx_byte | RO | 从 RX FIFO 读出一字节 |
| 31:8 | reserved | - | 保留 |

**语义**

- 若 RX FIFO 非空，读出并弹出一字节
- 若 RX FIFO 为空，返回 0

### 7.6 IRQ_EN 寄存器
**地址：** `0x14`

| 位 | 字段 | 访问 | 复位 |
|---|---|---|---|
| 0 | done_en | RW | 0 |
| 1 | tx_empty_en | RW | 0 |
| 2 | rx_not_empty_en | RW | 0 |
| 3 | tx_underflow_en | RW | 0 |
| 4 | rx_overflow_en | RW | 0 |
| 31:5 | reserved | - | 0 |

### 7.7 IRQ_RAW 寄存器
**地址：** `0x18`

| 位 | 字段 | 访问 | 复位 |
|---|---|---|---|
| 0 | done_raw | RO | 0 |
| 1 | tx_empty_raw | RO | 1 |
| 2 | rx_not_empty_raw | RO | 0 |
| 3 | tx_underflow_raw | RO | 0 |
| 4 | rx_overflow_raw | RO | 0 |
| 31:5 | reserved | - | 0 |

**语义**

- `done_raw`：sticky 事件型
- `tx_underflow_raw`：sticky 事件型
- `rx_overflow_raw`：sticky 事件型
- `tx_empty_raw`：电平型
- `rx_not_empty_raw`：电平型
- 复位列给出复位释放后观测到的值。电平型字段不含可复位存储，始终反映当前 FIFO 状态

### 7.8 IRQ_STATUS 寄存器
**地址：** `0x1C`

| 位 | 字段 | 访问 |
|---|---|---|
| 4:0 | irq_masked_status | RO |
| 31:5 | reserved | - |

**定义**

`IRQ_STATUS = IRQ_RAW & IRQ_EN`

### 7.9 IRQ_CLEAR 寄存器
**地址：** `0x20`

| 位 | 字段 | 访问 |
|---|---|---|
| 0 | clr_done | WO |
| 1 | clr_tx_empty | WO |
| 2 | clr_rx_not_empty | WO |
| 3 | clr_tx_underflow | WO |
| 4 | clr_rx_overflow | WO |
| 31:5 | reserved | - |

**语义**

- 对 sticky 项，写 1 清除
- 对电平型项，清除无效果
- 若 sticky 事件与其清除位在同一 PCLK 周期到达，清除优先

### 7.10 TXFIFO_LVL / RXFIFO_LVL
**地址：** `0x24`、`0x28`

- `TXFIFO_LVL` 返回当前 TX FIFO 字节数
- `RXFIFO_LVL` 返回当前 RX FIFO 字节数

### 7.11 VERSION 寄存器
**地址：** `0x2C`

| 位 | 字段 | 值 |
|---|---|---|
| 31:16 | major | `16'h0001` |
| 15:0 | minor | `16'h0000` |

---

## 8. SPI 行为规格

### 8.1 基本传输单元
v1 固定为：

`1 事务帧 = 8 bits`

v1 不支持：

- 可变长度帧
- 16-bit 帧
- 32-bit 帧

### 8.2 收发策略
v1 采用全双工 SPI 模型：

- 每发送 1 bit，同时接收 1 bit
- 若 `tx_en = 0`，发送 dummy 值 `8'h00`
- 若 `rx_en = 0`，不将接收数据写入 RX FIFO

### 8.3 启动条件
`spi_ctrl` 仅在以下所有条件满足时方可启动帧：

- `cfg_enable = 1`
- 控制器处于 `IDLE` 且收到 `start_pulse`，或已完成帧符合连续模式继续条件
- 若 `cfg_tx_en = 1`，TX FIFO 须至少含 1 字节
- 若 `cfg_tx_en = 0` 且 `cfg_rx_en = 1`，允许 dummy 传输

启动拒绝行为固定如下：

- 若 `cfg_enable = 0`，start 被忽略且不产生中断事件
- 若 `cfg_tx_en = 1` 且 TX FIFO 为空，start 不启动帧并产生 `evt_tx_underflow`
- 若 `cfg_tx_en = 0` 且 `cfg_rx_en = 1`，start 启动一帧 dummy 传输
- 若 `cfg_tx_en` 和 `cfg_rx_en` 均为 0，start 被忽略且不产生 underflow 事件
- 在 `IDLE` 之外收到的 start 被忽略

### 8.4 连续模式
当 `cont = 0` 时：

- 一次 `start_pulse` 仅执行一帧
- 帧完成后，CS 立即释放，控制器返回空闲

当 `cont = 1` 时：

- 一次 `start_pulse` 可触发连续传输
- 自动继续仅在 `cfg_tx_en = 1` 时适用。只要 TX FIFO 仍含数据，CS 在帧间保持有效
- 全部数据发送完毕后 CS 释放
- 每完成一帧仍然产生一个 `evt_done` 脉冲，且当 RX 使能时尝试一次 RX FIFO 写入
- TX FIFO 变空导致的正常终止不产生 `evt_tx_underflow`
- Dummy 纯接收操作（`tx_en = 0, rx_en = 1`）即使在 `cont = 1` 时每次被接受的 start 也只执行一帧

### 8.5 软件复位行为
写 `CTRL.soft_reset = 1` 具有执行状态复位语义，而非完整寄存器复位。其效果如下：

- 中止活跃帧，使 SPI 控制器返回 `IDLE`
- 释放 CS，驱动 MOSI 为低，SCLK 返回配置的 CPOL 空闲电平
- 清空 TX 和 RX FIFO
- 清除 sticky 的 done、TX-underflow 和 RX-overflow 中断源
- 根据已清空的 FIFO 重新计算电平型中断源

软件复位不会独立将 CTRL RW 字段恢复为冷复位默认值。与每次 CTRL 写入一样，这些字段采用同一 APB 写入中提供的值；软件必须保留期望的配置位。CLKDIV、IRQ_EN 和 VERSION 保持不变。软件复位后 `tx_empty_raw` 为 1，其对 IRQ_STATUS 和 `irq` 的贡献取决于保留的 `IRQ_EN.tx_empty_en` 位。复位命令完成后，STATUS 读数为 `0x0000_000A`，直至新活动改变 FIFO 或控制器状态。

### 8.6 CPOL / CPHA
v1 支持四种标准模式：

- Mode 0：`CPOL=0`、`CPHA=0`
- Mode 1：`CPOL=0`、`CPHA=1`
- Mode 2：`CPOL=1`、`CPHA=0`
- Mode 3：`CPOL=1`、`CPHA=1`

**实现策略**

- `cpol` 决定 `spi_sclk` 的空闲电平
- 内部生成：
  - `leading_edge_pulse`
  - `trailing_edge_pulse`
- `cpha` 决定采样/移位发生在 leading 还是 trailing 边沿

推荐实现显式抽象出：

- `sample_edge_pulse`
- `shift_edge_pulse`

而非在 FSM 分支中分散 CPOL/CPHA 特殊逻辑。

---

## 9. 错误与异常语义

### 9.1 tx_underflow
`tx_underflow` 在控制器处于 `IDLE`、`cfg_enable = 1`、`cfg_tx_en = 1` 且 TX FIFO 为空时收到 APB start 命令时产生。此情况下不启动 SPI 帧。

**说明**

- 在正常受控使用下此事件不应频繁出现
- 保留此事件可提高鲁棒性并为未来扩展留出空间

### 9.2 rx_overflow
当一帧接收完成时：

- 若 `cfg_rx_en = 1`
- 且 `u_rx_fifo.full = 1`

则：

- 当前接收字节被丢弃
- `evt_rx_overflow` 有效
- sticky raw 位锁存于 `irq_ctrl` 内

### 9.3 APB 非法访问
v1 中：

- 非法地址读，包括未对齐地址：返回 `32'h0000_0000`
- 非法地址写：忽略
- 保持 `PREADY = 1'b1`
- 在 APB 完成周期（`PSEL && PENABLE && PREADY`）置位 `PSLVERR`
- 在该完成周期之外清零 `PSLVERR`

---

## 10. 冻结的模块职责

### 10.1 apb_reg_block
**职责**

- APB 访问处理
- 寄存器存储
- `start_pulse` 生成
- `soft_reset_pulse` 生成
- `tx_fifo_wen / wdata` 生成
- `rx_fifo_ren` 生成
- `PRDATA` 组装
- `irq_en / irq_clear` 暴露

**不负责**

- SPI 移位/采样
- 原始中断锁存
- FIFO 内部实现

### 10.2 spi_ctrl
**职责**

- SPI master FSM
- SCLK 分频器
- 边沿脉冲生成
- 自动 CS 控制
- 位计数器 / 移位寄存器
- TX FIFO 数据获取
- RX FIFO 写请求
- 事件输出

**不负责**

- APB 地址处理
- 原始/sticky 中断存储
- FIFO 存储

### 10.3 irq_ctrl
**职责**

- 事件型 raw 锁存
- 电平型 raw 直通
- 屏蔽
- 清除
- `irq` 输出

**不负责**

- SPI 传输控制
- APB 译码
- FIFO 缓冲

### 10.4 sync_fifo
**职责**

- 数据存储
- `full / empty / level`

**不负责**

- 协议解释
- 控制逻辑
- 中断逻辑

---

## 11. 模块端口定义草案

### 11.1 顶层模块 `apb_spi_master_top`
```systemverilog
module apb_spi_master_top #(
    parameter int unsigned APB_ADDR_W    = 12,
    parameter int unsigned TX_FIFO_DEPTH = 8,
    parameter int unsigned RX_FIFO_DEPTH = 8,
    parameter int unsigned CLKDIV_W      = 8
)(
    input  logic                   PCLK,
    input  logic                   PRESETn,

    input  logic                   PSEL,
    input  logic                   PENABLE,
    input  logic                   PWRITE,
    input  logic [APB_ADDR_W-1:0]  PADDR,
    input  logic [31:0]            PWDATA,
    output logic [31:0]            PRDATA,
    output logic                   PREADY,
    output logic                   PSLVERR,

    output logic                   spi_sclk,
    output logic                   spi_mosi,
    input  logic                   spi_miso,
    output logic                   spi_cs_n,

    output logic                   irq
);
```

### 11.2 `apb_reg_block`
```systemverilog
module apb_reg_block #(
    parameter int unsigned APB_ADDR_W = 12,
    parameter int unsigned CLKDIV_W   = 8,
    parameter int unsigned FIFO_LVL_W = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   psel,
    input  logic                   penable,
    input  logic                   pwrite,
    input  logic [APB_ADDR_W-1:0]  paddr,
    input  logic [31:0]            pwdata,
    output logic [31:0]            prdata,
    output logic                   pready,
    output logic                   pslverr,

    output logic                   cfg_enable,
    output logic                   cfg_cpha,
    output logic                   cfg_cpol,
    output logic                   cfg_cont,
    output logic                   cfg_rx_en,
    output logic                   cfg_tx_en,
    output logic [CLKDIV_W-1:0]    cfg_clkdiv,

    output logic                   start_pulse,
    output logic                   soft_reset_pulse,

    output logic                   tx_fifo_wen,
    output logic [7:0]             tx_fifo_wdata,

    output logic                   rx_fifo_ren,
    input  logic [7:0]             rx_fifo_rdata,

    input  logic                   status_busy,
    input  logic                   status_tx_empty,
    input  logic                   status_tx_full,
    input  logic                   status_rx_empty,
    input  logic                   status_rx_full,
    input  logic                   status_cs_active,

    input  logic                   evt_done_pending,
    input  logic                   evt_tx_underflow_pending,
    input  logic                   evt_rx_overflow_pending,

    input  logic [FIFO_LVL_W-1:0]  tx_fifo_level,
    input  logic [FIFO_LVL_W-1:0]  rx_fifo_level,

    output logic [4:0]             irq_en,
    input  logic [4:0]             irq_raw,
    input  logic [4:0]             irq_status,
    output logic [4:0]             irq_clear
);
```

### 11.3 `spi_ctrl`
```systemverilog
module spi_ctrl #(
    parameter int unsigned CLKDIV_W = 8
)(
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 cfg_enable,
    input  logic                 cfg_cpha,
    input  logic                 cfg_cpol,
    input  logic                 cfg_cont,
    input  logic                 cfg_rx_en,
    input  logic                 cfg_tx_en,
    input  logic [CLKDIV_W-1:0]  cfg_clkdiv,

    input  logic                 start_pulse,
    input  logic                 soft_reset_pulse,

    output logic                 tx_fifo_ren,
    input  logic [7:0]           tx_fifo_rdata,
    input  logic                 tx_fifo_empty,

    output logic                 rx_fifo_wen,
    output logic [7:0]           rx_fifo_wdata,
    input  logic                 rx_fifo_full,

    output logic                 spi_sclk,
    output logic                 spi_mosi,
    input  logic                 spi_miso,
    output logic                 spi_cs_n,

    output logic                 status_busy,
    output logic                 status_cs_active,

    output logic                 evt_done,
    output logic                 evt_tx_underflow,
    output logic                 evt_rx_overflow
);
```

### 11.4 `irq_ctrl`
```systemverilog
module irq_ctrl (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        soft_reset_pulse,

    input  logic        evt_done,
    input  logic        evt_tx_underflow,
    input  logic        evt_rx_overflow,

    input  logic        level_tx_empty,
    input  logic        level_rx_not_empty,

    input  logic [4:0]  irq_en,
    input  logic [4:0]  irq_clear,

    output logic [4:0]  irq_raw,
    output logic [4:0]  irq_status,
    output logic        irq
);
```

### 11.5 `sync_fifo`
```systemverilog
module sync_fifo #(
    parameter int unsigned WIDTH = 8,
    parameter int unsigned DEPTH = 8
)(
    input  logic                         clk,
    input  logic                         rst_n,

    input  logic                         w_en,
    input  logic [WIDTH-1:0]             w_data,
    output logic                         full,

    input  logic                         r_en,
    output logic [WIDTH-1:0]             r_data,
    output logic                         empty,

    output logic [$clog2(DEPTH+1)-1:0]   level
);
```

---

## 12. SPI 控制器内部实现建议

### 12.1 推荐主 FSM
`spi_ctrl` 推荐使用以下四个状态：

- `IDLE`
- `LOAD`
- `SHIFT`
- `FRAME_DONE`

**IDLE**

- 等待 `start_pulse`
- 维持空闲 SCLK 电平
- `busy = 0`

**LOAD**

- 必要时拉低 CS
- 从 TX FIFO 加载一字节到发送移位寄存器
- 初始化位计数器 / 分频计数器 / 边沿跟踪

**SHIFT**

- 执行 8-bit 移位和采样操作
- 根据 CPOL/CPHA 使用 `sample_edge_pulse` 和 `shift_edge_pulse`

**FRAME_DONE**

- 若 `cfg_rx_en = 1`，将接收结果写入 RX FIFO
- 产生 `evt_done`
- 根据 `cfg_cont` 和 TX FIFO 状态决定：
  - 返回 `LOAD`
  - 或释放 CS 并返回 `IDLE`

### 12.2 推荐内部关键信号
`spi_ctrl` 内部推荐以下命名规范：

- `state_q`
- `state_d`
- `clkdiv_cnt_q`
- `bit_cnt_q`
- `tx_shift_reg_q`
- `rx_shift_reg_q`
- `sclk_q`
- `cs_active_q`
- `sample_edge_pulse`
- `shift_edge_pulse`

这些信号无需暴露为外部端口。调试时通过层次化引用观察。

---

## 13. Package 与常量组织建议
建议创建：

`apb_spi_pkg.sv`

此 package 应集中定义：

- 寄存器地址偏移
- IRQ 位索引
- 版本常量
- FSM 类型
- 其他共享 `localparam` / `typedef`

**推荐内容概要**

- `localparam CTRL_ADDR = 12'h000;`
- `localparam STATUS_ADDR = 12'h004;`
- `localparam IRQ_DONE_BIT = 0;`
- `localparam IRQ_TX_EMPTY_BIT = 1;`
- `typedef enum logic [1:0] {IDLE, LOAD, SHIFT, FRAME_DONE} spi_state_e;`

这避免了在整个设计中分散魔法数字。

---

## 14. 建议目录结构
```text
apb_spi_master/
├── rtl/
│   ├── top/
│   │   └── apb_spi_master_top.sv
│   ├── reg_if/
│   │   └── apb_reg_block.sv
│   ├── ctrl/
│   │   └── spi_ctrl.sv
│   ├── fifo/
│   │   └── sync_fifo.sv
│   ├── irq/
│   │   └── irq_ctrl.sv
│   ├── pkg/
│   │   └── apb_spi_pkg.sv
│   └── include/
│       └── apb_spi_defs.svh
├── doc/
│   ├── spec_v1.md
│   ├── reg_map_v1.md
│   └── architecture_v1.md
├── tb/
├── sim/
└── tests/
```

---

## 15. 冻结的调试策略

### 15.1 正式策略
v1 正式 DUT 不得暴露专用调试端口。

### 15.2 调试方法
调试依赖：

- 波形
- 一致的内部信号命名
- 对内部状态的层次化引用

例如：

- `dut.u_spi_ctrl.state_q`
- `dut.u_spi_ctrl.bit_cnt_q`
- `dut.u_tx_fifo.level`
- `dut.u_rx_fifo.level`

### 15.3 理由
此方式：

- 保持接口简洁
- 防止调试信号污染业务端口
- 保持架构简单
- 同时提供充分的可调试性

---

## 16. v1 冻结项清单
以下各项在 v1 中冻结，RTL 开发期间不得随意更改：

1. 顶层仅暴露 APB / SPI / IRQ / clk / reset
2. APB 零等待完成，并对非法访问返回错误响应
3. 单芯片选择
4. 仅 8-bit 帧
5. 仅 MSB-first
6. CPOL/CPHA 支持
7. 保留 TX 和 RX FIFO
8. 自动芯片选择
9. 四寄存器中断结构固定
10. `spi_ctrl` 输出瞬时事件；`irq_ctrl` 处理 sticky 状态
11. `apb_reg_block` 仅执行控制/映射，不做 SPI 行为
12. 不通过端口暴露调试

---

## 17. 建议开发顺序
基于本规格书，推荐开发顺序为：

**阶段 1：骨架与共享定义**

- 创建目录结构
- 完成 `apb_spi_pkg.sv`
- 完成顶层和所有子模块的空壳端口

**阶段 2：基本功能模块**

- 完成 `sync_fifo`
- 完成 `irq_ctrl`
- 完成 `apb_reg_block`

**阶段 3：核心执行模块**

- 完成 `spi_ctrl`
- 实现四状态主 FSM
- 实现 CPOL/CPHA 时序行为

**阶段 4：顶层集成**

- 完成 `apb_spi_master_top`
- 连接控制流、数据流和中断流

**阶段 5：验证准备**

- 输出最终寄存器文档
- 创建框图
- 定义验证计划

---

## 18. 最终结论
本 v1 规格书冻结了一套完整的面向开发者的顶层设计方案。

其核心特征为：

- 边界清晰
- 复杂度可控
- 架构分层良好
- 易于 RTL 落地
- 易于 UVM 扩展
- 显式为未来扩展预留空间

本规格书版本可作为后续所有 RTL 和验证工作的统一基准。
