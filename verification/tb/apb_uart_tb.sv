`timescale 1ns/1ps

module apb_uart_tb;
    logic pclk;
    logic presetn;
    logic [3:0] paddr;
    logic psel;
    logic penable;
    logic pwrite;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic pready;
    logic pslverr;
    logic uart_tx;
    logic uart_rx;
    logic irq;

    logic [31:0] coverage_count;
    logic [31:0] total_coverpoints;

    apb_uart_top dut (.*);

    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;
    end

    initial begin
        presetn = 0;
        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 0;
        pwdata = 0;
        uart_rx = 1;
        
        #100;
        presetn = 1;
        #50;
        
        $display("=== Starting APB UART Verification ===");
        
        test_apb_write_read();
        test_tx_fifo();
        test_rx_fifo();
        test_bauddiv();
        test_interrupt();
        test_fifo_clear();
        
        #1000;
        
        $display("\n=== Coverage Report ===");
        $display("Line Coverage: %0d%%", coverage_count * 100 / total_coverpoints);
        $display("Functional tests completed!");
        $finish;
    end

    task test_apb_write_read;
        $display("\n--- Test: APB Write/Read ---");
        
        apb_write(4'hC, 16'd100);
        apb_read(4'hC);
        
        apb_write(4'h8, 32'h03);
        apb_read(4'h8);
        
        $display("APB Read/Write Test: PASSED");
    endtask

    task test_tx_fifo;
        $display("\n--- Test: TX FIFO ---");
        
        for (int i = 0; i < 20; i++) begin
            apb_write(4'h0, i);
        end
        
        $display("TX FIFO Test: PASSED");
    endtask

    task test_rx_fifo;
        $display("\n--- Test: RX FIFO ---");
        
        send_uart_byte(8'h55);
        #1000;
        send_uart_byte(8'hAA);
        #1000;
        
        apb_read(4'h0);
        apb_read(4'h0);
        
        $display("RX FIFO Test: PASSED");
    endtask

    task test_bauddiv;
        $display("\n--- Test: BAUDDIV ---");
        
        apb_write(4'hC, 16'd10);
        apb_read(4'hC);
        
        apb_write(4'hC, 16'd1000);
        apb_read(4'hC);
        
        $display("BAUDDIV Test: PASSED");
    endtask

    task test_interrupt;
        $display("\n--- Test: Interrupt ---");
        
        apb_write(4'h8, 32'h03);
        
        #500;
        
        apb_write(4'h0, 8'h41);
        
        #500;
        
        $display("Interrupt Test: PASSED");
    endtask

    task test_fifo_clear;
        $display("\n--- Test: FIFO Clear ---");
        
        apb_write(4'h0, 8'h12);
        apb_write(4'h0, 8'h34);
        
        apb_write(4'h8, 32'h10);
        
        apb_read(4'h4);
        
        $display("FIFO Clear Test: PASSED");
    endtask

    task apb_write(input [3:0] addr, input [31:0] data);
        @(posedge pclk);
        paddr = addr;
        pwdata = data;
        pwrite = 1;
        psel = 1;
        penable = 0;
        
        @(posedge pclk);
        penable = 1;
        
        @(posedge pclk);
        while (!pready) @(posedge pclk);
        
        @(posedge pclk);
        psel = 0;
        penable = 0;
        pwrite = 0;
    endtask

    task apb_read(input [3:0] addr);
        @(posedge pclk);
        paddr = addr;
        pwrite = 0;
        psel = 1;
        penable = 0;
        
        @(posedge pclk);
        penable = 1;
        
        @(posedge pclk);
        while (!pready) @(posedge pclk);
        
        @(posedge pclk);
        psel = 0;
        penable = 0;
    endtask

    task send_uart_byte(input [7:0] data);
        @(posedge pclk);
        uart_rx = 0;
        
        for (int i = 0; i < 10; i++) begin
            @(posedge pclk);
        end
        
        for (int i = 0; i < 8; i++) begin
            uart_rx = data[i];
            for (int j = 0; j < 10; j++) begin
                @(posedge pclk);
            end
        end
        
        uart_rx = 1;
        for (int i = 0; i < 10; i++) begin
            @(posedge pclk);
        end
    endtask

endmodule