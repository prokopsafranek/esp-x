`timescale 1ns/1ps

module uart_controller (
    input wire clk,
    input wire rst,
    input wire [3:0] addr,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    input wire we,
    input wire re,
    input wire uart_rx,
    output reg uart_tx,
    output reg wake
);

    // Register map
    // 0x0: TX data
    // 0x4: RX data
    // 0x8: Status (bit 0: TX busy, bit 1: RX ready)

    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg tx_busy;
    reg rx_ready;
    reg [3:0] tx_bit_cnt;
    reg [3:0] rx_bit_cnt;
    reg [9:0] tx_shift;
    reg [9:0] rx_shift;
    reg [15:0] baud_cnt;
    reg rx_prev;

    // Simple baud rate: 100 MHz / 115200 = 868 clocks per bit
    parameter BAUD_DIV = 868;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata <= 32'h00000000;
            tx_data <= 8'h00;
            rx_data <= 8'h00;
            tx_busy <= 1'b0;
            rx_ready <= 1'b0;
            tx_bit_cnt <= 4'h0;
            rx_bit_cnt <= 4'h0;
            tx_shift <= 10'h3FF;
            rx_shift <= 10'h000;
            baud_cnt <= 16'h0000;
            uart_tx <= 1'b1;
            wake <= 1'b0;
            rx_prev <= 1'b1;
        end else begin
            wake <= 1'b0;

            // Write handling
            if (we) begin
                case (addr[3:0])
                    4'h0: begin
                        tx_data <= wdata[7:0];
                        tx_busy <= 1'b1;
                        tx_shift <= {1'b1, wdata[7:0], 1'b0}; // Stop, data, start
                        tx_bit_cnt <= 4'd10;
                        baud_cnt <= 16'h0000;
                    end
                endcase
            end

            // Read handling
            if (re) begin
                case (addr[3:0])
                    4'h0: rdata <= {24'h000000, tx_data};
                    4'h4: rdata <= {24'h000000, rx_data};
                    4'h8: rdata <= {30'h00000000, rx_ready, tx_busy};
                    default: rdata <= 32'h00000000;
                endcase
            end

            // TX logic
            if (tx_busy) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 16'h0000;
                    uart_tx <= tx_shift[0];
                    tx_shift <= {1'b1, tx_shift[9:1]};
                    tx_bit_cnt <= tx_bit_cnt - 1;
                    if (tx_bit_cnt == 4'd1)
                        tx_busy <= 1'b0;
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end else begin
                uart_tx <= 1'b1;
            end

            // RX logic (simplified start bit detection)
            rx_prev <= uart_rx;
            if (!uart_rx && rx_prev && !rx_ready && rx_bit_cnt == 4'h0) begin
                rx_bit_cnt <= 4'd10;
                baud_cnt <= 16'h0000;
                wake <= 1'b1;
            end

            if (rx_bit_cnt > 0) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 16'h0000;
                    rx_shift <= {uart_rx, rx_shift[9:1]};
                    rx_bit_cnt <= rx_bit_cnt - 1;
                    if (rx_bit_cnt == 4'd1) begin
                        rx_data <= rx_shift[8:1];
                        rx_ready <= 1'b1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end

            // Clear RX ready on read
            if (re && addr[3:0] == 4'h4)
                rx_ready <= 1'b0;
        end
    end

endmodule