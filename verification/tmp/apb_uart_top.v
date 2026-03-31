module apb_uart_top #(
    parameter APB_ADDR_WIDTH = 4
)(
    input  wire                    pclk,
    input  wire                    presetn,

    input  wire [APB_ADDR_WIDTH-1:0] paddr,
    input  wire                     psel,
    input  wire                     penable,
    input  wire                     pwrite,
    input  wire [31:0]              pwdata,
    output wire [31:0]              prdata,
    output wire                     pready,
    output wire                     pslverr,

    output wire                     uart_tx,
    input  wire                     uart_rx,

    output wire                     irq
);

    wire [15:0] baud_div;
    wire tx_fifo_clear;
    wire rx_fifo_clear;

    wire [7:0]  tx_data;
    wire        tx_valid;
    wire        tx_full;
    wire        tx_busy;

    wire [7:0]  rx_data;
    wire        rx_pop;
    wire        rx_empty;
    wire        rx_full;
    wire        overrun_error;

    wire        uart_rx_int;

    apb_uart_if #(
        .APB_ADDR_WIDTH(APB_ADDR_WIDTH)
    ) u_apb_if (
        .pclk(pclk),
        .presetn(presetn),
        .paddr(paddr),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr),
        .baud_div(baud_div),
        .tx_fifo_clear(tx_fifo_clear),
        .rx_fifo_clear(rx_fifo_clear),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_full(tx_full),
        .tx_busy(tx_busy),
        .rx_data(rx_data),
        .rx_pop(rx_pop),
        .rx_empty(rx_empty),
        .overrun_error(overrun_error),
        .irq(irq)
    );

    uart_tx u_uart_tx (
        .clk(pclk),
        .rst_n(presetn),
        .baud_div(baud_div),
        .fifo_clear(tx_fifo_clear),
        .wr_data(tx_data),
        .wr_valid(tx_valid),
        .fifo_full(tx_full),
        .uart_tx(uart_tx),
        .busy(tx_busy)
    );

    uart_rx u_uart_rx (
        .clk(pclk),
        .rst_n(presetn),
        .baud_div(baud_div),
        .fifo_clear(rx_fifo_clear),
        .rd_data(rx_data),
        .fifo_empty(rx_empty),
        .overrun_error(overrun_error),
        .uart_rx(uart_rx),
        .rx_pop(rx_pop)
    );

endmodule