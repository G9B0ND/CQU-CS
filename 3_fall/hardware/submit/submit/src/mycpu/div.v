`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/29 15:18:18
// Design Name: 
// Module Name: div
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


module div(clk,rst,Signed,A,B,Start,Enable,Annul,Result,Ready,Claim);
    input clk,rst;

    input Signed;
    input [31:0] A;
    input [31:0] B;
    input Start;
    input Enable;
    input Annul;
    output [63:0] Result;
    output reg Ready;
    output reg Claim;

    parameter MAX_ITERATION = 3'd6;// 迭代次数的下界,共计5(商)+1(余数)个周期,可以保证32位整数以浮点形式参与运算过程中的精度要求

    wire [31:0] divA,divB;
    reg Divon;
    reg [2:0] Count;
    reg [63:0] regA,regB;
    wire [31:0] mantissA,mantissB;
    wire [31:0] normQ;
    wire [63:0] tmpQ;
    wire [4:0] clzA,clzB;
    wire [63:0] TwoMinusYi;
    wire [127:0] Xi,Yi;
    reg regSigned;// 保留除法开始时的输入信号,避免其在运算过程中发生变化(主要是被除数A和除数B,Signed实际上不会发生变化(因为Signed不存在由数据前推得到的情况))
    reg [4:0] OffsetA,OffsetB;
    reg [31:0] Dividend;
    reg [31:0] Divisor;
    wire [31:0] mulD,mulQ,tmp;
    reg [31:0] Quotient;
    reg [31:0] Remainder;

    reg lastall;//
    always@(negedge clk or posedge rst)
    begin
        lastall <= (rst)? 1'b0 : ~Enable;
    end
    
    always@(posedge clk or posedge rst)
    begin
        if(rst || Annul)
        begin
            Ready <= 1'b0;
            Divon <= 1'b0;
        end
        else begin
            if(Start)
            begin
                if(Divon)
                begin
                    if(Count == MAX_ITERATION)
                    begin
                        Remainder <= Dividend + ((Divisor[31] ^ Quotient[31])? tmp : ~tmp + 1'b1);
                        Ready <= 1'b1;
                        Divon <= 1'b0;
                        Claim <= lastall;
                    end
                    else if(Count == MAX_ITERATION - 1)//最后一个周期不迭代,用以计算余数
                    begin
                        Quotient <= (regSigned && (Dividend[31] ^ Divisor[31]))? ~tmpQ[62:31] + 1'b1 : tmpQ[62:31];
                        Count <= Count + 1'b1;
                    end
                    else begin
                        regA <= Xi[126:63];
                        regB <= Yi[126:63];
                        Count <= Count + 1'b1;
                    end
                end
                else begin
                    Divon <= 1'b1;
                    regSigned <= Signed;
                    OffsetA <= clzA;
                    OffsetB <= clzB;
                    Dividend <= A;
                    Divisor <= B;
                    regA <= {1'b0,mantissA,31'b0};
                    regB <= {1'b0,mantissB,31'b0};
                    Count <= 3'b0;
                    Ready <= 1'b0;
                    Claim <= 1'b0;
                end
            end
            else if(Enable)
                Ready <= 1'b0;
        end
    end

    assign divA = (Signed && A[31] == 1'b1 )? ~A + 1'b1 : A;
    assign divB = (Signed && B[31] == 1'b1 )? ~B + 1'b1 : B; 
    clz CLZA(divA,clzA);
    clz CLZB(divB,clzB);
    assign mantissA = divA << clzA;
    assign mantissB = divB << clzB;
    assign TwoMinusYi = ~regB + 1'b1;
    assign Xi = regA * TwoMinusYi;
    assign Yi = regB * TwoMinusYi;

    assign normQ = regA[63:32] + (|regA[31:0]);//四舍五入
    assign tmpQ = (OffsetA > OffsetB)? normQ >> (OffsetA - OffsetB) : normQ << (OffsetB - OffsetA);//转回整数

    assign mulD = Divisor[31]? ~Divisor + 1'b1 : Divisor;//最后一个周期所进行的运算
    assign mulQ = Quotient[31]? ~Quotient + 1'b1 : Quotient;
    assign tmp = mulD * mulQ;

    assign Result = {Remainder,Quotient};
endmodule
