`timescale 1ns/1ps

module pmu_controller (
    input wire clk,
    input wire rst,
    input wire [3:0] addr,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    input wire we,
    input wire re,
    input wire uart_wake,
    output reg sleep_mode
);

    // Register map
    // 0x0: Sleep control (bit 0: enter sleep)
    // 0x4: Wake status (bit 0: UART wake)

    reg sleep_req;
    reg wake_status;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sleep_mode <= 1'b0;
            sleep_req <= 1'b0;
            wake_status <= 1'b0;
            rdata <= 32'h00000000;
        end else begin
            if (uart_wake) begin
                sleep_mode <= 1'b0;
                wake_status <= 1'b1;
            end

            if (we) begin
                case (addr[3:0])
                    4'h0: begin
                        sleep_req <= wdata[0];
                        if (wdata[0])
                            sleep_mode <= 1'b1;
                    end
                endcase
            end

            if (re) begin
                case (addr[3:0])
                    4'h0: rdata <= {31'h00000000, sleep_mode};
                    4'h4: rdata <= {31'h00000000, wake_status};
                    default: rdata <= 32'h00000000;
                endcase
                if (addr[3:0] == 4'h4)
                    wake_status <= 1'b0;
            end
        end
    end

endmodule