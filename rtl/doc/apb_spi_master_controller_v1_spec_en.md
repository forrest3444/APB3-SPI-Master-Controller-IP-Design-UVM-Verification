**English** | [中文](apb_spi_master_controller_v1_spec_cn.md)

# APB-SPI Master Controller v1  
**Developer-Oriented Top-Level Design Spec**  
**Document Status:** Frozen for v1 Architecture  
**Target Audience:** RTL designer, verification engineer, future maintainer  
**Scope:** v1 architecture, module partitioning, register model, signal contracts, implementation boundaries  
**Out of Scope:** detailed RTL code, testbench code, firmware driver code

---

## 1. Design Goals and Positioning

### 1.1 Project Positioning
This project implements an APB peripheral-style SPI Master Controller IP.

Upstream, the IP provides an APB3 slave interface for configuration and data access. Downstream, it provides an SPI master serial interface for driving external SPI slave devices.

The goal of v1 is not merely to build a minimum runnable demo, but to deliver an integrable IP with the following characteristics:

- Clear structure
- Stable hierarchy
- Strong verifiability
- Explicit extensibility
- Reserved architectural space for future v2/v3 evolution

### 1.2 v1 Design Principles
Version v1 follows the principles below.

**Principle A: Build a complete, closable architecture first**  
Priority is given to:

- Complete functional closure
- Stable interface semantics
- Clear module boundaries
- Ease of verification and debug

rather than maximizing feature count at the beginning.

**Principle B: Separate control plane from execution plane**

- APB register access, configuration storage, and status mapping belong to the **control plane**
- SPI timing generation, shifting, and sampling belong to the **execution plane**
- Interrupt sticky/latch, masking, and clearing belong to the **event management plane**
- FIFOs are used only as buffers and must not carry protocol semantics

**Principle C: Keep the business-facing ports clean**  
The formal DUT top level shall expose only:

- APB interface
- SPI interface
- IRQ
- Clock and reset

No dedicated debug ports shall be exposed. Debug shall be performed by hierarchical reference to internal signals.

**Principle D: Freeze several core constraints in v1**  
To control complexity, v1 explicitly freezes the following key constraints:

- Single chip select
- Fixed 8-bit frame
- MSB-first only
- APB always-ready
- No DMA
- No multi-master
- No wait-state extension
- No variable frame length

---

## 2. v1 Scope Definition

### 2.1 Mandatory v1 Features
v1 must support the following features:

- APB3 slave register access
- SPI master mode
- Single chip-select output
- All four CPOL/CPHA modes
- Programmable SCLK divider
- 8-bit frame transmit/receive
- TX FIFO
- RX FIFO
- Automatic chip-select control
- Busy/status reporting
- Raw interrupt status / enable / masked status / clear
- Continuous transfer mode

### 2.2 Explicitly Excluded from v1
The following features are out of scope for v1:

- Multiple chip selects
- Multi-master arbitration
- Dual/quad SPI
- LSB-first
- Programmable frame length
- DMA request / descriptor mode
- APB wait-state / variable ready
- Hardware automatic burst-length configuration
- Timeout / watchdog
- Advanced error recovery
- Complex software handshake protocols

---

## 3. Top-Level Architecture Strategy

### 3.1 Architecture Overview
The v1 top level adopts four first-class functional subsystems:

1. Register and APB interface subsystem
2. SPI control and execution subsystem
3. FIFO data buffering subsystem
4. Interrupt and event management subsystem

These four parts are integrated by the top-level module.

### 3.2 Top-Level Module Name
The top-level module name is frozen as:

`apb_spi_master_top`

Its responsibilities are strictly limited to:

- Port definitions
- Submodule instantiation
- Signal interconnection between submodules
- Parameter propagation downward

The top level must not contain complex protocol behavior logic.

### 3.3 Subsystem Partitioning

#### 3.3.1 Register and APB Interface Subsystem
**Module name:** `apb_reg_block`

**Responsibilities:**

- APB slave interface access
- Address decode
- Control register storage
- Status register readout organization
- Data register access interface
- Control pulse generation
- Interrupt register access mapping

**Not responsible for:**

- SPI timing generation
- Interrupt sticky-state storage
- FIFO storage implementation

#### 3.3.2 SPI Control and Execution Subsystem
**Module name:** `spi_ctrl`

**Responsibilities:**

- SPI master control FSM
- Divider counting
- SCLK toggle control
- Leading/trailing edge generation
- MOSI shift
- MISO sample
- Automatic CS control
- Frame boundary handling
- Continuous-mode scheduling
- `done` / overflow / underflow event generation

**Not responsible for:**

- APB address decode
- Interrupt enable and sticky-state management
- FIFO internal storage implementation

#### 3.3.3 FIFO Subsystem
**Generic module name:** `sync_fifo`

Instantiated twice as:

- `u_tx_fifo`
- `u_rx_fifo`

**Responsibilities:**

- Data buffering
- `full` / `empty` / `level` reporting

**Not responsible for:**

- SPI protocol semantics
- Transaction scheduling
- Interrupt logic

#### 3.3.4 Interrupt and Event Management Subsystem
**Module name:** `irq_ctrl`

**Responsibilities:**

- Receive event-type and level-type interrupt sources
- Raw status generation
- Sticky latching
- Masking
- Clearing
- `irq` output generation

**Not responsible for:**

- SPI timing
- APB address access
- FIFO storage

---

## 4. Top-Level Interface Specification

### 4.1 APB Interface
v1 uses an APB3-style interface.

**Inputs**

- `PCLK`
- `PRESETn`
- `PSEL`
- `PENABLE`
- `PWRITE`
- `PADDR[APB_ADDR_W-1:0]`
- `PWDATA[31:0]`

**Outputs**

- `PRDATA[31:0]`
- `PREADY`
- `PSLVERR`

**Frozen v1 semantics**

- `PREADY = 1'b1`
- `PSLVERR = 1'b0`

**Notes**

- v1 does not implement wait-state insertion
- v1 does not report errors through the APB error channel
- Register offsets are word-aligned. Any address that does not exactly match a
  defined offset, including an unaligned address, is illegal.
- Illegal address reads return `32'h0000_0000`; illegal writes are ignored

### 4.2 SPI Interface
**Outputs**

- `spi_sclk`
- `spi_mosi`
- `spi_cs_n`

**Input**

- `spi_miso`

**Frozen v1 semantics**

- Single chip select
- Master mode only
- `spi_cs_n` is active low
- Idle `spi_sclk` level is determined by `cpol`

### 4.3 Interrupt Interface
**Output**

- `irq`

`irq` is generated by `irq_ctrl` according to `irq_raw & irq_en`.

---

## 5. Top-Level Data Flow and Control Flow

### 5.1 Write Data Path
APB write to `TXDATA`  
→ `apb_reg_block` generates `tx_fifo_wen / tx_fifo_wdata`  
→ `u_tx_fifo` enqueues data  
→ `spi_ctrl` dequeues when starting a frame  
→ load transmit shift register  
→ output through MOSI

### 5.2 Read Data Path
`spi_ctrl` completes 8-bit reception  
→ forms `rx_fifo_wdata`  
→ `u_rx_fifo` enqueues data  
→ APB reads `RXDATA`  
→ `apb_reg_block` generates `rx_fifo_ren`  
→ one byte is popped from `u_rx_fifo`

### 5.3 Control Path
APB write to `CTRL / CLKDIV`  
→ `apb_reg_block` stores configuration  
→ outputs `cfg_*` to `spi_ctrl`

APB write to `CTRL.start`  
→ `apb_reg_block` generates `start_pulse`  
→ `spi_ctrl` decides whether to start a frame under current conditions

APB write to `CTRL.soft_reset`  
→ `apb_reg_block` generates `soft_reset_pulse`  
→ applied to `spi_ctrl`, `irq_ctrl`, and FIFO reset path

### 5.4 Interrupt Path
`spi_ctrl` generates pulse-style events:

- `evt_done`
- `evt_tx_underflow`
- `evt_rx_overflow`

FIFO status generates level-style events:

- `level_tx_empty`
- `level_rx_not_empty`

These are fed into `irq_ctrl`, which generates:

- `irq_raw`
- `irq_status`
- `irq`

---

## 6. v1 Software-Visible Register Architecture

### 6.1 Register Design Strategy
The following design rules are adopted:

- All registers are 32-bit wide
- Addresses are word-aligned
- Control bits and status bits are separated
- Interrupts use a four-register set:
  - `IRQ_EN`
  - `IRQ_RAW`
  - `IRQ_STATUS`
  - `IRQ_CLEAR`
- Data registers are independent:
  - `TXDATA`
  - `RXDATA`
- Writes to RO registers and reserved bits are ignored
- Reserved bits read as zero
- Reads from WO registers (`TXDATA` and `IRQ_CLEAR`) return
  `32'h0000_0000` and have no side effect

### 6.2 Register Map Summary

| Offset | Name | Access | Reset | Description |
|---|---|---|---|---|
| 0x00 | CTRL | RW/WO | 0x0000_0060 | Control register |
| 0x04 | STATUS | RO | 0x0000_000A | Status register |
| 0x08 | CLKDIV | RW | 0x0000_0001 | Clock divider register |
| 0x0C | TXDATA | WO | - | Transmit data entry |
| 0x10 | RXDATA | RO | 0x0000_0000 | Receive data exit |
| 0x14 | IRQ_EN | RW | 0x0000_0000 | Interrupt enable |
| 0x18 | IRQ_RAW | RO | 0x0000_0002 | Raw interrupt status; includes live level sources |
| 0x1C | IRQ_STATUS | RO | 0x0000_0000 | Masked interrupt status |
| 0x20 | IRQ_CLEAR | WO | - | Write 1 to clear interrupt |
| 0x24 | TXFIFO_LVL | RO | 0x0000_0000 | TX FIFO level |
| 0x28 | RXFIFO_LVL | RO | 0x0000_0000 | RX FIFO level |
| 0x2C | VERSION | RO | 0x0001_0000 | Version number |

**Reset value notes**

`CTRL` reset value is `0x0000_0060`, corresponding to:

- `rx_en = 1`
- `tx_en = 1`
- all other control bits reset to 0

`STATUS` reset value is `0x0000_000A`, corresponding to:

- `tx_empty = 1`
- `rx_empty = 1`

`IRQ_RAW` reads as `0x0000_0002` after reset release because
`tx_empty_raw` is a live level-type source and the reset TX FIFO is empty.
The three stored sticky sources (`done_raw`, `tx_underflow_raw`, and
`rx_overflow_raw`) reset to zero. `IRQ_STATUS` and `irq` remain zero because
`IRQ_EN` resets to zero.

`TXDATA` and `IRQ_CLEAR` contain no readable storage. Their reset entry is
therefore shown as `-`, while their APB read value is defined as zero.

---

## 7. Detailed Register Definitions

### 7.1 CTRL Register
**Address:** `0x00`

| Bit | Field | Access | Reset | Description |
|---|---|---|---|---|
| 0 | enable | RW | 0 | Module enable |
| 1 | start | WO pulse | 0 | Start one transfer |
| 2 | cpha | RW | 0 | SPI phase configuration |
| 3 | cpol | RW | 0 | SPI polarity configuration |
| 4 | cont | RW | 0 | Continuous transfer mode |
| 5 | rx_en | RW | 1 | Receive enable |
| 6 | tx_en | RW | 1 | Transmit enable |
| 7 | soft_reset | WO pulse | 0 | Software reset |
| 31:8 | reserved | - | 0 | Reserved |

**Semantic notes**

- When `enable = 0`, no new transaction may be started
- `start` and `soft_reset` are write-only command bits. Writing 1 generates a
  one-PCLK-cycle pulse; reading CTRL always returns zero for these bits
- Every CTRL write also updates all six RW fields from the same write data.
  Software shall preserve their intended values when issuing a command
- `start` is accepted only while the SPI controller is in `IDLE`. A start
  written during `LOAD`, `SHIFT`, or `FRAME_DONE` is ignored
- If `start` and `soft_reset` are written as 1 in the same APB transfer,
  software reset takes precedence and no frame is started
- `cont = 1` means that after one start, if the TX FIFO still contains data, CS remains asserted and subsequent frames continue automatically
- Except for `soft_reset`, software shall update CTRL configuration fields and
  CLKDIV only while the controller is idle. Mid-frame configuration changes
  are unsupported and their SPI waveform is not architecturally guaranteed

### 7.2 STATUS Register
**Address:** `0x04`

| Bit | Field | Access | Reset | Description |
|---|---|---|---|---|
| 0 | busy | RO | 0 | Transfer currently in progress |
| 1 | tx_empty | RO | 1 | TX FIFO empty |
| 2 | tx_full | RO | 0 | TX FIFO full |
| 3 | rx_empty | RO | 1 | RX FIFO empty |
| 4 | rx_full | RO | 0 | RX FIFO full |
| 5 | cs_active | RO | 0 | Chip select currently active |
| 6 | done_pending | RO | 0 | Completion event pending clear |
| 7 | tx_underflow_pending | RO | 0 | TX underflow event pending clear |
| 8 | rx_overflow_pending | RO | 0 | RX overflow event pending clear |
| 31:9 | reserved | - | 0 | Reserved |

**Note**  
The last three fields are essentially mapped from sticky raw bits inside `irq_ctrl`, to let software quickly observe key event status.

### 7.3 CLKDIV Register
**Address:** `0x08`

| Bit | Field | Access | Reset | Description |
|---|---|---|---|---|
| 7:0 | div_value | RW | 1 | SPI SCLK divider value |
| 31:8 | reserved | - | 0 | Reserved |

**Semantics**

- Define `effective_div = (div_value == 0) ? 1 : div_value`
- While a frame is shifting, `spi_sclk` toggles once every `effective_div`
  PCLK cycles
- One full SCLK period requires two toggles
- Therefore `T_SCLK = 2 * effective_div * T_PCLK`
- Consequently, `div_value = 0` and `div_value = 1` produce the same SCLK rate

### 7.4 TXDATA Register
**Address:** `0x0C`

| Bit | Field | Access | Description |
|---|---|---|---|
| 7:0 | tx_byte | WO | Write one byte into TX FIFO |
| 31:8 | reserved | - | Reserved |

**Semantics**

- If TX FIFO is not full, the write succeeds
- If TX FIFO is full, the write is ignored
- v1 does not report TX-write-when-full behavior via APB error or any extra sticky error bit

### 7.5 RXDATA Register
**Address:** `0x10`

| Bit | Field | Access | Description |
|---|---|---|---|
| 7:0 | rx_byte | RO | Read one byte out of RX FIFO |
| 31:8 | reserved | - | Reserved |

**Semantics**

- If RX FIFO is not empty, the read pops one byte
- If RX FIFO is empty, return 0

### 7.6 IRQ_EN Register
**Address:** `0x14`

| Bit | Field | Access | Reset |
|---|---|---|---|
| 0 | done_en | RW | 0 |
| 1 | tx_empty_en | RW | 0 |
| 2 | rx_not_empty_en | RW | 0 |
| 3 | tx_underflow_en | RW | 0 |
| 4 | rx_overflow_en | RW | 0 |
| 31:5 | reserved | - | 0 |

### 7.7 IRQ_RAW Register
**Address:** `0x18`

| Bit | Field | Access | Reset |
|---|---|---|---|
| 0 | done_raw | RO | 0 |
| 1 | tx_empty_raw | RO | 1 |
| 2 | rx_not_empty_raw | RO | 0 |
| 3 | tx_underflow_raw | RO | 0 |
| 4 | rx_overflow_raw | RO | 0 |
| 31:5 | reserved | - | 0 |

**Semantics**

- `done_raw`: sticky event-type
- `tx_underflow_raw`: sticky event-type
- `rx_overflow_raw`: sticky event-type
- `tx_empty_raw`: level-type
- `rx_not_empty_raw`: level-type
- The reset column gives the value observed after reset release. Level-type
  fields contain no resettable storage and always reflect current FIFO state

### 7.8 IRQ_STATUS Register
**Address:** `0x1C`

| Bit | Field | Access |
|---|---|---|
| 4:0 | irq_masked_status | RO |
| 31:5 | reserved | - |

**Definition**

`IRQ_STATUS = IRQ_RAW & IRQ_EN`

### 7.9 IRQ_CLEAR Register
**Address:** `0x20`

| Bit | Field | Access |
|---|---|---|
| 0 | clr_done | WO |
| 1 | clr_tx_empty | WO |
| 2 | clr_rx_not_empty | WO |
| 3 | clr_tx_underflow | WO |
| 4 | clr_rx_overflow | WO |
| 31:5 | reserved | - |

**Semantics**

- For sticky items, write 1 to clear
- For level-type items, clear has no effect
- If a sticky event and its clear bit occur in the same PCLK cycle, clear takes
  precedence

### 7.10 TXFIFO_LVL / RXFIFO_LVL
**Addresses:** `0x24`, `0x28`

- `TXFIFO_LVL` returns the current TX FIFO byte count
- `RXFIFO_LVL` returns the current RX FIFO byte count

### 7.11 VERSION Register
**Address:** `0x2C`

| Bits | Field | Value |
|---|---|---|
| 31:16 | major | `16'h0001` |
| 15:0 | minor | `16'h0000` |

---

## 8. SPI Behavioral Specification

### 8.1 Basic Transfer Unit
v1 is fixed as:

`1 transaction frame = 8 bits`

v1 does not support:

- Variable-length frames
- 16-bit frames
- 32-bit frames

### 8.2 Transmit/Receive Policy
v1 adopts a full-duplex SPI model:

- For every 1 bit transmitted, 1 bit is received simultaneously
- If `tx_en = 0`, transmit dummy value `8'h00`
- If `rx_en = 0`, do not write received data into RX FIFO

### 8.3 Start Conditions
`spi_ctrl` may start a frame only when all relevant conditions are satisfied:

- `cfg_enable = 1`
- The controller is in `IDLE` and a `start_pulse` is received, or a completed
  frame is eligible for continuous-mode continuation
- If `cfg_tx_en = 1`, the TX FIFO shall contain at least 1 byte
- If `cfg_tx_en = 0` and `cfg_rx_en = 1`, dummy transmission is allowed

Start rejection behavior is fixed as follows:

- If `cfg_enable = 0`, start is ignored without an interrupt event
- If `cfg_tx_en = 1` and the TX FIFO is empty, start does not begin a frame and
  generates `evt_tx_underflow`
- If `cfg_tx_en = 0` and `cfg_rx_en = 1`, start begins one dummy-transmit frame
- If both `cfg_tx_en` and `cfg_rx_en` are 0, start is ignored without an
  underflow event
- A start received outside `IDLE` is ignored

### 8.4 Continuous Mode
When `cont = 0`:

- One `start_pulse` executes only one frame
- After frame completion, CS is released immediately and the controller returns to idle

When `cont = 1`:

- One `start_pulse` may trigger continuous transmission
- Automatic continuation applies only when `cfg_tx_en = 1`. As long as the TX
  FIFO still contains data, CS remains active between frames
- When all data has been sent, CS is released
- Each completed frame still generates one `evt_done` pulse and, when RX is
  enabled, attempts one RX FIFO write
- Normal termination caused by the TX FIFO becoming empty does not generate
  `evt_tx_underflow`
- Dummy receive-only operation (`tx_en = 0, rx_en = 1`) executes one frame per
  accepted start even when `cont = 1`

### 8.5 Software Reset Behavior
Writing `CTRL.soft_reset = 1` has execution-state reset semantics, not a full
register reset. It has the following effects:

- Abort the active frame and return the SPI controller to `IDLE`
- Deassert CS, drive MOSI low, and return SCLK to the configured CPOL idle level
- Empty both TX and RX FIFOs
- Clear the sticky done, TX-underflow, and RX-overflow interrupt sources
- Recompute level-type interrupt sources from the now-empty FIFOs

Software reset does not independently restore CTRL RW fields to their cold-reset
defaults. As with every CTRL write, those fields take the values supplied in
the same APB write that requests soft reset; software must preserve the desired
configuration bits. CLKDIV, IRQ_EN, and VERSION are unchanged. After software
reset `tx_empty_raw` is 1, and its contribution to IRQ_STATUS and `irq` depends
on the preserved `IRQ_EN.tx_empty_en` bit. Once the reset command has completed,
STATUS reads `0x0000_000A` until new activity changes FIFO or controller state.

### 8.6 CPOL / CPHA
v1 supports the four standard modes:

- Mode 0: `CPOL=0`, `CPHA=0`
- Mode 1: `CPOL=0`, `CPHA=1`
- Mode 2: `CPOL=1`, `CPHA=0`
- Mode 3: `CPOL=1`, `CPHA=1`

**Implementation strategy**

- `cpol` determines the idle level of `spi_sclk`
- Internally generate:
  - `leading_edge_pulse`
  - `trailing_edge_pulse`
- `cpha` determines whether sampling/shifting occurs on the leading or trailing edge

A recommended implementation explicitly abstracts:

- `sample_edge_pulse`
- `shift_edge_pulse`

rather than scattering CPOL/CPHA special-case logic throughout FSM branches.

---

## 9. Error and Exception Semantics

### 9.1 tx_underflow
`tx_underflow` is generated when an APB start command is received while the
controller is in `IDLE`, `cfg_enable = 1`, `cfg_tx_en = 1`, and the TX FIFO is
empty. No SPI frame starts in this case.

**Notes**

- Under normal, controlled use this event should not occur frequently
- Keeping this event improves robustness and leaves room for future extension

### 9.2 rx_overflow
When one receive frame completes:

- if `cfg_rx_en = 1`
- and `u_rx_fifo.full = 1`

then:

- the current received byte is dropped
- `evt_rx_overflow` is asserted
- the sticky raw bit is latched inside `irq_ctrl`

### 9.3 APB Illegal Access
In v1:

- Illegal address read, including an unaligned address: return
  `32'h0000_0000`
- Illegal address write: ignore
- Do not assert `PSLVERR`

---

## 10. Frozen Module Responsibilities

### 10.1 apb_reg_block
**Responsibilities**

- APB access handling
- Register storage
- `start_pulse` generation
- `soft_reset_pulse` generation
- `tx_fifo_wen / wdata` generation
- `rx_fifo_ren` generation
- `PRDATA` organization
- `irq_en / irq_clear` exposure

**Non-responsibilities**

- SPI shift/sample
- Raw interrupt latching
- FIFO internal implementation

### 10.2 spi_ctrl
**Responsibilities**

- SPI master FSM
- SCLK divider
- Edge pulse generation
- Automatic CS control
- Bit counter / shift register
- TX FIFO data fetch
- RX FIFO write request
- Event outputs

**Non-responsibilities**

- APB address handling
- Raw/sticky interrupt storage
- FIFO storage

### 10.3 irq_ctrl
**Responsibilities**

- Event-type raw latching
- Level-type raw pass-through
- Masking
- Clearing
- `irq` output

**Non-responsibilities**

- SPI transfer control
- APB decode
- FIFO buffering

### 10.4 sync_fifo
**Responsibilities**

- Data storage
- `full / empty / level`

**Non-responsibilities**

- Protocol interpretation
- Control logic
- Interrupt logic

---

## 11. Draft Module Port Definitions

### 11.1 Top-Level Module `apb_spi_master_top`
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

## 12. Recommended Internal SPI Controller Implementation

### 12.1 Recommended Main FSM
`spi_ctrl` is recommended to use the following four states:

- `IDLE`
- `LOAD`
- `SHIFT`
- `FRAME_DONE`

**IDLE**

- Wait for `start_pulse`
- Maintain idle SCLK level
- `busy = 0`

**LOAD**

- Assert CS low if required
- Load one byte from TX FIFO into the transmit shift register
- Initialize bit counter / divider counter / edge tracking

**SHIFT**

- Perform 8-bit shift and sample operations
- Use `sample_edge_pulse` and `shift_edge_pulse` according to CPOL/CPHA

**FRAME_DONE**

- If `cfg_rx_en = 1`, write received result into RX FIFO
- Generate `evt_done`
- Decide according to `cfg_cont` and TX FIFO status whether to:
  - return to `LOAD`
  - or release CS and return to `IDLE`

### 12.2 Recommended Internal Key Signals
The following internal naming convention is recommended for `spi_ctrl`:

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

These signals do not need to be exposed as external ports. For debug, observe them through hierarchical references.

---

## 13. Package and Constant Organization Recommendations
It is recommended to create:

`apb_spi_pkg.sv`

This package should centrally define:

- Register address offsets
- IRQ bit indices
- Version constants
- FSM types
- Other shared `localparam` / `typedef`

**Suggested content sketch**

- `localparam CTRL_ADDR = 12'h000;`
- `localparam STATUS_ADDR = 12'h004;`
- `localparam IRQ_DONE_BIT = 0;`
- `localparam IRQ_TX_EMPTY_BIT = 1;`
- `typedef enum logic [1:0] {IDLE, LOAD, SHIFT, FRAME_DONE} spi_state_e;`

This avoids scattering magic numbers throughout the design.

---

## 14. Suggested Directory Structure
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

## 15. Frozen Debug Strategy

### 15.1 Formal Strategy
The formal v1 DUT shall not expose dedicated debug ports.

### 15.2 Debug Method
Debug relies on:

- Waveforms
- Consistent internal signal naming
- Hierarchical reference to internal states

For example:

- `dut.u_spi_ctrl.state_q`
- `dut.u_spi_ctrl.bit_cnt_q`
- `dut.u_tx_fifo.level`
- `dut.u_rx_fifo.level`

### 15.3 Reasons
This approach:

- Keeps the interface clean
- Prevents business-facing ports from being polluted by debug signals
- Preserves architectural simplicity
- Still provides sufficient debuggability

---

## 16. Frozen Item List for v1
The following items are frozen in v1 and shall not be changed casually during RTL development:

1. Top level exposes only APB / SPI / IRQ / clk / reset
2. APB always-ready
3. Single chip select
4. 8-bit frame only
5. MSB-first only
6. CPOL/CPHA support
7. Both TX and RX FIFOs are retained
8. Automatic chip select
9. The four-register interrupt structure is fixed
10. `spi_ctrl` outputs instantaneous events; `irq_ctrl` handles sticky state
11. `apb_reg_block` only performs control/mapping, not SPI behavior
12. Debug is not exposed through ports

---

## 17. Suggested Development Sequence
Based on this spec, the recommended development sequence is:

**Phase 1: Skeleton and shared definitions**

- Create the directory structure
- Complete `apb_spi_pkg.sv`
- Complete empty shell ports for the top level and all submodules

**Phase 2: Basic functional modules**

- Complete `sync_fifo`
- Complete `irq_ctrl`
- Complete `apb_reg_block`

**Phase 3: Core execution module**

- Complete `spi_ctrl`
- Implement the four-state main FSM
- Implement CPOL/CPHA timing behavior

**Phase 4: Top-level integration**

- Complete `apb_spi_master_top`
- Connect control flow, data flow, and interrupt flow

**Phase 5: Verification preparation**

- Output final register documentation
- Create block diagram
- Define verification plan

---

## 18. Final Conclusion
This v1 spec freezes a complete developer-oriented top-level design solution.

Its core characteristics are:

- Clear boundaries
- Controllable complexity
- Well-layered architecture
- Easy RTL landing
- Easy UVM expansion
- Explicit reserved space for future extension

This version of the spec can serve as the unified basis for all subsequent RTL and verification work.
