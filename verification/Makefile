.PHONY: all compile sim wave clean

RTL_DIR = ../rtl
TB_DIR = tb
VERILOG_FILES = $(RTL_DIR)/apb_uart_top.v $(RTL_DIR)/apb_uart_if.v $(RTL_DIR)/uart_tx.v $(RTL_DIR)/uart_rx.v $(TB_DIR)/apb_uart_tb.sv

all: compile sim

compile:
	@echo "Compiling APB UART with iverilog..."
	iverilog -o apb_uart_sim.vvp -g2005-sv $(VERILOG_FILES) 2>&1

sim: compile
	@echo "Running simulation..."
	vvp apb_uart_sim.vvp 2>&1

wave: compile
	@echo "Note: Waveform requires GTKWave"
	vvp apb_uart_sim.vvp

clean:
	rm -f apb_uart_sim.vvp work