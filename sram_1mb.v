`timescale 1ns/1ps

module sram_1mb (
    input wire clk,
    input wire rst,
    input wire [19:0] addr,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    input wire we,
    input wire re,
    input wire [3:0] be
);

    // 1 MB = 262144 words (32-bit each)
    reg [31:0] mem [0:262143];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata <= 32'h00000000;
            for (i = 0; i < 262144; i = i + 1)
                mem[i] <= 32'h00000000;
        end else begin
            if (we) begin
                if (be[0]) mem[addr][7:0] <= wdata[7:0];
                if (be[1]) mem[addr][15:8] <= wdata[15:8];
                if (be[2]) mem[addr][23:16] <= wdata[23:16];
                if (be[3]) mem[addr][31:24] <= wdata[31:24];
            end
            if (re) begin
                rdata <= mem[addr];
            end
        end
    end

endmodule