`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/15 19:05:10
// Design Name: 
// Module Name: controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller(clk,rst,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW,opD,FunctD,RsD,RtD,EretD,
BranchD,JumpD,JumpSrcD,ALUControlE,AluSrcE,RegDstE,MemReadE,RegWriteE,LinkE,LinkDstE,RegWriteM,MemWriteM,MemReadM,RegWriteW,MemReadW,
HiloWriteE,HilotoRegE,HiloSrcE,RetSrcE,RetSrcM,RetSrcW,
BreakD,SyscallD,ReserveD,CP0WriteM,DelaySlotM);
    input clk;
    input rst;
    input StallD;
    input FlushD;
    input StallE;
    input FlushE;
    input StallM;
    input FlushM;
    input StallW;
    input FlushW;
    input [5:0] opD;//ID
    input [5:0] FunctD;
    input [4:0] RsD;
    input [4:0] RtD;
    input EretD;

    output [1:0] BranchD;//ID
    output JumpD;
    output JumpSrcD;
    output [4:0] ALUControlE;//EX
    output AluSrcE;
    output RegDstE;
    output MemReadE;
    output RegWriteE;
    output LinkE;
    output LinkDstE;
    output RegWriteM;//MEM
    output MemWriteM;
    output MemReadM;
    output RegWriteW;//WB
    output MemReadW;

    output HiloWriteE,HilotoRegE,HiloSrcE;//HILO
    output [1:0] RetSrcE;
    output [1:0] RetSrcM;
    output [1:0] RetSrcW;

    output BreakD;
    output SyscallD;
    output ReserveD;
    output CP0WriteM;
    output DelaySlotM;

    wire RegWriteD;
    wire MemWriteD,MemWriteE;
    wire MemReadD;
    wire [4:0] ALUControlD;
    wire AluSrcD;
    wire RegDstD;
    wire LinkD;
    wire LinkDstD;
    
    wire [1:0] RetSrcD;
    wire HiloWriteD,HilotoRegD,HiloSrcD;
    wire HiloWriteE,HilotoRegE;

    wire CP0WriteD,CP0WriteE;
    wire DelaySlotF,DelaySlotD,DelaySlotE;

    maindec maindec(opD,FunctD,RsD,RtD,EretD,RegWriteD,RegDstD,RetSrcD,AluSrcD,MemWriteD,MemReadD,
                            HiloWriteD,HilotoRegD,HiloSrcD,
                            BranchD,JumpD,JumpSrcD,
                            LinkD,LinkDstD,
                            BreakD,SyscallD,CP0WriteD,ReserveD);
    aludec aludec(opD,FunctD,ALUControlD);

    assign DelaySlotF = (|BranchD) || JumpD;
    Flopenrc #(1) reg_IF_ID(clk,rst,FlushD,~StallD,{DelaySlotF},{DelaySlotD});
    Flopenrc #(19) reg_ID_EX(clk,rst,FlushE,~StallE,
                                    {RegWriteD,RegDstD,AluSrcD,MemWriteD,MemReadD,ALUControlD,RetSrcD,LinkD,LinkDstD,HiloWriteD,HilotoRegD,HiloSrcD,CP0WriteD,DelaySlotD},
                                    {RegWriteE,RegDstE,AluSrcE,MemWriteE,MemReadE,ALUControlE,RetSrcE,LinkE,LinkDstE,HiloWriteE,HilotoRegE,HiloSrcE,CP0WriteE,DelaySlotE});
    Flopenrc #(7) reg_EX_MEM(clk,rst,FlushM,~StallM,
                                {RegWriteE,MemWriteE,MemReadE,RetSrcE,CP0WriteE,DelaySlotE},
                                {RegWriteM,MemWriteM,MemReadM,RetSrcM,CP0WriteM,DelaySlotM});
    Flopenrc #(4) reg_MEM_WB(clk,rst,FlushW,~StallW,
                                {RegWriteM,MemReadM,RetSrcM},
                                {RegWriteW,MemReadW,RetSrcW});
endmodule
