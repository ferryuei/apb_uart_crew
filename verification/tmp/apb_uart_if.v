module apb_uart_if #(
    parameter APB_ADDR_WIDTH = 4
)(
    input  wire                    pclk,
    input  wire                    presetn,

    input  wire [APB_ADDR_WIDTH-1:0] paddr,
    input  wire                     psel,
    input  wire                     penable,
    input  wire                     pwrite,
    input  wire [31:0]              pwdata,
    output reg  [31:0]              prdata,
    output reg                      pready,
    output reg                      pslverr,

    output wire [15:0]              baud_div,
    output wire                     tx_fifo_clear,
    output wire                     rx_fifo_clear,

    output wire [7:0]               tx_data,
    output wire                     tx_valid,
    input  wire                     tx_full,
    input  wire                     tx_busy,

    input  wire [7:0]               rx_data,
    output wire                     rx_pop,
    input  wire                     rx_empty,
    input  wire                     overrun_error,

    output wire                     irq
);

    localparam ADDR_RXDATA   = 4'h0;
    localparam ADDR_TXDATA   = 4'h0;
    localparam ADDR_STATUS   = 4'h4;
    localparam ADDR_CTRL     = 4'h8;
    localparam ADDR_BAUDDIV  = 4'hC;

    reg [15:0] baud_div_reg;
    reg        tx_irq_en;
    reg        rx_irq_en;

    wire [31:0] status_reg;
    assign status_reg = {28'b0, overrun_error, tx_busy, tx_full, rx_empty};

    wire tx_irq_trigger = tx_irq_en && !tx_full;
    wire rx_irq_trigger = rx_irq_en && !rx_empty;
    assign irq = tx_irq_trigger | rx_irq_trigger;

    wire apb_write = psel && penable && pwrite;
    wire apb_read  = psel && penable && !pwrite;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            pready <= 1'b1;
        end else begin
            pready <= 1'b1;
        end
    end

    assign pslverr = 1'b0;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            baud_div_reg <= 16'd1;
            tx_irq_en <= 1'b0;
            rx_irq_en <= 1'b0;
        end else if (apb_write) begin
            case (paddr)
                ADDR_CTRL: begin
                    tx_irq_en <= pwdata[0];
                    rx_irq_en <= pwdata[1];
                end
                ADDR_BAUDDIV: begin
                    baud_div_reg <= pwdata[15:0];
                end
                default: ;
            endcase
        end
    end

    assign baud_div = baud_div_reg;

    reg tx_valid_reg;
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) tx_valid_reg <= 0;
        else tx_valid_reg <= apb_write && (paddr == ADDR_TXDATA);
    end

    assign tx_data  = pwdata[7:0];
    assign tx_valid = tx_valid_reg;

    assign tx_fifo_clear = apb_write && (paddr == ADDR_CTRL) && pwdata[4];
    assign rx_fifo_clear = apb_write && (paddr == ADDR_CTRL) && pwdata[5];

    reg [31:0] prdata_n;
    always @(*) begin
        prdata_n = 32'b0;
        if (apb_read) begin
            case (paddr)
                ADDR_RXDATA: begin
                    prdata_n = {24'b0, rx_data};
                end
                ADDR_STATUS: begin
                    prdata_n = status_reg;
                end
                ADDR_CTRL: begin
                    prdata_n = {30'b0, rx_irq_en, tx_irq_en};
                end
                ADDR_BAUDDIV: begin
                    prdata_n = {16'b0, baud_div_reg};
                end
                default: prdata_n = 32'b0;
            endcase
        end
    end

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) prdata <= 0;
        else prdata <= prdata_n;
    end

    assign rx_pop = apb_read && (paddr == ADDR_RXDATA);

endmodule