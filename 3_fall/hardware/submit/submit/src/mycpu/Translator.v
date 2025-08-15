`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/31 17:57:05
// Design Name: 
// Module Name: Translator
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
module Translator(op,MemWrite,MemRead,MemEnable,MemWen,EXResult,MemAddr,ReadData,TReadData,WriteData,TWriteData,Adel,Ades);
    input [5:0] op;
    input MemWrite;
    input MemRead;
    output MemEnable;
    output reg [3:0] MemWen;

    input [31:0] EXResult;
    output [31:0] MemAddr;

    input [31:0] ReadData;
    output reg [31:0] TReadData;

    input [31:0] WriteData;
    output reg [31:0] TWriteData;

    output reg Adel;
    output reg Ades;

    wire [1:0] addr;
    wire MemError;
    
    assign addr = EXResult[1:0];
    assign MemError = Adel || Ades;
    assign MemEnable = (~MemError) && (MemWrite | MemRead);
    assign MemAddr = (MemWrite)? EXResult : {EXResult[31:2],2'b0};

    always@(*)
    begin
        case(op)
        `SW:
            begin
                TWriteData <= WriteData;
                MemWen <= 4'b1111;
            end
        `SH:
            begin
                TWriteData <= {2{WriteData[15:0]}};
                case(addr)
                2'b00: MemWen <= 4'b0011;
                2'b10: MemWen <= 4'b1100;
                default: MemWen <= 4'b0;
                endcase
            end
        `SB:
            begin
                TWriteData <= {4{WriteData[7:0]}};
                case(addr)
                2'b00: MemWen <= 4'b0001;
                2'b01: MemWen <= 4'b0010;
                2'b10: MemWen <= 4'b0100;
                2'b11: MemWen <= 4'b1000;
                default: MemWen <= 4'b0;
                endcase
            end
        default: 
            begin
                TWriteData <= 32'b0;
                MemWen <= 4'b0;
            end
        endcase
    end

    always@(*)
    begin
        case(op)
        `LW: TReadData <= ReadData;
        `LH:
            case(addr)
            2'b00: TReadData <= {{16{ReadData[15]}},ReadData[15:0]};
            2'b10: TReadData <= {{16{ReadData[31]}},ReadData[31:16]};
            default: TReadData <= 32'b0;
            endcase
        `LHU:
            case(addr)
            2'b00: TReadData <= {{16{1'b0}},ReadData[15:0]};
            2'b10: TReadData <= {{16{1'b0}},ReadData[31:16]};
            default: TReadData <= 32'b0;
            endcase
        `LB:
            case(addr)
            2'b00: TReadData <= {{24{ReadData[7]}},ReadData[7:0]};
            2'b01: TReadData <= {{24{ReadData[15]}},ReadData[15:8]};
            2'b10: TReadData <= {{24{ReadData[23]}},ReadData[23:16]};
            2'b11: TReadData <= {{24{ReadData[31]}},ReadData[31:24]};
            default: TReadData <= 32'b0;
            endcase
        `LBU:
            case(addr)
            2'b00: TReadData <= {{24{1'b0}},ReadData[7:0]};
            2'b01: TReadData <= {{24{1'b0}},ReadData[15:8]};
            2'b10: TReadData <= {{24{1'b0}},ReadData[23:16]};
            2'b11: TReadData <= {{24{1'b0}},ReadData[31:24]};
            default: TReadData <= 32'b0;
            endcase
        default: TReadData <= 32'b0;
        endcase        
    end

    always@(*)
    begin
        case(op)
        `LW: Adel <= |addr;
        `LH,`LHU: Adel <= addr[0];
        default: Adel <= 1'b0;
        endcase
    end

    always@(*)
    begin
        case(op)
        `SW: Ades <= |addr;
        `SH: Ades <= addr[0];
        default: Ades <= 1'b0;
        endcase
    end

endmodule
