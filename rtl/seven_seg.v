module seven_seg(
    input clk,
    input [15:0] addr,
    input [15:0] data,
    output reg [3:0] D0_AN, output reg [7:0] D0_SEG,
    output reg [3:0] D1_AN, output reg [7:0] D1_SEG
);
    reg [18:0] counter = 0;
    always @(posedge clk) counter <= counter + 1;
    wire [1:0] sel = counter[18:17]; 
    reg [3:0] hex_addr, hex_data;

    always @(*) begin
        D0_AN = 4'b1111; D1_AN = 4'b1111;
        D0_AN[sel] = 0;  D1_AN[sel] = 0;
        
        // D1 shows Data
        case(sel)
            0: hex_data = data[3:0];   1: hex_data = data[7:4];
            2: hex_data = data[11:8];  3: hex_data = data[15:12];
        endcase
        
        // D0 shows Address (Now using all 4 digits)
        case(sel)
            0: hex_addr = addr[3:0];   1: hex_addr = addr[7:4];
            2: hex_addr = addr[11:8];  3: hex_addr = addr[15:12];
        endcase
    end

    always @(*) begin
        D0_SEG = decode_hex(hex_addr); 
        D1_SEG = decode_hex(hex_data);
    end

    function [7:0] decode_hex(input [3:0] h);
        case(h)
            4'h0: decode_hex = 8'hC0; 4'h1: decode_hex = 8'hF9; 4'h2: decode_hex = 8'hA4; 4'h3: decode_hex = 8'hB0;
            4'h4: decode_hex = 8'h99; 4'h5: decode_hex = 8'h92; 4'h6: decode_hex = 8'h82; 4'h7: decode_hex = 8'hF8;
            4'h8: decode_hex = 8'h80; 4'h9: decode_hex = 8'h90; 4'hA: decode_hex = 8'h88; 4'hB: decode_hex = 8'h83;
            4'hC: decode_hex = 8'hC6; 4'hD: decode_hex = 8'hA1; 4'hE: decode_hex = 8'h86; 4'hF: decode_hex = 8'h8E;
            default: decode_hex = 8'hFF;
        endcase
    endfunction
endmodule