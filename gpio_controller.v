`timescale 1ns/1ps

module gpio_controller (
    input wire clk,
    input wire rst,
    input wire [3:0] addr,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    input wire we,
    input wire re,
    inout wire [9:0] gpio
);

    // Register map
    // 0x0: GPIO output data
    // 0x4: GPIO input data
    // 0x8: GPIO direction (0=input, 1=output)

    reg [9:0] gpio_out;
    reg [9:0] gpio_in;
    reg [9:0] gpio_dir;

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : gpio_tri
            assign gpio[i] = gpio_dir[i] ? gpio_out[i] : 1'bz;
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gpio_out <= 10'h000;
            gpio_dir <= 10'h000;
            rdata <= 32'h00000000;
        end else begin
            gpio_in <= gpio;

            if (we) begin
                case (addr[3:0])
                    4'h0: gpio_out <= wdata[9:0];
                    4'h8: gpio_dir <= wdata[9:0];
                endcase
            end

            if (re) begin
                case (addr[3:0])
                    4'h0: rdata <= {22'h000000, gpio_out};
                    4'h4: rdata <= {22'h000000, gpio_in};
                    4'h8: rdata <= {22'h000000, gpio_dir};
                    default: rdata <= 32'h00000000;
                endcase
            end
        end
    end

endmodule