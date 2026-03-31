# Makefile for APB UART Cocotb Verification with Verilator

PROJECT = apb_uart
TOPLEVEL = apb_uart_top
MODULE = test_apb_uart

VERILOG_SOURCES = ../../rtl/apb_uart_top.v \
                  ../../rtl/apb_uart_if.v \
                  ../../rtl/uart_tx.v \
                  ../../rtl/uart_rx.v

VERILATOR_FLAGS = --cc --trace-fst --coverage \
                  --coverage-line --coverage-toggle --coverage-branch \
                  -DVM_COVERAGE=1

SIM ?= verilator

COCOTB_MAKEFILES = /home/fangzhen/.local/lib/python3.10/site-packages/cocotb/share/makefiles

COCOTB_PLUSARGS += +coverage

export COCOTB_COVERAGE = 1

.PHONY: all clean run coverage

all: 
	@echo "Running cocotb tests with verilator..."
	$(MAKE) clean
	MODULE=$(MODULE) TOPLEVEL=$(TOPLEVEL) VERILOG_SOURCES="$(VERILOG_SOURCES)" SIM=$(SIM) VERILATOR_FLAGS="$(VERILATOR_FLAGS)" make -f $(COCOTB_MAKEFILES)/Makefile.sim
	@echo ""
	@echo "Generating coverage report..."
	$(MAKE) coverage

coverage:
	@echo "=== Coverage Report ==="
	@verilator_coverage --annotate coverage_annotated \
		$(shell find sim_build -name "coverage.dat" -o -name "*_coverage.dat" 2>/dev/null) \
		../../rtl/*.v 2>/dev/null || echo "Note: Install gcovr for detailed coverage report"
	@echo ""
	@echo "Line coverage summary (approximate):"
	@echo "Run 'verilator_coverage --help' for detailed options"

run: all

clean::
	rm -rf __pycache__ *.pyc
	rm -rf logs/
	rm -rf $(PROJECT)*.dir/
	rm -f *.vcd *.fst coverage.dat