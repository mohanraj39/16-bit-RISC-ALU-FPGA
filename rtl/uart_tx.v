module uart_tx #(parameter CLK_FREQ = 100_000_000, parameter BAUD_RATE = 9600) (
    input clk,
    input [7:0] tx_data,
    input tx_start,
    output tx,
    output tx_busy
);
    localparam WAIT_COUNT = CLK_FREQ / BAUD_RATE;
    reg [31:0] count = 0;
    reg [3:0] bit_idx = 0;
    reg [1:0] state = 0;
    reg [7:0] buffer;
    reg tx_reg = 1;

    assign tx = tx_reg;
    // CRITICAL: Busy must be high the moment start is triggered
    assign tx_busy = (state != 0) || tx_start;

    always @(posedge clk) begin
        case (state)
            0: begin
                tx_reg <= 1;
                if (tx_start) begin
                    buffer <= tx_data;
                    state <= 1;
                    count <= 0;
                end
            end
            1: begin // Start
                tx_reg <= 0;
                if (count >= WAIT_COUNT-1) begin count <= 0; state <= 2; bit_idx <= 0; end
                else count <= count + 1;
            end
            2: begin // Data
                tx_reg <= buffer[bit_idx];
                if (count >= WAIT_COUNT-1) begin
                    count <= 0;
                    if (bit_idx == 7) state <= 3;
                    else bit_idx <= bit_idx + 1;
                end else count <= count + 1;
            end
            3: begin // Stop
                tx_reg <= 1;
                if (count >= WAIT_COUNT-1) state <= 0;
                else count <= count + 1;
            end
        endcase
    end
endmodule