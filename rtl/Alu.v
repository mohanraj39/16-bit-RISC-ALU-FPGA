module alu(
    input [15:0] A,
    input [15:0] B,
    input [2:0] opcode, 
    output reg [15:0] Result,
    output Z, S, C, V
);
    reg carry_out;
    
    always @(*) begin
        carry_out = 0;
        case(opcode)
            3'b000: {carry_out, Result} = A + B;       // ADD
            3'b001: {carry_out, Result} = A - B;       // SUB
            3'b010: Result = A & B;                    // AND
            3'b011: Result = A | B;                    // OR
            3'b100: Result = A ^ B;                    // XOR
            3'b101: Result = ~A;                       // NOT
            default: Result = 16'h0;
        endcase
    end

    // Flag Generation
    assign Z = (Result == 16'h0);                      
    assign S = Result[15];                             
    assign C = (opcode == 3'b000 || opcode == 3'b001) ? carry_out : 0;
    
    // Signed Overflow (V) logic
    assign V = (opcode == 3'b000) ? ((A[15] == B[15]) && (Result[15] != A[15])) :
               (opcode == 3'b001) ? ((A[15] != B[15]) && (Result[15] != A[15])) : 0;
endmodule