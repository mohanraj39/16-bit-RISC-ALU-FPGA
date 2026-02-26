module uart_rx #(parameter CLK_FREQ = 100_000_000, parameter BAUD_RATE = 9600) (
    input clk,
    input rst,        // Added reset
    input rx,
    output reg [7:0] data_out,
    output reg rx_done
);
    localparam WAIT_COUNT = CLK_FREQ / BAUD_RATE;
    
    // --- 2-Flop Synchronizer ---
    reg rx_sync1, rx_sync2;
    always @(posedge clk) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;       // First stage
            rx_sync2 <= rx_sync1; // Second stage (safe to use)
        end
    end

    reg [31:0] count = 0;
    reg [3:0] bit_idx = 0;
    reg [1:0] state = 0;

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            rx_done <= 0;
            count <= 0;
        end else begin
            rx_done <= 0;
            case (state)
                0: begin // Idle: Wait for start bit (0)
                    count <= 0;
                    bit_idx <= 0;
                    if (rx_sync2 == 0) state <= 1; // Use synchronized signal
                end
                1: begin // Start bit
                    if (count == WAIT_COUNT / 2) begin
                        count <= 0;
                        state <= 2;
                    end else count <= count + 1;
                end
                2: begin // Data bits
                    if (count == WAIT_COUNT) begin
                        count <= 0;
                        data_out[bit_idx] <= rx_sync2; // Use synchronized signal
                        if (bit_idx == 7) state <= 3;
                        else bit_idx <= bit_idx + 1;
                    end else count <= count + 1;
                end
                3: begin // Stop bit
                    if (count == WAIT_COUNT) begin
                        rx_done <= 1;
                        state <= 0;
                    end else count <= count + 1;
                end
            endcase
        end
    end
endmodule