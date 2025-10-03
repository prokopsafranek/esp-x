`timescale 1ns/1ps

module spi_flash_controller (
    input wire clk,
    input wire rst,
    input wire [23:0] addr,
    output reg [31:0] rdata,
    input wire re,
    output reg spi_cs,
    output reg spi_sclk,
    output reg spi_mosi,
    input wire spi_miso
);

    // SPI states
    localparam IDLE = 3'd0;
    localparam CMD = 3'd1;
    localparam ADDR = 3'd2;
    localparam READ = 3'd3;
    localparam DONE = 3'd4;

    reg [2:0] state;
    reg [5:0] bit_cnt;
    reg [7:0] cmd;
    reg [23:0] addr_buf;
    reg [31:0] data_buf;
    reg sclk_en;

    // Read command for SPI Flash: 0x03
    parameter READ_CMD = 8'h03;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            spi_cs <= 1'b1;
            spi_sclk <= 1'b0;
            spi_mosi <= 1'b0;
            rdata <= 32'h00000000;
            bit_cnt <= 6'd0;
            cmd <= 8'h00;
            addr_buf <= 24'h000000;
            data_buf <= 32'h00000000;
            sclk_en <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    spi_cs <= 1'b1;
                    spi_sclk <= 1'b0;
                    sclk_en <= 1'b0;
                    if (re) begin
                        spi_cs <= 1'b0;
                        cmd <= READ_CMD;
                        addr_buf <= addr;
                        bit_cnt <= 6'd8;
                        state <= CMD;
                        sclk_en <= 1'b1;
                    end
                end
                CMD: begin
                    spi_sclk <= ~spi_sclk;
                    if (spi_sclk) begin
                        spi_mosi <= cmd[7];
                        cmd <= {cmd[6:0], 1'b0};
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 6'd1) begin
                            bit_cnt <= 6'd24;
                            state <= ADDR;
                        end
                    end
                end
                ADDR: begin
                    spi_sclk <= ~spi_sclk;
                    if (spi_sclk) begin
                        spi_mosi <= addr_buf[23];
                        addr_buf <= {addr_buf[22:0], 1'b0};
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 6'd1) begin
                            bit_cnt <= 6'd32;
                            state <= READ;
                        end
                    end
                end
                READ: begin
                    spi_sclk <= ~spi_sclk;
                    if (!spi_sclk) begin
                        data_buf <= {data_buf[30:0], spi_miso};
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 6'd1) begin
                            state <= DONE;
                        end
                    end
                end
                DONE: begin
                    spi_cs <= 1'b1;
                    spi_sclk <= 1'b0;
                    rdata <= data_buf;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule