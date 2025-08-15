`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/30 01:09:44
// Design Name: 
// Module Name: BranchCompare
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

`include "defines2.vh"
module BranchCompare(op,rt,SrcA,SrcB,PCSrc);
    input [5:0] op;
    input [4:0] rt;
    input [31:0] SrcA,SrcB;

    output reg PCSrc;

//PCSrc:为1表示跳转地址来源于Branch

    always@(*)
    begin
        case(op)
        `BEQ: PCSrc <= SrcA == SrcB;
        `BNE: PCSrc <= SrcA != SrcB;
        `BLEZ: PCSrc <= (SrcA == `ZeroWord) || SrcA[31];
        `BGTZ: PCSrc <= (SrcA != `ZeroWord) && ~SrcA[31];
        `REGIMM_INST:
            case(rt)
            `BLTZ,`BLTZAL: PCSrc <= SrcA[31];
            `BGEZ,`BGEZAL: PCSrc <= ~SrcA[31];
            default: PCSrc <= 1'b0;
            endcase
        default: PCSrc <= 1'b0;
        endcase
    end

endmodule
