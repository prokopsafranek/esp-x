`timescale 1ns/1ps

module mvp_chip (
    input wire clk,
    input wire rst,
    // GPIO pins
    inout wire [9:0] gpio,
    // UART pins
    input wire uart_rx,
    output wire uart_tx,
    // SPI Flash pins
    output wire flash_cs,
    output wire flash_sclk,
    output wire flash_mosi,
    input wire flash_miso
);

    // Memory map
    // 0x00000000 - 0x000FFFFF: SRAM (1 MB)
    // 0x10000000 - 0x1000000F: UART
    // 0x10001000 - 0x1000100F: GPIO
    // 0x10002000 - 0x1000200F: PMU
    // 0x20000000 - 0x209FFFFF: Flash XIP (10 MB)

    // CPU 0 signals
    wire [31:0] cpu0_addr;
    wire [31:0] cpu0_wdata;
    wire [31:0] cpu0_rdata;
    wire cpu0_we;
    wire cpu0_re;
    wire [3:0] cpu0_be;
    
    // CPU 1 signals
    wire [31:0] cpu1_addr;
    wire [31:0] cpu1_wdata;
    wire [31:0] cpu1_rdata;
    wire cpu1_we;
    wire cpu1_re;
    wire [3:0] cpu1_be;

    // SRAM signals
    wire [31:0] sram_addr;
    wire [31:0] sram_wdata;
    wire [31:0] sram_rdata;
    wire sram_we;
    wire sram_re;
    wire [3:0] sram_be;

    // UART signals
    wire [31:0] uart_addr;
    wire [31:0] uart_wdata;
    wire [31:0] uart_rdata;
    wire uart_we;
    wire uart_re;
    wire uart_wake;

    // GPIO signals
    wire [31:0] gpio_addr;
    wire [31:0] gpio_wdata;
    wire [31:0] gpio_rdata;
    wire gpio_we;
    wire gpio_re;

    // PMU signals
    wire [31:0] pmu_addr;
    wire [31:0] pmu_wdata;
    wire [31:0] pmu_rdata;
    wire pmu_we;
    wire pmu_re;
    wire sleep_mode;

    // SPI Flash signals
    wire [31:0] flash_addr;
    wire [31:0] flash_rdata;
    wire flash_re;

    // Bus arbiter (simple round-robin between two CPUs)
    reg cpu_select;
    wire [31:0] bus_addr;
    wire [31:0] bus_wdata;
    wire [31:0] bus_rdata;
    wire bus_we;
    wire bus_re;
    wire [3:0] bus_be;

    always @(posedge clk or posedge rst) begin
        if (rst)
            cpu_select <= 1'b0;
        else
            cpu_select <= ~cpu_select;
    end

    assign bus_addr = cpu_select ? cpu1_addr : cpu0_addr;
    assign bus_wdata = cpu_select ? cpu1_wdata : cpu0_wdata;
    assign bus_we = cpu_select ? cpu1_we : cpu0_we;
    assign bus_re = cpu_select ? cpu1_re : cpu0_re;
    assign bus_be = cpu_select ? cpu1_be : cpu0_be;

    assign cpu0_rdata = bus_rdata;
    assign cpu1_rdata = bus_rdata;

    // Address decoding
    wire sel_sram = (bus_addr[31:20] == 12'h000);
    wire sel_uart = (bus_addr[31:16] == 16'h1000) && (bus_addr[15:4] == 12'h000);
    wire sel_gpio = (bus_addr[31:16] == 16'h1000) && (bus_addr[15:4] == 12'h100);
    wire sel_pmu = (bus_addr[31:16] == 16'h1000) && (bus_addr[15:4] == 12'h200);
    wire sel_flash = (bus_addr[31:24] == 8'h20);

    // Connect to peripherals
    assign sram_addr = bus_addr;
    assign sram_wdata = bus_wdata;
    assign sram_we = bus_we && sel_sram;
    assign sram_re = bus_re && sel_sram;
    assign sram_be = bus_be;

    assign uart_addr = bus_addr;
    assign uart_wdata = bus_wdata;
    assign uart_we = bus_we && sel_uart;
    assign uart_re = bus_re && sel_uart;

    assign gpio_addr = bus_addr;
    assign gpio_wdata = bus_wdata;
    assign gpio_we = bus_we && sel_gpio;
    assign gpio_re = bus_re && sel_gpio;

    assign pmu_addr = bus_addr;
    assign pmu_wdata = bus_wdata;
    assign pmu_we = bus_we && sel_pmu;
    assign pmu_re = bus_re && sel_pmu;

    assign flash_addr = bus_addr;
    assign flash_re = bus_re && sel_flash;

    // Read data mux
    assign bus_rdata = sel_sram ? sram_rdata :
                       sel_uart ? uart_rdata :
                       sel_gpio ? gpio_rdata :
                       sel_pmu ? pmu_rdata :
                       sel_flash ? flash_rdata :
                       32'h00000000;

    // CPU 0 instance (black box)
    rv32i_core cpu0 (
        .clk(clk),
        .rst(rst || sleep_mode),
        .addr(cpu0_addr),
        .wdata(cpu0_wdata),
        .rdata(cpu0_rdata),
        .we(cpu0_we),
        .re(cpu0_re),
        .be(cpu0_be)
    );

    // CPU 1 instance (black box)
    rv32i_core cpu1 (
        .clk(clk),
        .rst(rst || sleep_mode),
        .addr(cpu1_addr),
        .wdata(cpu1_wdata),
        .rdata(cpu1_rdata),
        .we(cpu1_we),
        .re(cpu1_re),
        .be(cpu1_be)
    );

    // SRAM instance
    sram_1mb sram (
        .clk(clk),
        .rst(rst),
        .addr(sram_addr[19:0]),
        .wdata(sram_wdata),
        .rdata(sram_rdata),
        .we(sram_we),
        .re(sram_re),
        .be(sram_be)
    );

    // UART instance
    uart_controller uart (
        .clk(clk),
        .rst(rst),
        .addr(uart_addr[3:0]),
        .wdata(uart_wdata),
        .rdata(uart_rdata),
        .we(uart_we),
        .re(uart_re),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .wake(uart_wake)
    );

    // GPIO instance
    gpio_controller gpio_ctrl (
        .clk(clk),
        .rst(rst),
        .addr(gpio_addr[3:0]),
        .wdata(gpio_wdata),
        .rdata(gpio_rdata),
        .we(gpio_we),
        .re(gpio_re),
        .gpio(gpio)
    );

    // PMU instance
    pmu_controller pmu (
        .clk(clk),
        .rst(rst),
        .addr(pmu_addr[3:0]),
        .wdata(pmu_wdata),
        .rdata(pmu_rdata),
        .we(pmu_we),
        .re(pmu_re),
        .uart_wake(uart_wake),
        .sleep_mode(sleep_mode)
    );

    // SPI Flash interface
    spi_flash_controller flash_ctrl (
        .clk(clk),
        .rst(rst),
        .addr(flash_addr[23:0]),
        .rdata(flash_rdata),
        .re(flash_re),
        .spi_cs(flash_cs),
        .spi_sclk(flash_sclk),
        .spi_mosi(flash_mosi),
        .spi_miso(flash_miso)
    );

endmodule