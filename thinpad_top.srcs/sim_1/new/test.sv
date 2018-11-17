`timescale 1ns / 1ps
module tb();

reg clk_50M = 0;
reg clk_11M0592 = 0;

reg clock_btn = 0;         //BTN5手动时钟按钮�??关，带消抖电路，按下时为1
reg reset_btn = 0;         //BTN6手动复位按钮�??关，带消抖电路，按下时为1

wire[7:0] OutReg0;
wire[7:0] OutReg1;
wire[7:0] OutReg2;
wire[7:0] OutReg3;
wire[7:0] OutReg4;
wire[7:0] OutMem0;
wire[7:0] OutMem1;
wire[7:0] OutMem2;
wire[7:0] OutMem3;
wire[7:0] OutMem4;
wire[7:0] OutMem5;
wire[7:0] OutMem6;
wire[7:0] OutMem7;
wire[4:0] OutForward;
wire [31:0] outPC;
wire [31:0] outInstruction;
wire RegDst;
wire ALUSrc1, ALUSrc2;
wire MemtoReg;
wire RegWrite;
wire MemWrite;
wire MemRead;
wire Branch;
wire Jump;
wire ExtOp;
wire [2:0] ALUOp;
wire [7:0] debugOut1;
wire [7:0] debugOut2;
wire [7:0] debugOut3;
//Windows�??要注意路径分隔符的转义，例如"D:\\foo\\bar.bin"

initial begin 
    //在这里可以自定义测试输入序列，例如：
    reset_btn = 1;
    #25 reset_btn = 0;
    /*for (integer i = 0; i < 20; i = i++) begin
        #100; //等待100ns
        clock_btn = 1; //按下手工时钟按钮
        #100; //等待100ns
        clock_btn = 0; //松开手工时钟按钮
    end*/
end

always
begin
    #10 clk_50M = ~clk_50M;
end

thinpad_top dut(
    .clk_50M(clk_50M),
    .reset_btn(reset_btn),
    .OutReg0(OutReg0),
    .OutReg1(OutReg1),
    .OutReg2(OutReg2),
    .OutReg3(OutReg3),
    .OutReg4(OutReg4),
    .OutMem0(OutMem0),
    .OutMem1(OutMem1),
    .OutMem2(OutMem2),
    .OutMem3(OutMem3),
    .OutMem4(OutMem4),
    .OutMem5(OutMem5),
    //.OutMem6(OutMem6),
    //.OutMem7(OutMem7),
    .OutPC(outPC),
    .OutInstruction(outInstruction),
    .OutRegDst(RegDst),
    .OutALUSrc1(ALUSrc1),
    .OutALUSrc2(ALUSrc2),
    .OutMemtoReg(MemtoReg),
    .OutRegWrite(RegWrite),
    .OutMemWrite(MemWrite),
    .OutMemRead(MemRead),
    .OutBranch(Branch),
    .OutJump(Jump),
    .OutExtOp(ExtOp),
    .OutALUOp(ALUOp),
    .debugOut1(debugOut1),
    .debugOut2(debugOut2),
    .debugOut3(debugOut3),
    .OutForward(OutForward)
);
/*
clock osc(
    .clk_11M0592(clk_11M0592),
    .clk_50M    (clk_50M)
);
*/
endmodule