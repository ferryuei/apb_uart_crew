module uart_rx (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [15:0] baud_div,
    input  wire        fifo_clear,

    output wire [7:0]  rd_data,
    output wire        fifo_empty,
    output wire        overrun_error,

    input  wire        uart_rx,
    input  wire        rx_pop
);

    localparam FIFO_DEPTH = 16;
    localparam FIFO_PTR_W = $clog2(FIFO_DEPTH);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift_reg;

    reg [1:0] rx_sync;
    wire rx_fall;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_sync <= 2'b11;
        else rx_sync <= {rx_sync[0], uart_rx};
    end

    assign rx_fall = (rx_sync[1] && !rx_sync[0]);

    reg [7:0] mem [0:FIFO_DEPTH-1];
    reg [FIFO_PTR_W:0] wr_ptr;
    reg [FIFO_PTR_W:0] rd_ptr;

    wire [FIFO_PTR_W:0] count;
    wire fifo_full;
    wire fifo_push;

    assign count = wr_ptr - rd_ptr;
    assign fifo_full = (count == FIFO_DEPTH);
    assign fifo_empty = (count == 0);
    assign rd_data = mem[rd_ptr[FIFO_PTR_W-1:0]];

    reg overrun_error_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            overrun_error_reg <= 0;
        end else if (fifo_clear) begin
            wr_ptr <= 0;
            overrun_error_reg <= 0;
        end else if (fifo_push) begin
            if (fifo_full) begin
                overrun_error_reg <= 1'b1;
            end else begin
                mem[wr_ptr[FIFO_PTR_W-1:0]] <= shift_reg;
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end

    assign overrun_error = overrun_error_reg;

    reg [FIFO_PTR_W:0] rd_ptr_next;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (fifo_clear) begin
            rd_ptr <= 0;
        end else begin
            rd_ptr <= rd_ptr_next;
        end
    end

    always @(*) begin
        if (rx_pop && !fifo_empty)
            rd_ptr_next = rd_ptr + 1;
        else
            rd_ptr_next = rd_ptr;
    end

    assign fifo_push = (state == STOP) && (baud_cnt >= baud_div - 1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            baud_cnt <= 0;
            bit_idx <= 0;
            shift_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    baud_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_fall) begin
                        state <= START;
                    end
                end

                START: begin
                    if (baud_cnt >= (baud_div >> 1)) begin
                        if (rx_sync[0] == 1'b0) begin
                            baud_cnt <= 0;
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                DATA: begin
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        shift_reg <= {rx_sync[0], shift_reg[7:1]};
                        if (bit_idx == 7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                STOP: begin
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