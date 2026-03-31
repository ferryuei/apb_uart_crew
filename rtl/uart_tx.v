//////////////////////////////////////////////////////////////////////
// File Name: uart_tx.v
// Description: UART Transmitter module.
//              Supports 8N1 format, configurable baud rate, and 16-depth
// FIFO.
//////////////////////////////////////////////////////////////////////

module uart_tx (
    input  wire        clk,
    input  wire        rst_n,

    // Control Interface
    input  wire [15:0] baud_div,
    input  wire        fifo_clear,

    // Data Interface
    input  wire [7:0]  wr_data,
    input  wire        wr_valid,
    output wire        fifo_full,

    // UART Output
    output reg         uart_tx,
    output wire        busy
);

    localparam FIFO_DEPTH = 16;
    localparam FIFO_PTR_W = $clog2(FIFO_DEPTH);

    reg [7:0] mem [0:FIFO_DEPTH-1];
    reg [FIFO_PTR_W:0] wr_ptr;
    reg [FIFO_PTR_W:0] rd_ptr;

    wire [FIFO_PTR_W:0] count;
    wire fifo_empty;
    wire fifo_pop;

    assign count = wr_ptr - rd_ptr;
    assign fifo_full = (count == FIFO_DEPTH);
    assign fifo_empty = (count == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (fifo_clear) begin
            wr_ptr <= 0;
        end else if (wr_valid && !fifo_full) begin
            mem[wr_ptr[FIFO_PTR_W-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    reg [7:0] fifo_dout;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (fifo_clear) begin
            rd_ptr <= 0;
        end else if (fifo_pop) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    assign fifo_dout = mem[rd_ptr[FIFO_PTR_W-1:0]];

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [1:0] state;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift_reg;
    reg        tx_active;

    assign busy = (state != IDLE);
    assign fifo_pop = (state == IDLE) && !fifo_empty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            uart_tx <= 1'b1;
            baud_cnt <= 0;
            bit_idx <= 0;
            shift_reg <= 0;
            tx_active <= 0;
        end else begin
            tx_active <= 1'b0;

            case (state)
                IDLE: begin
                    uart_tx <= 1'b1;
                    baud_cnt <= 0;
                    bit_idx <= 0;
                    if (!fifo_empty) begin
                        shift_reg <= fifo_dout;
                        state <= START;
                    end
                end

                START: begin
                    uart_tx <= 1'b0;
                    tx_active <= 1'b1;
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        state <= DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                DATA: begin
                    uart_tx <= shift_reg[0];
                    tx_active <= 1'b1;
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        if (bit_idx == 7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                            shift_reg <= {1'b0, shift_reg[7:1]};
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                STOP: begin
                    uart_tx <= 1'b1;
                    tx_active <= 1'b1;
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        state <= IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule