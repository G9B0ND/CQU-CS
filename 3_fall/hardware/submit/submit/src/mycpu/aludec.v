`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/09 08:52:30
// Design Name: 
// Module Name: aludec
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
module aludec(op, Funct, ALUControl);
    input [5:0] op;
    input [5:0] Funct;
    output reg [4:0] ALUControl;

    always @(*) begin
        case (op)
            `R_TYPE: 
                case (Funct)
                    `AND: ALUControl = `AND_CONTROL;
                    `OR: ALUControl = `OR_CONTROL;
                    `XOR: ALUControl = `XOR_CONTROL;
                    `NOR: ALUControl = `NOR_CONTROL;
                    `SLL: ALUControl = `SLL_CONTROL;
                    `SRL: ALUControl = `SRL_CONTROL;
                    `SRA: ALUControl = `SRA_CONTROL;       
                    `SLLV: ALUControl = `SLLV_CONTROL;
                    `SRLV: ALUControl = `SRLV_CONTROL;
                    `SRAV: ALUControl = `SRAV_CONTROL;
                    `ADD: ALUControl = `ADD_CONTROL;
                    `ADDU: ALUControl = `ADDU_CONTROL;
                    `SUB: ALUControl = `SUB_CONTROL;
                    `SUBU: ALUControl = `SUBU_CONTROL;
                    `SLT: ALUControl = `SLT_CONTROL;
                    `SLTU: ALUControl = `SLTU_CONTROL;
                    `MULT: ALUControl = `MULT_CONTROL;
                    `MULTU: ALUControl = `MULTU_CONTROL;
                    `DIV: ALUControl = `DIV_CONTROL;
                    `DIVU: ALUControl = `DIVU_CONTROL;
                    default: ALUControl = `NO_CONTROL;
                endcase
            `ANDI: ALUControl = `AND_CONTROL;
            `ORI: ALUControl = `OR_CONTROL;
            `XORI: ALUControl = `XOR_CONTROL;
            `LUI: ALUControl = `LUI_CONTROL;
            `ADDI: ALUControl = `ADD_CONTROL;
            `ADDIU: ALUControl = `ADDU_CONTROL;
            `SLTI: ALUControl = `SLT_CONTROL;
            `SLTIU: ALUControl = `SLTU_CONTROL;
            `SW, `SH, `SB, `LW, `LH, `LHU, `LB, `LBU: ALUControl = `ADDU_CONTROL;
            default: ALUControl = `NO_CONTROL;
        endcase
    end
endmodule
