\# APB-SPI Master Controller v1

\#\# Developer-Oriented Specification

This is \*\*not\*\* a simplified spec for software users, but a
top-level design plan for subsequent RTL/verification development.

\-\--

\# APB-SPI Master Controller v1

\#\# Developer-Oriented Top-Level Design Spec

\*\*Document Status:\*\* Frozen for v1 Architecture

\*\*Target Audience:\*\* RTL designer, verification engineer, future
maintainer

\*\*Scope:\*\* v1 architecture, module partitioning, register model,
signal contracts, implementation boundaries

\*\*Out of Scope:\*\* detailed RTL code, testbench code, firmware driver
code

\-\--

\# 1. Design Goals and Positioning

\#\# 1.1 Project Positioning

This project implements an \*\*APB peripheral-style SPI Master
Controller IP\*\*.

The IP provides an \*\*APB3 slave\*\* interface for configuration and
data access on the upper side, and an \*\*SPI Master\*\* serial
interface on the lower side to drive external SPI slave devices.

The goal of v1 is not a minimal runnable demo, but an integrable IP with
the following characteristics:

\- Clear architecture

\- Stable hierarchy

\- Strong verifiability

\- Clear extensibility

\- Reserved architectural space for future v2/v3 evolution

\#\# 1.2 v1 Design Principles

v1 adheres to the following principles:

\*\*Principle A: Build a complete, closable architecture first\*\*

Prioritize:

\- Complete functional closure

\- Stable interface semantics

\- Clear module boundaries

\- Ease of verification and debugging

rather than excessive features at the initial stage.

\*\*Principle B: Separation of control plane and execution plane\*\*

\- APB register access, configuration storage, and status mapping belong
to the control plane

\- SPI timing generation, shifting, and sampling belong to the execution
plane

\- Interrupt latching, masking, and clearing belong to the event
management plane

\- FIFO acts only as buffer and does not carry protocol semantics

\*\*Principle C: Clean functional top-level ports\*\*

The formal DUT top-level exposes only:

\- APB interface

\- SPI interface

\- IRQ

\- Clock and reset

No debug ports are exposed. Debugging is done via hierarchical reference
to internal signals.

\*\*Principle D: v1 freezes several core constraints\*\*

To control complexity, v1 explicitly freezes the following key
constraints:

\- Single CS

\- Fixed 8-bit frame

\- MSB first

\- APB always-ready

\- No DMA

\- No multi-master

\- No wait-state extension

\- No variable frame length

\-\--

\# 2. v1 Scope Definition

\#\# 2.1 Mandatory Features for v1

v1 must support:

\- APB3 slave register access

\- SPI master mode

\- Single chip-select output

\- Four CPOL/CPHA modes

\- Programmable SCLK clock division

\- 8-bit frame transmit and receive

\- TX FIFO

\- RX FIFO

\- Automatic chip-select control

\- Busy/status reporting

\- Raw interrupt status / enable / masked status / clear

\- Continuous transfer mode

\#\# 2.2 Explicitly Excluded Features for v1

The following features are out of v1 scope:

\- Multi chip-select

\- Multi-master arbitration

\- Dual/quad SPI

\- LSB-first

\- Programmable frame length

\- DMA request / descriptor mode

\- APB wait-state / variable ready

\- Hardware automatic burst length configuration

\- Timeout / watchdog

\- Advanced error recovery

\- Complex software handshake protocols

\-\--

\# 3. Top-Level Architecture Strategy

\#\# 3.1 Architecture Overview

v1 top-level uses four first-level functional subsystems:

1\. Register & APB interface subsystem

2\. SPI control & execution subsystem

3\. FIFO data buffer subsystem

4\. Interrupt & event management subsystem

These four parts are integrated by the top-level module.

\#\# 3.2 Top-Level Module Name

Frozen top-level module name:

\`apb\_spi\_master\_top\`

Top-level responsibilities are limited to:

\- Port definition

\- Submodule instantiation

\- Signal connection between submodules

\- Parameter passing downward

The top-level does not implement complex protocol logic.

\#\# 3.3 Subsystem Partitioning

\#\#\# 3.3.1 Register & APB Interface Subsystem

Module name: \`apb\_reg\_block\`

Responsibilities:

\- APB slave interface attachment

\- Address decoding

\- Control register storage

\- Status register readback organization

\- Data register access interface

\- Control pulse generation

\- Interrupt register access mapping

Not responsible for:

\- SPI timing generation

\- Interrupt sticky state storage

\- FIFO memory implementation

\#\#\# 3.3.2 SPI Control & Execution Subsystem

Module name: \`spi\_ctrl\`

Responsibilities:

\- SPI master state machine

\- Clock division counting

\- SCLK toggle control

\- Leading/trailing edge generation

\- MOSI shift

\- MISO sample

\- Automatic CS control

\- Frame boundary handling

\- Continuous mode scheduling

\- Done / overflow / underflow event generation

Not responsible for:

\- APB address decoding

\- Interrupt enable and sticky management

\- FIFO internal memory implementation

\#\#\# 3.3.3 FIFO Subsystem

Generic module name: \`sync\_fifo\`

Two instances:

\- \`u\_tx\_fifo\`

\- \`u\_rx\_fifo\`

Responsibilities:

\- Data buffering

\- Full/empty/level indication

Not responsible for:

\- SPI protocol semantics

\- Transaction scheduling

\- Interrupt logic

\#\#\# 3.3.4 Interrupt & Event Management Subsystem

Module name: \`irq\_ctrl\`

Responsibilities:

\- Receive event-based and level-based interrupt sources

\- Raw status generation

\- Sticky latching

\- Masking

\- Clearing

\- IRQ output

Not responsible for:

\- SPI timing

\- APB address access

\- FIFO storage

\-\--

\# 4. Top-Level Interface Specification

\#\# 4.1 APB Interface

v1 uses an APB3-style interface.

\*\*Inputs\*\*

\- PCLK

\- PRESETn

\- PSEL

\- PENABLE

\- PWRITE

\- PADDR\[APB\_ADDR\_W-1:0\]

\- PWDATA\[31:0\]

\*\*Outputs\*\*

\- PRDATA\[31:0\]

\- PREADY

\- PSLVERR

\*\*v1 Semantics Frozen\*\*

\- PREADY = 1\'b1

\- PSLVERR = 1\'b0

Notes:

\- v1 does not implement wait-states

\- v1 does not report errors via the APB error channel

\- Illegal address reads return default value; writes are ignored

\#\# 4.2 SPI Interface

\*\*Outputs\*\*

\- spi\_sclk

\- spi\_mosi

\- spi\_cs\_n

\*\*Inputs\*\*

\- spi\_miso

\*\*v1 Semantics Frozen\*\*

\- Single CS

\- Master mode

\- spi\_cs\_n active low

\- Idle spi\_sclk level determined by CPOL

\#\# 4.3 Interrupt Interface

\*\*Output\*\*

\- irq

irq is generated by the irq\_ctrl module based on irq\_raw & irq\_en.

\-\--

\# 5. Top-Level Data Flow and Control Flow

\#\# 5.1 Write Data Path

APB write to TXDATA

→ apb\_reg\_block generates tx\_fifo\_wen / tx\_fifo\_wdata

→ Enqueue to u\_tx\_fifo

→ Dequeue when spi\_ctrl starts a frame

→ Load into transmit shift register

→ Output via MOSI

\#\# 5.2 Read Data Path

spi\_ctrl completes 8-bit reception

→ Forms rx\_fifo\_wdata

→ Enqueue to u\_rx\_fifo

→ APB reads RXDATA

→ apb\_reg\_block generates rx\_fifo\_ren

→ Pop one byte from u\_rx\_fifo

\#\# 5.3 Control Path

APB writes to CTRL/CLKDIV

→ apb\_reg\_block stores configuration

→ Outputs cfg\_\* signals to spi\_ctrl

APB writes CTRL.start

→ apb\_reg\_block generates start\_pulse

→ spi\_ctrl decides whether to start a frame based on current conditions

APB writes CTRL.soft\_reset

→ apb\_reg\_block generates soft\_reset\_pulse

→ Applied to spi\_ctrl, irq\_ctrl, and FIFO reset paths

\#\# 5.4 Interrupt Path

spi\_ctrl generates instantaneous events:

\- evt\_done

\- evt\_tx\_underflow

\- evt\_rx\_overflow

FIFO status generates level events:

\- level\_tx\_empty

\- level\_rx\_not\_empty

These events feed into irq\_ctrl, which generates:

\- irq\_raw

\- irq\_status

\- irq

\-\--

\# 6. v1 Software-Visible Register Architecture

\#\# 6.1 Register Design Strategy

The following strategy is adopted:

\- All registers are 32-bit wide

\- Addresses are word-aligned

\- Control bits and status bits are separated

\- Interrupts use a four-register set:

\- IRQ\_EN

\- IRQ\_RAW

\- IRQ\_STATUS

\- IRQ\_CLEAR

\- Separate data registers:

\- TXDATA

\- RXDATA

\#\# 6.2 Register Map Summary

\| Offset \| Name \| Access \| Reset \| Description \|

\|\-\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|

\| 0x00 \| CTRL \| RW/WO \| 0x0000\_0060 \| Control register \|

\| 0x04 \| STATUS \| RO \| 0x0000\_000A \| Status register \|

\| 0x08 \| CLKDIV \| RW \| 0x0000\_0001 \| Clock divider register \|

\| 0x0C \| TXDATA \| WO \| -- \| Transmit data port \|

\| 0x10 \| RXDATA \| RO \| 0x0000\_0000 \| Receive data port \|

\| 0x14 \| IRQ\_EN \| RW \| 0x0000\_0000 \| Interrupt enable \|

\| 0x18 \| IRQ\_RAW \| RO \| 0x0000\_0000 \| Raw interrupt status \|

\| 0x1C \| IRQ\_STATUS \| RO \| 0x0000\_0000 \| Masked interrupt status
\|

\| 0x20 \| IRQ\_CLEAR \| WO \| -- \| Write 1 to clear interrupt\|

\| 0x24 \| TXFIFO\_LVL \| RO \| 0x0000\_0000 \| TX FIFO level \|

\| 0x28 \| RXFIFO\_LVL \| RO \| 0x0000\_0000 \| RX FIFO level \|

\| 0x2C \| VERSION \| RO \| 0x0001\_0000 \| Version number \|

\*\*Reset Value Notes\*\*

CTRL reset = 0x0000\_0060:

\- rx\_en = 1

\- tx\_en = 1

\- All other control bits 0

STATUS reset = 0x0000\_000A:

\- tx\_empty = 1

\- rx\_empty = 1

\-\--

\# 7. Detailed Register Definition

\#\# 7.1 CTRL Register

Address: 0x00

\| Bit \| Field \| Access \| Reset \| Description \|

\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|

\| 0 \| enable \| RW \| 0 \| Module enable \|

\| 1 \| start \| WO pulse \| 0 \| Start one transfer \|

\| 2 \| cpha \| RW \| 0 \| SPI phase configuration \|

\| 3 \| cpol \| RW \| 0 \| SPI polarity configuration \|

\| 4 \| cont \| RW \| 0 \| Continuous transfer mode \|

\| 5 \| rx\_en \| RW \| 1 \| Receive enable \|

\| 6 \| tx\_en \| RW \| 1 \| Transmit enable \|

\| 7 \| soft\_reset \| WO pulse \| 0 \| Software reset \|

\| 31:8 \| reserved \| -- \| 0 \| Reserved \|

\*\*Semantics\*\*

\- enable=0: new transactions cannot start

\- start is a command pulse; write 1 to trigger, self-clearing

\- soft\_reset is a command pulse; write 1 to trigger, self-clearing

\- cont=1: after one start, if TX FIFO still has data, keep CS active
and transmit consecutive frames

\#\# 7.2 STATUS Register

Address: 0x04

\| Bit \| Field \| Access \| Reset \| Description \|

\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|

\| 0 \| busy \| RO \| 0 \| Currently transferring \|

\| 1 \| tx\_empty \| RO \| 1 \| TX FIFO empty \|

\| 2 \| tx\_full \| RO \| 0 \| TX FIFO full \|

\| 3 \| rx\_empty \| RO \| 1 \| RX FIFO empty \|

\| 4 \| rx\_full \| RO \| 0 \| RX FIFO full \|

\| 5 \| cs\_active \| RO \| 0 \| Chip-select active \|

\| 6 \| done\_pending \| RO \| 0 \| Done event pending clear \|

\| 7 \| tx\_underflow\_pending \| RO \| 0 \| TX underflow event pending
clear\|

\| 8 \| rx\_overflow\_pending \| RO \| 0 \| RX overflow event pending
clear \|

\| 31:9 \| reserved \| -- \| 0 \| Reserved \|

Note: The last three bits map to sticky raw bits in irq\_ctrl for fast
software status check.

\#\# 7.3 CLKDIV Register

Address: 0x08

\| Bit \| Field \| Access \| Reset \| Description \|

\|\-\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|

\| 15:0 \| div\_value \| RW \| 1 \| SPI SCLK division value \|

\| 31:16 \| reserved \| -- \| 0 \| Reserved \|

\*\*Semantics\*\*

\- spi\_sclk toggles once every div\_value + 1 PCLK cycles

\- One full SCLK cycle requires two toggles

\- div\_value == 0 is internally treated as 1

\#\# 7.4 TXDATA Register

Address: 0x0C

\| Bit \| Field \| Access \| Description \|

\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|

\| 7:0 \| tx\_byte \| WO \| Write to TX FIFO \|

\| 31:8 \| reserved \| -- \| Reserved \|

\*\*Semantics\*\*

\- Write succeeds if TX FIFO is not full

\- Write is ignored if TX FIFO is full

\- v1 does not report TX full via APB error or extra sticky bits

\#\# 7.5 RXDATA Register

Address: 0x10

\| Bit \| Field \| Access \| Description \|

\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|

\| 7:0 \| rx\_byte \| RO \| Read one byte from RX FIFO \|

\| 31:8 \| reserved \| -- \| Reserved \|

\*\*Semantics\*\*

\- Read pops one byte if RX FIFO not empty

\- Returns 0 if RX FIFO empty

\#\# 7.6 IRQ\_EN Register

Address: 0x14

\| Bit \| Field \| Access \| Reset \|

\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\--\|

\| 0 \| done\_en \| RW \| 0 \|

\| 1 \| tx\_empty\_en \| RW \| 0 \|

\| 2 \| rx\_not\_empty\_en \| RW \| 0 \|

\| 3 \| tx\_underflow\_en \| RW \| 0 \|

\| 4 \| rx\_overflow\_en \| RW \| 0 \|

\| 31:5 \| reserved \| -- \| 0 \|

\#\# 7.7 IRQ\_RAW Register

Address: 0x18

\| Bit \| Field \| Access \| Reset \|

\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\--\|

\| 0 \| done\_raw \| RO \| 0 \|

\| 1 \| tx\_empty\_raw \| RO \| 0 \|

\| 2 \| rx\_not\_empty\_raw \| RO \| 0 \|

\| 3 \| tx\_underflow\_raw \| RO \| 0 \|

\| 4 \| rx\_overflow\_raw \| RO \| 0 \|

\| 31:5 \| reserved \| -- \| 0 \|

\*\*Semantics\*\*

\- done\_raw: sticky event-based

\- tx\_underflow\_raw: sticky event-based

\- rx\_overflow\_raw: sticky event-based

\- tx\_empty\_raw: level-based

\- rx\_not\_empty\_raw: level-based

\#\# 7.8 IRQ\_STATUS Register

Address: 0x1C

\| Bit \| Field \| Access \|

\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|

\| 4:0 \| irq\_masked\_status \| RO \|

\| 31:5 \| reserved \| -- \|

Definition:

IRQ\_STATUS = IRQ\_RAW & IRQ\_EN

\#\# 7.9 IRQ\_CLEAR Register

Address: 0x20

\| Bit \| Field \| Access \|

\|\-\-\-\-\-\--\|\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|

\| 0 \| clr\_done \| WO \|

\| 1 \| clr\_tx\_empty \| WO \|

\| 2 \| clr\_rx\_not\_empty \| WO \|

\| 3 \| clr\_tx\_underflow \| WO \|

\| 4 \| clr\_rx\_overflow \| WO \|

\| 31:5 \| reserved \| -- \|

\*\*Semantics\*\*

\- Write 1 to clear sticky bits

\- Clear has no effect on level-based bits

\#\# 7.10 TXFIFO\_LVL / RXFIFO\_LVL

Addresses: 0x24, 0x28

\- TXFIFO\_LVL returns current byte count in TX FIFO

\- RXFIFO\_LVL returns current byte count in RX FIFO

\#\# 7.11 VERSION Register

Address: 0x2C

\| Bits \| Field \| Value \|

\|\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|\-\-\-\-\-\-\--\|

\| 31:16 \| major \| 16\'h0001 \|

\| 15:0 \| minor \| 16\'h0000 \|

\-\--

\# 8. SPI Behavior Specification

\#\# 8.1 Basic Transfer Unit

v1 fixed:

\*\*1 transaction frame = 8 bits\*\*

v1 does NOT support:

\- Variable-length frames

\- 16-bit frames

\- 32-bit frames

\#\# 8.2 Transmit/Receive Policy

v1 uses a full-duplex SPI model:

\- 1 bit transmitted, 1 bit received simultaneously

\- If tx\_en = 0, send dummy value 8\'h00

\- If rx\_en = 0, do not write received data to RX FIFO

\#\# 8.3 Start Condition

spi\_ctrl may start a frame if:

\- cfg\_enable = 1

\- start\_pulse received, or continuous mode allows continuation

\- current busy = 0

\- if cfg\_tx\_en = 1, at least 1 byte available in TX FIFO

\- if cfg\_tx\_en = 0 and cfg\_rx\_en = 1, dummy transmission allowed

\#\# 8.4 Continuous Mode

When cont=0:

\- One start\_pulse executes only 1 frame

\- CS released immediately after frame; return to idle

When cont=1:

\- One start\_pulse triggers continuous transmission

\- CS remains active between frames as long as TX FIFO has data

\- CS released after all transmissions complete

\#\# 8.5 CPOL / CPHA

v1 supports 4 standard modes:

\- Mode 0: CPOL=0, CPHA=0

\- Mode 1: CPOL=0, CPHA=1

\- Mode 2: CPOL=1, CPHA=0

\- Mode 3: CPOL=1, CPHA=1

Implementation strategy:

\- cpol determines idle spi\_sclk level

\- Internally generate:

\- leading\_edge\_pulse

\- trailing\_edge\_pulse

\- cpha selects whether sample/shift occur on leading or trailing edge

Recommended explicit abstraction:

\- sample\_edge\_pulse

\- shift\_edge\_pulse

Avoid scattering CPOL/CPHA logic across state machine branches.

\-\--

\# 9. Error and Exception Semantics

\#\# 9.1 tx\_underflow

v1 defines and retains this event to indicate the executor expected next
frame data but no valid TX data was available.

Note:

\- Should not occur frequently under normal controlled operation

\- Retained for robustness and future extensibility

\#\# 9.2 rx\_overflow

When a frame reception completes:

\- if cfg\_rx\_en = 1

\- and u\_rx\_fifo.full = 1

Then:

\- Current received byte is discarded

\- evt\_rx\_overflow is asserted

\- Sticky raw bit latched in irq\_ctrl

\#\# 9.3 APB Illegal Access

In v1:

\- Illegal address read: return 0

\- Illegal address write: ignore

\- PSLVERR is never asserted

\-\--

\# 10. Frozen Module Responsibilities

\#\# 10.1 apb\_reg\_block

\*\*Responsibilities\*\*

\- APB access handling

\- Register storage

\- start\_pulse generation

\- soft\_reset\_pulse generation

\- tx\_fifo\_wen/wdata generation

\- rx\_fifo\_ren generation

\- PRDATA composition

\- irq\_en/irq\_clear exposure

\*\*Non-Responsibilities\*\*

\- SPI shift/sample

\- Raw interrupt latching

\- FIFO internal implementation

\#\# 10.2 spi\_ctrl

\*\*Responsibilities\*\*

\- SPI master state machine

\- SCLK clock division

\- Edge pulse generation

\- Automatic CS control

\- Bit counter / shift register

\- TX FIFO data read

\- RX FIFO write request

\- Event output

\*\*Non-Responsibilities\*\*

\- APB address handling

\- Raw/sticky interrupt storage

\- FIFO memory

\#\# 10.3 irq\_ctrl

\*\*Responsibilities\*\*

\- Event-based raw latching

\- Level-based raw passthrough

\- Masking

\- Clearing

\- IRQ output

\*\*Non-Responsibilities\*\*

\- SPI transfer control

\- APB decoding

\- FIFO buffering

\#\# 10.4 sync\_fifo

\*\*Responsibilities\*\*

\- Data storage

\- full/empty/level indicators

\*\*Non-Responsibilities\*\*

\- Protocol interpretation

\- Control logic

\- Interrupt logic

\-\--

\# 11. Draft Module Port Definitions

\#\# 11.1 Top-Level: apb\_spi\_master\_top

\`\`\`systemverilog

module apb\_spi\_master\_top \#(

parameter int unsigned APB\_ADDR\_W = 12,

parameter int unsigned TX\_FIFO\_DEPTH = 8,

parameter int unsigned RX\_FIFO\_DEPTH = 8,

parameter int unsigned CLKDIV\_W = 16

)(

input logic PCLK,

input logic PRESETn,

input logic PSEL,

input logic PENABLE,

input logic PWRITE,

input logic \[APB\_ADDR\_W-1:0\] PADDR,

input logic \[31:0\] PWDATA,

output logic \[31:0\] PRDATA,

output logic PREADY,

output logic PSLVERR,

output logic spi\_sclk,

output logic spi\_mosi,

input logic spi\_miso,

output logic spi\_cs\_n,

output logic irq

);

\`\`\`

\#\# 11.2 apb\_reg\_block

\`\`\`systemverilog

module apb\_reg\_block \#(

parameter int unsigned APB\_ADDR\_W = 12,

parameter int unsigned CLKDIV\_W = 16,

parameter int unsigned FIFO\_LVL\_W = 4

)(

input logic clk,

input logic rst\_n,

input logic psel,

input logic penable,

input logic pwrite,

input logic \[APB\_ADDR\_W-1:0\] paddr,

input logic \[31:0\] pwdata,

output logic \[31:0\] prdata,

output logic pready,

output logic pslverr,

output logic cfg\_enable,

output logic cfg\_cpha,

output logic cfg\_cpol,

output logic cfg\_cont,

output logic cfg\_rx\_en,

output logic cfg\_tx\_en,

output logic \[CLKDIV\_W-1:0\] cfg\_clkdiv,

output logic start\_pulse,

output logic soft\_reset\_pulse,

output logic tx\_fifo\_wen,

output logic \[7:0\] tx\_fifo\_wdata,

output logic rx\_fifo\_ren,

input logic \[7:0\] rx\_fifo\_rdata,

input logic status\_busy,

input logic status\_tx\_empty,

input logic status\_tx\_full,

input logic status\_rx\_empty,

input logic status\_rx\_full,

input logic status\_cs\_active,

input logic evt\_done\_pending,

input logic evt\_tx\_underflow\_pending,

input logic evt\_rx\_overflow\_pending,

input logic \[FIFO\_LVL\_W-1:0\] tx\_fifo\_level,

input logic \[FIFO\_LVL\_W-1:0\] rx\_fifo\_level,

output logic \[4:0\] irq\_en,

input logic \[4:0\] irq\_raw,

input logic \[4:0\] irq\_status,

output logic \[4:0\] irq\_clear

);

\`\`\`

\#\# 11.3 spi\_ctrl

\`\`\`systemverilog

module spi\_ctrl \#(

parameter int unsigned CLKDIV\_W = 16

)(

input logic clk,

input logic rst\_n,

input logic cfg\_enable,

input logic cfg\_cpha,

input logic cfg\_cpol,

input logic cfg\_cont,

input logic cfg\_rx\_en,

input logic cfg\_tx\_en,

input logic \[CLKDIV\_W-1:0\] cfg\_clkdiv,

input logic start\_pulse,

input logic soft\_reset\_pulse,

output logic tx\_fifo\_ren,

input logic \[7:0\] tx\_fifo\_rdata,

input logic tx\_fifo\_empty,

output logic rx\_fifo\_wen,

output logic \[7:0\] rx\_fifo\_wdata,

input logic rx\_fifo\_full,

output logic spi\_sclk,

output logic spi\_mosi,

input logic spi\_miso,

output logic spi\_cs\_n,

output logic status\_busy,

output logic status\_cs\_active,

output logic evt\_done,

output logic evt\_tx\_underflow,

output logic evt\_rx\_overflow

);

\`\`\`

\#\# 11.4 irq\_ctrl

\`\`\`systemverilog

module irq\_ctrl (

input logic clk,

input logic rst\_n,

input logic soft\_reset\_pulse,

input logic evt\_done,

input logic evt\_tx\_underflow,

input logic evt\_rx\_overflow,

input logic level\_tx\_empty,

input logic level\_rx\_not\_empty,

input logic \[4:0\] irq\_en,

input logic \[4:0\] irq\_clear,

output logic \[4:0\] irq\_raw,

output logic \[4:0\] irq\_status,

output logic irq

);

\`\`\`

\#\# 11.5 sync\_fifo

\`\`\`systemverilog

module sync\_fifo \#(

parameter int unsigned WIDTH = 8,

parameter int unsigned DEPTH = 8

)(

input logic clk,

input logic rst\_n,

input logic w\_en,

input logic \[WIDTH-1:0\] w\_data,

output logic full,

input logic r\_en,

output logic \[WIDTH-1:0\] r\_data,

output logic empty,

output logic \[\$clog2(DEPTH+1)-1:0\] level

);

\`\`\`

\-\--

\# 12. SPI Controller Internal Implementation Recommendations

\#\# 12.1 Recommended Master State Machine

spi\_ctrl recommended 4 states:

\- IDLE

\- LOAD

\- SHIFT

\- FRAME\_DONE

\*\*IDLE\*\*

\- Wait for start\_pulse

\- Maintain idle SCLK level

\- busy=0

\*\*LOAD\*\*

\- Assert CS if needed

\- Load 1 byte from TX FIFO to transmit shift register

\- Initialize bit counter / divider counter / edge tracking

\*\*SHIFT\*\*

\- Perform 8-bit shift and sample

\- Use sample\_edge\_pulse and shift\_edge\_pulse based on CPOL/CPHA

\*\*FRAME\_DONE\*\*

\- If cfg\_rx\_en=1, write result to RX FIFO

\- Generate evt\_done

\- Based on cfg\_cont and TX FIFO status:

\- Return to LOAD

\- Or release CS and return to IDLE

\#\# 12.2 Recommended Internal Key Signals

Recommended internal naming convention for spi\_ctrl:

\- state\_q

\- state\_d

\- clkdiv\_cnt\_q

\- bit\_cnt\_q

\- tx\_shift\_reg\_q

\- rx\_shift\_reg\_q

\- sclk\_q

\- cs\_active\_q

\- sample\_edge\_pulse

\- shift\_edge\_pulse

These signals are not exposed as ports; observed via hierarchical
reference for debug.

\-\--

\# 13. Package and Constant Organization Recommendation

Recommended to create:

\`apb\_spi\_pkg.sv\`

Define centrally:

\- Register address offsets

\- IRQ bit indices

\- Version constants

\- State machine type

\- Other shared localparam/typedef

Example content:

\- localparam CTRL\_ADDR = 12\'h000;

\- localparam STATUS\_ADDR = 12\'h004;

\- localparam IRQ\_DONE\_BIT = 0;

\- localparam IRQ\_TX\_EMPTY\_BIT = 1;

\- typedef enum logic \[1:0\] {IDLE, LOAD, SHIFT, FRAME\_DONE}
spi\_state\_e;

Avoid scattered magic numbers.

\-\--

\# 14. Recommended Directory Structure

\`\`\`

apb\_spi\_master/

├── rtl/

│ ├── top/

│ │ └── apb\_spi\_master\_top.sv

│ ├── reg\_if/

│ │ └── apb\_reg\_block.sv

│ ├── ctrl/

│ │ └── spi\_ctrl.sv

│ ├── fifo/

│ │ └── sync\_fifo.sv

│ ├── irq/

│ │ └── irq\_ctrl.sv

│ ├── pkg/

│ │ └── apb\_spi\_pkg.sv

│ └── include/

│ └── apb\_spi\_defs.svh

├── doc/

│ ├── spec\_v1.md

│ ├── reg\_map\_v1.md

│ └── architecture\_v1.md

├── tb/

├── sim/

└── tests/

\`\`\`

\-\--

\# 15. Frozen Debug Strategy

\#\# 15.1 Formal Strategy

v1 formal DUT does not expose debug ports.

\#\# 15.2 Debug Method

Debug relies on:

\- Waveforms

\- Internal signal naming convention

\- Hierarchical reference to internal state

Examples:

\- dut.u\_spi\_ctrl.state\_q

\- dut.u\_spi\_ctrl.bit\_cnt\_q

\- dut.u\_tx\_fifo.level

\- dut.u\_rx\_fifo.level

\#\# 15.3 Rationale

This ensures:

\- Clean interface

\- No pollution of functional ports by debug signals

\- Clean architecture

\- Sufficient debug visibility

\-\--

\# 16. v1 Frozen Items List

The following items are frozen in v1 and shall not be arbitrarily
changed during RTL implementation:

1\. Top-level exposes only APB/SPI/IRQ/clk/reset

2\. APB always-ready

3\. Single chip-select

4\. 8-bit frame only

5\. MSB first only

6\. CPOL/CPHA support

7\. TX/RX FIFO both implemented

8\. Automatic chip-select control

9\. Fixed four-register interrupt structure

10\. spi\_ctrl outputs instantaneous events; irq\_ctrl handles sticky
logic

11\. apb\_reg\_block only handles control/mapping, not SPI behavior

12\. Debug not exposed via ports

\-\--

\# 17. Recommended Subsequent Development Sequence

Based on this spec, the recommended development flow is:

\*\*Phase 1: Skeleton and Common Definitions\*\*

\- Create directory structure

\- Implement apb\_spi\_pkg.sv

\- Complete top-level and submodule empty port shells

\*\*Phase 2: Basic Functional Modules\*\*

\- Implement sync\_fifo

\- Implement irq\_ctrl

\- Implement apb\_reg\_block

\*\*Phase 3: Core Execution Module\*\*

\- Implement spi\_ctrl

\- Implement 4-state main state machine

\- Implement CPOL/CPHA timing

\*\*Phase 4: Top-Level Integration\*\*

\- Complete apb\_spi\_master\_top

\- Connect control flow, data flow, and interrupt flow

\*\*Phase 5: Verification Preparation\*\*

\- Generate final register documentation

\- Create block diagram

\- Define verification plan

\-\--

\# 18. Final Conclusion

This v1 specification freezes a complete top-level design plan for
developers.

Core characteristics:

\- Clear boundaries

\- Controlled complexity

\- Reasonable architectural layering

\- Easy RTL implementation

\- Straightforward UVM verification

\- Clear extension path reserved

This spec serves as the unified reference for all subsequent RTL and
verification work.
