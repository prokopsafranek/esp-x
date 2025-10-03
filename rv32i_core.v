`timescale 1ns/1ps

// Black box placeholder for RV32I core
module rv32i_core (
    input wire clk,
    input wire rst,
    output reg [31:0] addr,
    output reg [31:0] wdata,
    input wire [31:0] rdata,
    output reg we,
    output reg re,
    output reg [3:0] be
);

    // 2-stage pipeline states
    reg [31:0] pc;
    reg [31:0] instruction;
    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'h00000000;
            addr <= 32'h00000000;
            wdata <= 32'h00000000;
            we <= 1'b0;
            re <= 1'b0;
            be <= 4'b1111;
            instruction <= 32'h00000013; // NOP
            state <= 2'b00;
        end else begin
            case (state)
                2'b00: begin // Fetch
                    addr <= pc;
                    re <= 1'b1;
                    we <= 1'b0;
                    state <= 2'b01;
                end
                2'b01: begin // Execute
                    instruction <= rdata;
                    re <= 1'b0;
                    pc <= pc + 4;
                    state <= 2'b00;
                end
                default: state <= 2'b00;
            endcase
        end
    end

endmodule