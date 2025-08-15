`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/10 17:41:28
// Design Name: 
// Module Name: mul
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


module mul(clk,rst,Signed,A,B,Start,Enable,Annul,Result,Ready,Claim);
    input clk,rst;

    input Signed;
    input [31:0] A;
    input [31:0] B;
    input Start;
    input Enable;
    input Annul;
    output reg [63:0] Result;
    output reg Ready;
    output reg Claim;

    parameter MAX_ITERATION = 3'd1;

    reg Mulon;
    reg [2:0] Count;
    reg [31:0] regA,regB;
    reg regSigned;
    wire [31:0] mutA,mutB;
    wire [63:0] tmp;
    
    assign mutA = (regSigned && regA[31] == 1'b1 )? ~regA + 1'b1 : regA;
    assign mutB = (regSigned && regB[31] == 1'b1 )? ~regB + 1'b1 : regB;
    assign tmp = mutA * mutB;

    reg lastall;
    always@(posedge clk or posedge rst)
    begin
        lastall <= (rst)? 1'b0 : ~Enable;
    end

    always@(negedge clk or posedge rst)
    begin
        if(rst || Annul)
        begin
            Result <= 64'b0;
            Ready <= 1'b0;
            Claim <= 1'b0;
            
            Mulon <= 1'b0;
            Count <= 3'b0;

            regSigned <= 1'b0;
            regA <= 32'b0;
            regB <= 32'b0;
        end
        else begin
            if(Start)
            begin
                if(Mulon)
                begin
                    if(Count == MAX_ITERATION)
                    begin
                        Result <= (regSigned && (regA[31] ^ regB[31]))? ~tmp + 1'b1 : tmp;
                        Ready <= 1'b1;
                        Mulon <= 1'b0;
                        Claim <= lastall;
                    end
                    else Count <= Count + 1'b1;
                end
                else begin
                    Mulon <= 1'b1;
                    regSigned <= Signed;
                    regA <= A;
                    regB <= B;
                    Count <= 3'b0;
                    Ready <= 1'b0;
                    Claim <= 1'b0;
                end
            end
            else if(Enable)
                Ready <= 1'b0;
        end
    end

endmodule
