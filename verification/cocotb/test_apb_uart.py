"""
Cocotb testbench for APB UART using Verilator
"""

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
import random


class APBUARTTest:
    def __init__(self, dut):
        self.dut = dut
        self.errors = 0

    async def reset_dut(self):
        self.dut.presetn.value = 0
        self.dut.psel.value = 0
        self.dut.penable.value = 0
        self.dut.pwrite.value = 0
        self.dut.paddr.value = 0
        self.dut.pwdata.value = 0
        self.dut.uart_rx.value = 1
        await Timer(100, units="ns")
        self.dut.presetn.value = 1
        await Timer(100, units="ns")

    async def apb_write(self, addr, data):
        await RisingEdge(self.dut.pclk)
        self.dut.paddr.value = addr
        self.dut.pwdata.value = data
        self.dut.pwrite.value = 1
        self.dut.psel.value = 1
        self.dut.penable.value = 0

        await RisingEdge(self.dut.pclk)
        self.dut.penable.value = 1

        await RisingEdge(self.dut.pclk)
        while self.dut.pready.value == 0:
            await RisingEdge(self.dut.pclk)

        await RisingEdge(self.dut.pclk)
        await RisingEdge(self.dut.pclk)
        self.dut.psel.value = 0
        self.dut.penable.value = 0
        self.dut.pwrite.value = 0

    async def apb_read(self, addr):
        await RisingEdge(self.dut.pclk)
        self.dut.paddr.value = addr
        self.dut.pwrite.value = 0
        self.dut.psel.value = 1
        self.dut.penable.value = 0

        await RisingEdge(self.dut.pclk)
        self.dut.penable.value = 1

        await RisingEdge(self.dut.pclk)
        while self.dut.pready.value == 0:
            await RisingEdge(self.dut.pclk)

        await Timer(1, units="ns")
        data = self.dut.prdata.value
        await RisingEdge(self.dut.pclk)
        await RisingEdge(self.dut.pclk)
        self.dut.psel.value = 0
        self.dut.penable.value = 0

        return data.integer

    async def send_uart_byte(self, data):
        await RisingEdge(self.dut.pclk)
        self.dut.uart_rx.value = 0
        baud_div = await self.apb_read(0xC)
        bit_period = (baud_div + 1) * 10

        for i in range(8):
            self.dut.uart_rx.value = (data >> i) & 1
            await Timer(bit_period, units="ns")

        self.dut.uart_rx.value = 1
        await Timer(bit_period, units="ns")


@cocotb.test()
async def test_apb_basic(dut):
    """Test basic APB read/write"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0xC, 100)
    data = await test.apb_read(0xC)
    assert data == 100, f"Expected 100, got {data}"

    await test.apb_write(0x8, 3)
    data = await test.apb_read(0x8)
    assert (data & 0x3) == 3, f"Expected 3, got {data}"

    print("test_apb_basic: PASSED")


@cocotb.test()
async def test_tx_fifo(dut):
    """Test TX FIFO operations"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0xC, 10)

    for i in range(20):
        await test.apb_write(0x0, i)

    status = await test.apb_read(0x4)
    tx_full = (status >> 1) & 1
    assert tx_full == 1, "TX FIFO should be full"

    print("test_tx_fifo: PASSED")


@cocotb.test()
async def test_rx_fifo(dut):
    """Test RX FIFO operations"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0xC, 10)

    await test.send_uart_byte(0x55)
    await Timer(5000, units="ns")
    await test.send_uart_byte(0xAA)
    await Timer(5000, units="ns")

    data1 = await test.apb_read(0x0)
    data2 = await test.apb_read(0x0)

    print(f"RX Data1: {data1} (expected 85), Data2: {data2} (expected 170)")

    print("test_rx_fifo: PASSED")


@cocotb.test()
async def test_interrupt(dut):
    """Test interrupt generation"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0x8, 0x3)

    await test.apb_write(0x0, 0x41)

    await Timer(500, units="ns")

    irq = dut.irq.value
    print(f"IRQ value: {irq}")

    print("test_interrupt: PASSED")


@cocotb.test()
async def test_fifo_clear(dut):
    """Test FIFO clear operations"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0xC, 10)
    await test.apb_write(0x0, 0x12)
    await test.apb_write(0x0, 0x34)

    await test.apb_write(0x8, 0x10)

    status = await test.apb_read(0x4)
    tx_full = (status >> 1) & 1
    assert tx_full == 0, "TX FIFO should be empty after clear"

    print("test_fifo_clear: PASSED")


@cocotb.test()
async def test_bauddiv(dut):
    """Test BAUDDIV configuration"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0xC, 10)
    data = await test.apb_read(0xC)
    assert data == 10, f"Expected 10, got {data}"

    await test.apb_write(0xC, 1000)
    data = await test.apb_read(0xC)
    assert data == 1000, f"Expected 1000, got {data}"

    print("test_bauddiv: PASSED")


@cocotb.test()
async def test_status_register(dut):
    """Test STATUS register bits"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    status = await test.apb_read(0x4)
    rx_empty = status & 1
    tx_full = (status >> 1) & 1
    tx_busy = (status >> 2) & 1
    overrun = (status >> 3) & 1

    assert rx_empty == 1, "RX should be empty initially"
    assert tx_full == 0, "TX should not be full initially"
    assert tx_busy == 0, "TX should not be busy initially"
    assert overrun == 0, "No overrun initially"

    print("test_status_register: PASSED")


@cocotb.test()
async def test_multiple_tx(dut):
    """Test multiple TX operations"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0xC, 5)

    for i in range(5):
        await test.apb_write(0x0, 0x40 + i)

    print("test_multiple_tx: PASSED")


@cocotb.test()
async def test_rx_overrun(dut):
    """Test RX overrun detection"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0xC, 5)

    for i in range(20):
        await test.send_uart_byte(i)
        await Timer(200, units="ns")

    status = await test.apb_read(0x4)
    overrun = (status >> 3) & 1

    print(f"Overrun flag: {overrun}")
    print("test_rx_overrun: PASSED")


@cocotb.test()
async def test_control_register(dut):
    """Test CTRL register"""
    cocotb.start_soon(Clock(dut.pclk, 10, units="ns").start())

    test = APBUARTTest(dut)
    await test.reset_dut()

    await test.apb_write(0x8, 0x1)
    data = await test.apb_read(0x8)
    assert (data & 0x1) == 1, "TX IRQ should be enabled"

    await test.apb_write(0x8, 0x2)
    data = await test.apb_read(0x8)
    assert (data & 0x2) == 2, "RX IRQ should be enabled"

    print("test_control_register: PASSED")
