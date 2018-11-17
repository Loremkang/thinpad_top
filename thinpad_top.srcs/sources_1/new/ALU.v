`default_nettype wire

`define ADDU    6'b100001
`define AND     6'b100100
`define SUB     6'b100010
`define OR      6'b100101
`define SLL     6'b000000
`define SRL     6'b000010
`define XOR     6'b100110
`define CLZ     6'b100000
`define NOR     6'b100111


module ALU(
    input [31:0] A,
    input [31:0] B,
    input [2:0] ALUOp,
    input [5:0] Func,
    output reg [31:0] result,
    output wire Zero
    );
    /*initial begin
        result = 0;
    end*/
    reg [31:0] RTypeOut;
    reg [31:0] CLZOut;
    reg [15:0] val16;
    reg [7:0] val8;
    reg [3:0] val4;
    
    always @(A, B) begin
        CLZOut = 0;
        CLZOut[5] = (A == 0);
        CLZOut[4] = (A[31:16] == 16'b0);
        val16 = CLZOut[4] ? A[15:0] : A[31:16];
        CLZOut[3] = (val16[15:8] == 8'b0);
        val8 = CLZOut[3] ? val16[7:0] : val16[15:8];
        CLZOut[2] = (val8[7:4] == 4'b0);
        val4 = CLZOut[2] ? val8[3:0] : val8[7:4];
        CLZOut[1] = (val4[3:2] == 2'b0);
        CLZOut[0] = CLZOut[1] ? ~val4[1] : ~val4[3];
    end
    
    always @(A, B, Func) begin
        case (Func)
            `ADDU: RTypeOut = A + B;
            `AND: RTypeOut = A & B;
            `CLZ: RTypeOut = CLZOut;
            `NOR: RTypeOut = ~(A | B);
            `OR: RTypeOut = A | B;
            `SLL: RTypeOut = B << (A[10:6]);
            `SRL: RTypeOut = B >> (A[10:6]);
            `SUB: RTypeOut = A - B;
            `XOR: RTypeOut = A ^ B;
            default: RTypeOut = 0;
        endcase
    end
        
    /*always @(A, B, Func) begin
        case(Func)
            `ADDU: RTypeOut = A + B;
            `AND: RTypeOut = A & B;
            `CLZ: RTypeOut = A + B; // to do
            `NOR: RTypeOut = ~(A | B);
            `OR: RTypeOut = A | B;
            `SLL: RTypeOut = B << (A[10:6]);
            `SRL: RTypeOut = B >> (A[10:6]);
            `SUB: RTypeOut = A - B;
            `XOR: RTypeOut = A ^ B;
            default: RTypeOut = 0;
        endcase;
    end*/
    
    always @(A, B, ALUOp, result) begin
        case(ALUOp)
            3'b001: result = A + B;
            3'b010: result = A & B;
            3'b011: result = A | B;
            3'b100: result = A ^ B;
            3'b101: result = RTypeOut;
            3'b111: result = RTypeOut;
            default: result = 0;
        endcase
    end
    
    assign Zero = (result == 0) ? 1 : 0;
    
endmodule
