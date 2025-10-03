`timescale 1ns/1ps

module tb_mvp_chip;

    reg clk;
    reg rst;
    wire [9:0] gpio;
    reg uart_rx;
    wire uart_tx;
    wire flash_cs;
    wire flash_sclk;
    wire flash_mosi;
    reg flash_miso;

    // GPIO driver
    reg [9:0] gpio_drive;
    reg [9:0] gpio_oe;

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : gpio_buf
            assign gpio[i] = gpio_oe[i] ? gpio_drive[i] : 1'bz;
        end
    endgenerate

    // Instantiate DUT
    mvp_chip dut (
        .clk(clk),
        .rst(rst),
        .gpio(gpio),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .flash_cs(flash_cs),
        .flash_sclk(flash_sclk),
        .flash_mosi(flash_mosi),
        .flash_miso(flash_miso)
    );

    // Clock generation: 100 MHz = 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        rst = 1;
        uart_rx = 1;
        flash_miso = 0;
        gpio_drive = 10'h000;
        gpio_oe = 10'h000;

        #100;
        rst = 0;

        #100;

        // Toggle some GPIO externally
        gpio_oe = 10'h00F;
        gpio_drive = 10'h005;
        #50;
        gpio_drive = 10'h00A;
        #50;

        // Send a byte via UART RX (0x55, 8N1)
        // Start bit
        uart_rx = 0;
        #8680; // One bit time at 115200 baud
        // Data bits (LSB first): 0x55 = 01010101
        uart_rx = 1; #8680;
        uart_rx = 0; #8680;
        uart_rx = 1; #8680;
        uart_rx = 0; #8680;
        uart_rx = 1; #8680;
        uart_rx = 0; #8680;
        uart_rx = 1; #8680;
        uart_rx = 0; #8680;
        // Stop bit
        uart_rx = 1; #8680;

        // Run for some cycles
        #10000;

        $display("Simulation completed successfully");
        $finish;
    end

    // Optional: Monitor signals
    initial begin
        $monitor("Time=%0t rst=%b uart_tx=%b gpio=%b", $time, rst, uart_tx, gpio);
    end

endmodule