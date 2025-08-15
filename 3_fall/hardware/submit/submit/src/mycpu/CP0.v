`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/03 00:24:15
// Design Name: 
// Module Name: CP0
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
module CP0(clk,rst,CP0En,CP0Write,rd,sel,WriteData,Int,EXcCode,Badaddr,DelaySlot,PC,
            CP0out,BadVAddr,Count,Status,Cause,EPC,ExceptDeal);
    input clk,rst;
    input CP0En;
    input CP0Write;
    input [4:0] rd;
    input [2:0] sel;
    input [31:0] WriteData;
    
    input [5:0] Int;
    input [4:0] EXcCode;
    input [31:0] Badaddr;
    input DelaySlot;
    input [31:0] PC;

    output reg [31:0] CP0out;
    output reg [31:0] BadVAddr;
    output [31:0] Count;
    output reg [31:0] Status;
    output reg [31:0] Cause;
    output reg [31:0] EPC;
    output reg ExceptDeal;
    
    reg [32:0] counter;
    wire [7:0] Screen;
    wire Interrupt;

    assign Count = counter[31:1];
    assign Screen = Status[15:8] & Cause[15:8];
    assign Interrupt = (Status[1] == 1'b0 && Status[0] == 1'b1 && (|Screen));

    always@(negedge clk or posedge rst)
    begin
        if(rst)
        begin
            CP0out <= 32'b0;
            ExceptDeal <= 1'b0;
            BadVAddr <= 32'b0;
            counter <= 32'b0;
            Status <= {9'b0,1'b1,22'b0};
            Cause <= 32'b0;
            EPC <= 32'b0;
        end
        else if(CP0En) 
        begin
            counter <= counter + 1'b1;
            Cause[15:10] <= Int;
            if(CP0Write)
            begin
                ExceptDeal <= 1'b0;
                case(rd)
                    // `CP0_REG_BADVADDR:
                    `CP0_REG_COUNT: counter[32:1] <= WriteData;
                    `CP0_REG_STATUS: Status <= WriteData;
                    `CP0_REG_CAUSE: Cause <= {Cause[31:24],WriteData[23:22],Cause[21:10],WriteData[9:8],Cause[7:0]};
                    `CP0_REG_EPC: EPC <= WriteData;
                    default: ;
                endcase
            end
            else begin
                if(Interrupt)
                begin
                    if(DelaySlot)
                    begin
                        EPC <= PC - 32'd4;
                        Cause[31] <= 1'b1;
                    end
                    else begin
                        EPC <= PC;
                        Cause[31] <= 1'b0;
                    end
                    Cause[6:2] <= `Int;
                    Status[1] <= 1'b1;
                    ExceptDeal <= 1'b1;
                end
                else begin
                    case(EXcCode)
                        `AdEL,`AdES,`Sys,`Bp,`RI,`Ov:
                            begin
                                if(DelaySlot)
                                begin
                                    EPC <= PC - 32'd4;
                                    Cause[31] <= 1'b1;
                                end
                                else begin
                                    EPC <= PC;
                                    Cause[31] <= 1'b0;
                                end
                                Cause[6:2] <= EXcCode;
                                Status[1] <= 1'b1; 
                                ExceptDeal <= 1'b1;
                            end
                        `Eret:
                            begin
                                Cause[6:2] <= EXcCode;
                                Status[1] <= 1'b0;
                                ExceptDeal <= 1'b1;
                            end
                        default: ExceptDeal <= 1'b0;
                    endcase
                end

                case(EXcCode)
                    `AdEL,`AdES: BadVAddr <= Badaddr;
                    default ;
                endcase

                case(rd)
                    `CP0_REG_BADVADDR: CP0out <= BadVAddr;
                    `CP0_REG_COUNT: CP0out <= Count;
                    `CP0_REG_STATUS: CP0out <= Status;
                    `CP0_REG_CAUSE: CP0out <= Cause;
                    `CP0_REG_EPC: CP0out <= EPC;
                    default: CP0out <= 32'b0;
                endcase
            end
        end
    end
endmodule
