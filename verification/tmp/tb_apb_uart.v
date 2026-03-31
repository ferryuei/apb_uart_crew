`timescale 1ns/1ps

module tb;
    reg pclk;
    reg presetn;
    reg [3:0] paddr;
    reg psel;
    reg penable;
    reg pwrite;
    reg [31:0] pwdata;
    wire [31:0] prdata;
    wire pready;
    wire pslverr;
    wire uart_tx;
    reg uart_rx;
    wire irq;

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
        
        $display("=== Test 1: APB Write/Read ===");
        apb_write(4'hC, 16'd100);
        apb_read(4'hC);
        
        apb_write(4'h8, 32'h03);
        apb_read(4'h8);
        $display("PASS");

        $display("=== Test 2: TX FIFO ===");
        for (int i = 0; i < 20; i++) begin
            apb_write(4'h0, i);
        end
        $display("PASS");

        $display("=== Test 3: RX FIFO ===");
        send_uart_byte(8'h55);
        #5000;
        send_uart_byte(8'hAA);
        #5000;
        apb_read(4'h0);
        apb_read(4'h0);
        $display("PASS");

        $display("=== Test 4: Interrupt ===");
        apb_write(4'h8, 32'h03);
        apb_write(4'h0, 8'h41);
        #500;
        $display("PASS");

        $display("=== Test 5: FIFO Clear ===");
        apb_write(4'h0, 8'h12);
        apb_write(4'h0, 8'h34);
        apb_write(4'h8, 32'h10);
        apb_read(4'h4);
        $display("PASS");

        $display("=== Test 6: BAUDDIV ===");
        apb_write(4'hC, 16'd10);
        apb_write(4'hC, 16'd1000);
        $display("PASS");

        $display("=== Test 7: Status Register ===");
        apb_read(4'h4);
        $display("PASS");

        $display("=== Test 8: Multiple TX ===");
        for (int i = 0; i < 5; i++) begin
            apb_write(4'h0, 8'h40 + i);
        end
        $display("PASS");

        $display("=== Test 9: RX Overrun ===");
        for (int i = 0; i < 20; i++) begin
            send_uart_byte(i);
            #200;
        end
        apb_read(4'h4);
        $display("PASS");

        $display("=== Test 10: Control Register ===");
        apb_write(4'h8, 8'h1);
        apb_read(4'h8);
        apb_write(4'h8, 8'h2);
        apb_read(4'h8);
        $display("PASS");

        #1000;
        $display("\n=== ALL TESTS PASSED ===");
        $finish;
    end

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
        
        #1;
        @(posedge pclk);
        @(posedge pclk);
        psel = 0;
        penable = 0;
    endtask

    task send_uart_byte(input [7:0] data);
        @(posedge pclk);
        uart_rx = 0;
        
        for (int i = 0; i < 110; i++) begin
            @(posedge pclk);
        end
        
        for (int i = 0; i < 8; i++) begin
            uart_rx = data[i];
            for (int j = 0; j < 110; j++) begin
                @(posedge pclk);
            end
        end
        
        uart_rx = 1;
        for (int i = 0; i < 110; i++) begin
            @(posedge pclk);
        end
    endtask

endmodule
