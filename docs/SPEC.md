# APB UART Design Specification

## Document Information
- **Version:** 1.0
- **Date:** 2024
- **Author:** Documentation Engineer
- **Status:** Final

---

## Table of Contents
1. [Design Specification](#1-design-specification)
2. [Register Description](#2-register-description)
3. [Interface Description](#3-interface-description)
4. [Usage Guide](#4-usage-guide)

---

## 1. Design Specification

### 1.1 Overview

The APB UART (Universal Asynchronous Receiver-Transmitter) is a configurable serial communication peripheral designed for AMBA APB (Advanced Peripheral Bus) based systems. It provides full-duplex serial communication with configurable baud rates and interrupt support.

The design implements a standard 8N1 UART format (8 data bits, no parity, 1 stop bit) with 16-byte transmit and receive FIFOs to reduce CPU intervention frequency.

### 1.2 Feature List

| Feature | Description |
|---------|-------------|
| **Bus Interface** | AMBA 3.0 APB Slave Interface |
| **Data Format** | 8N1 (8 data bits, no parity, 1 stop bit) |
| **Baud Rate** | Configurable via 16-bit divider register |
| **TX FIFO** | 16-byte depth with full flag |
| **RX FIFO** | 16-byte depth with empty flag |
| **Interrupts** | TX interrupt (FIFO not full), RX interrupt (data available) |
| **Error Detection** | Overrun error detection |
| **FIFO Control** | Individual TX/RX FIFO clear capability |
| **Clock Domain** | Single clock domain operation |

### 1.3 Block Diagram Description

```
                      +------------------------------------------+
                      |              APB UART TOP                |
                      |                                          |
      +------------+  |  +----------------+                      |
      |            |  |  |                |                      |
      |  APB       |--+--|  APB UART IF   |                      |
      |  Bus       |  |  |                |                      |
      |            |  |  |  - Registers   |                      |
      +------------+  |  |  - Interrupt   |                      |
                      |  |    Generation  |                      |
                      |  +-------+--------+                      |
                      |          |                               |
                      |          | Control & Data                |
                      |          |                               |
                      |    +-----+-----+    +----------+         |
                      |    |           |    |          |         |
                      |    |  UART TX  |    |  UART RX |         |
                      |    |           |    |          |         |
                      |    | - FIFO    |    | - FIFO   |         |
                      |    | - State   |    | - State  |         |
                      |    |   Machine |    |   Machine|         |
                      |    +-----+-----+    +----+-----+         |
                      |          |               |               |
                      |          |               |               |
                      +----------+---------------+---------------+
                                 |               |
                            UART_TX           UART_RX
```

### 1.3.1 Module Hierarchy

```
apb_uart_top
├── apb_uart_if      // APB Interface and Register Block
├── uart_tx          // UART Transmitter
└── uart_rx          // UART Receiver
```

### 1.4 Design Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| APB_ADDR_WIDTH | 4 | APB address bus width |

---

## 2. Register Description

### 2.1 Address Map

The APB UART peripheral uses a 4-bit address bus, providing 16 addressable locations:

| Offset | Name | R/W | Description |
|--------|------|-----|-------------|
| 0x0 | RXDATA | R | Receive Data Register |
| 0x0 | TXDATA | W | Transmit Data Register |
| 0x4 | STATUS | R | Status Register |
| 0x8 | CTRL | R/W | Control Register |
| 0xC | BAUDDIV | R/W | Baud Rate Divider Register |

**Note:** RXDATA and TXDATA share the same address (0x0).

### 2.2 Register Bit Definitions

#### 2.2.1 Receive Data Register (RXDATA) - Offset 0x0

| Bits | Name | Access | Reset Value | Description |
|------|------|--------|-------------|-------------|
| [7:0] | RXDATA | R | 0x00 | Received data byte. Reading pops data from RX FIFO. |
| [31:8] | Reserved | R | 0x000000 | Reserved, reads as 0 |

#### 2.2.2 Transmit Data Register (TXDATA) - Offset 0x0

| Bits | Name | Access | Reset Value | Description |
|------|------|--------|-------------|-------------|
| [7:0] | TXDATA | W | - | Data byte to transmit |
| [31:8] | Reserved | W | - | Reserved, ignored on write |

#### 2.2.3 Status Register (STATUS) - Offset 0x4

| Bits | Name | Access | Reset Value | Description |
|------|------|--------|-------------|-------------|
| [0] | RX_EMPTY | R | 1 | RX FIFO Empty Flag |
| [1] | TX_FULL | R | 0 | TX FIFO Full Flag |
| [2] | TX_BUSY | R | 0 | Transmitter Busy Flag |
| [3] | OVERRUN_ERR | R | 0 | Overrun Error Flag |
| [31:4] | Reserved | R | 0x0000000 | Reserved |

#### 2.2.4 Control Register (CTRL) - Offset 0x8

| Bits | Name | Access | Reset Value | Description |
|------|------|--------|-------------|-------------|
| [0] | TX_IRQ_EN | R/W | 0 | TX Interrupt Enable |
| [1] | RX_IRQ_EN | R/W | 0 | RX Interrupt Enable |
| [4] | TX_FIFO_CLEAR | W | 0 | TX FIFO Clear (self-clearing) |
| [5] | RX_FIFO_CLEAR | W | 0 | RX FIFO Clear (self-clearing) |
| [31:2] | Reserved | R/W | 0 | Reserved |

#### 2.2.5 Baud Rate Divider Register (BAUDDIV) - Offset 0xC

| Bits | Name | Access | Reset Value | Description |
|------|------|--------|-------------|-------------|
| [15:0] | DIVIDER | R/W | 0x0001 | Baud rate divider value |
| [31:16] | Reserved | R/W | 0x0000 | Reserved |

**Baud Rate Calculation:**
```
Baud_Rate = PCLK_Frequency / (BAUDDIV + 1)
BAUDDIV = (PCLK_Frequency / Baud_Rate) - 1
```

---

## 3. Interface Description

### 3.1 APB Interface Signals

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| pclk | Input | 1 | APB Clock |
| presetn | Input | 1 | APB Active-Low Reset |
| paddr | Input | 4 | APB Address Bus |
| psel | Input | 1 | APB Select |
| penable | Input | 1 | APB Enable |
| pwrite | Input | 1 | APB Write (1=write, 0=read) |
| pwdata | Input | 32 | APB Write Data |
| prdata | Output | 32 | APB Read Data |
| pready | Output | 1 | APB Ready |
| pslverr | Output | 1 | APB Slave Error |

### 3.2 UART Interface Signals

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| uart_tx | Output | 1 | UART Transmit Data (idle high) |
| uart_rx | Input | 1 | UART Receive Data |

### 3.3 Interrupt Signal

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| irq | Output | 1 | Interrupt Request (active high) |

---

## 4. Usage Guide

### 4.1 Initialization

1. Configure BAUDDIV register for desired baud rate
2. Optionally enable TX/RX interrupts via CTRL register
3. UART is ready for operation

### 4.2 Transmitting Data

1. Check STATUS[TX_FULL] to ensure FIFO has space
2. Write data to TXDATA register (offset 0x0)
3. Data is automatically transmitted

### 4.3 Receiving Data

1. Check STATUS[RX_EMPTY] or wait for RX interrupt
2. Read from RXDATA register (offset 0x0)
3. Reading automatically pops data from FIFO

### 4.4 Interrupt Handling

- **TX Interrupt:** Triggered when TX FIFO has space (TX_FULL=0)
- **RX Interrupt:** Triggered when RX FIFO has data (RX_EMPTY=0)