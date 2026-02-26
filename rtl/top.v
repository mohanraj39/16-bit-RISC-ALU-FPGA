module top(
    input clk,
    input rst,        // NEW: Reset input (Map to a button on your board)
    input UART_rxd,
    output UART_txd,
    output [3:0] D0_AN, output [7:0] D0_SEG,  
    output [3:0] D1_AN, output [7:0] D1_SEG,
    output led
);
    // UART Logic
    wire [7:0] rx_data;
    wire rx_done_raw;
    reg [7:0] tx_data_reg;
    reg tx_start_reg;
    wire tx_busy;

    // Edge Detector
    reg rx_done_prev;
    wire rx_done = (rx_done_raw && !rx_done_prev);
    always @(posedge clk) begin
        if (rst) rx_done_prev <= 0;
        else rx_done_prev <= rx_done_raw;
    end

    // Memory
    reg [15:0] registers [0:1023]; 
    integer i;
    // Initial remains for simulation/power-on, but Reset provides a hardware clear
    initial for (i = 0; i < 1024; i = i + 1) registers[i] = 16'h0;
    
    // States
    reg [5:0] state = 0;
    reg [5:0] return_state = 0;
    localparam IDLE=0, GET_ADDR1=1, GET_DATA=2, EXECUTE_W=3, 
               TX_D=4, TX_SPACE=5, TX_HEX1=6, TX_HEX2=7, TX_HEX3=8, TX_HEX4=9, 
               WAIT_UART=10, GET_ADDR2=11, READ_1=12, READ_2=13, READ_3=14, 
               CALC=15, GET_ADDR_DEST=16, EXECUTE_ALU_WRITE=17,
               TX_FSPACE=18, TX_Z_L=19, TX_Z_V=20, TX_S_L=21, TX_S_V=22,
               TX_C_L=23, TX_C_V=24, TX_V_L=25, TX_V_V=26, TX_NL=27;

    reg [15:0] addr1, addr2, addr_dest, data_reg, op1, op2, val_out, addr_disp;
    reg [7:0] active_cmd;
    reg z_r, s_r, c_r, v_r; 
    reg [2:0] alu_op; 

    // ALU instantiation
    wire [15:0] alu_res;
    wire alu_z, alu_s, alu_c, alu_v;
    alu core_alu (.A(op1), .B(op2), .opcode(alu_op), .Result(alu_res), .Z(alu_z), .S(alu_s), .C(alu_c), .V(alu_v));

    // Helpers
    function is_hex(input [7:0] a); is_hex = (a >= "0" && a <= "9") || (a >= "A" && a <= "F") || (a >= "a" && a <= "f"); endfunction
    function [3:0] to_hex(input [7:0] a);
        if (a >= "0" && a <= "9") to_hex = a[3:0]; else if (a >= "A" && a <= "F") to_hex = a - 8'h37; else to_hex = a - 8'h57;
    endfunction
    function [7:0] to_ascii(input [3:0] h); to_ascii = (h < 10) ? (8'h30 + h) : (8'h57 + h); endfunction

    always @(posedge clk) begin
        if (rst) begin
            // --- Reset Logic ---
            state <= IDLE;
            tx_start_reg <= 0;
            addr1 <= 0; addr2 <= 0; addr_dest <= 0; data_reg <= 0;
            val_out <= 0; z_r <= 0; s_r <= 0; c_r <= 0; v_r <= 0;
            alu_op <= 0;
        end else begin
            tx_start_reg <= 0;
            if (rx_done) begin
                if (rx_data == "W" || rx_data == "w" || rx_data == "R" || rx_data == "r" || 
                    rx_data == "S" || rx_data == "s" || rx_data == "U" || rx_data == "u" || 
                    rx_data == "X" || rx_data == "x" || rx_data == "N" || rx_data == "n" ||
                    rx_data == "O" || rx_data == "o" || rx_data == "T" || rx_data == "t") begin
                    
                    active_cmd <= rx_data;
                    case (rx_data)
                        "S", "s": alu_op <= 3'b000; "U", "u": alu_op <= 3'b001;
                        "N", "n": alu_op <= 3'b010; "O", "o": alu_op <= 3'b011;
                        "X", "x": alu_op <= 3'b100; "T", "t": alu_op <= 3'b101;
                        default:  alu_op <= 3'b000;
                    endcase
                    addr1 <= 0; addr2 <= 0; addr_dest <= 0; data_reg <= 0;
                    tx_data_reg <= "#"; tx_start_reg <= 1; state <= GET_ADDR1;
                end 
                else begin
                    case (state)
                        GET_ADDR1: if (rx_data == 8'h0D || rx_data == " ") begin
                                       addr_disp <= addr1;
                                       if (active_cmd == "W" || active_cmd == "w") state <= GET_DATA;
                                       else if (active_cmd == "R" || active_cmd == "r") state <= READ_1;
                                       else state <= GET_ADDR2;
                                   end else if (is_hex(rx_data)) addr1 <= {addr1[11:0], to_hex(rx_data)};
                        GET_ADDR2: if (rx_data == 8'h0D || rx_data == " ") begin
                                       if (active_cmd == "T" || active_cmd == "t") begin addr_dest <= addr2; state <= READ_1; end
                                       else state <= GET_ADDR_DEST;
                                   end else if (is_hex(rx_data)) addr2 <= {addr2[11:0], to_hex(rx_data)};
                        GET_ADDR_DEST: if (rx_data == 8'h0D) state <= READ_1;
                                       else if (is_hex(rx_data)) addr_dest <= {addr_dest[11:0], to_hex(rx_data)};
                        GET_DATA: if (rx_data == 8'h0D) state <= EXECUTE_W;
                                  else if (is_hex(rx_data)) data_reg <= {data_reg[11:0], to_hex(rx_data)};
                    endcase
                end
            end

            case (state)
                EXECUTE_W: begin registers[addr1[9:0]] <= data_reg; val_out <= data_reg; state <= IDLE; end
                READ_1: state <= READ_2;
                READ_2: begin op1 <= registers[addr1[9:0]]; state <= (active_cmd == "R" || active_cmd == "r") ? TX_D : READ_3; end
                READ_3: begin op2 <= registers[addr2[9:0]]; state <= CALC; end
                CALC: begin
                    val_out <= alu_res; z_r <= alu_z; s_r <= alu_s; c_r <= alu_c; v_r <= alu_v;
                    state <= (active_cmd == "R" || active_cmd == "r") ? TX_D : EXECUTE_ALU_WRITE;
                end
                EXECUTE_ALU_WRITE: begin registers[addr_dest[9:0]] <= val_out; state <= TX_D; end
                
                TX_D:     begin tx_data_reg <= "d"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_SPACE; end
                TX_SPACE: begin tx_data_reg <= " "; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_HEX1; end
                TX_HEX1:  begin tx_data_reg <= to_ascii(val_out[15:12]); tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_HEX2; end
                TX_HEX2:  begin tx_data_reg <= to_ascii(val_out[11:8]);  tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_HEX3; end
                TX_HEX3:  begin tx_data_reg <= to_ascii(val_out[7:4]);   tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_HEX4; end
                TX_HEX4:  begin tx_data_reg <= to_ascii(val_out[3:0]);   tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_FSPACE; end
                TX_FSPACE:begin tx_data_reg <= " "; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_Z_L; end
                TX_Z_L:   begin tx_data_reg <= "Z"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_Z_V; end
                TX_Z_V:   begin tx_data_reg <= z_r ? "1" : "0"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_S_L; end
                TX_S_L:   begin tx_data_reg <= "S"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_S_V; end
                TX_S_V:   begin tx_data_reg <= s_r ? "1" : "0"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_C_L; end
                TX_C_L:   begin tx_data_reg <= "C"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_C_V; end
                TX_C_V:   begin tx_data_reg <= c_r ? "1" : "0"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_V_L; end
                TX_V_L:   begin tx_data_reg <= "V"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_V_V; end
                TX_V_V:   begin tx_data_reg <= v_r ? "1" : "0"; tx_start_reg <= 1; state <= WAIT_UART; return_state <= TX_NL;  end
                TX_NL:    begin tx_data_reg <= 8'h0A; tx_start_reg <= 1; state <= WAIT_UART; return_state <= IDLE; end
                WAIT_UART: if (!tx_busy && !tx_start_reg) state <= return_state;
                IDLE: ;
            endcase
        end
    end

    // Updated Instantiations with Reset
    uart_rx receiver (.clk(clk), .rst(rst), .rx(UART_rxd), .data_out(rx_data), .rx_done(rx_done_raw));
    uart_tx transmitter (.clk(clk), .tx_data(tx_data_reg), .tx_start(tx_start_reg), .tx(UART_txd), .tx_busy(tx_busy));
    seven_seg display_mod (.clk(clk), .addr(addr_disp), .data(val_out), .D0_AN(D0_AN), .D0_SEG(D0_SEG), .D1_AN(D1_AN), .D1_SEG(D1_SEG));
    assign led = (state != IDLE);
endmodule