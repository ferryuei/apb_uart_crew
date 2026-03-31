interface uart_if(input logic clk);
    logic uart_tx;
    logic uart_rx;
    logic irq;

    clocking cb_driver @(posedge clk);
        output  uart_rx;
        input   uart_tx, irq;
    endclocking

    clocking cb_monitor @(posedge clk);
        input uart_tx, uart_rx, irq;
    endclocking

    modport mp_driver (clocking cb_driver);
    modport mp_monitor (clocking cb_monitor);
endinterface : uart_if