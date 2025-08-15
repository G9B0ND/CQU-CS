`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/16 22:12:11
// Design Name: 
// Module Name: PC
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


module PC(clk,rst,en,PC,Adel,PCF);
    input clk;
    input rst;
    input en;
    input [31:0] PC;
    output reg Adel;
    output reg [31:0] PCF=0;

    always @(posedge clk or posedge rst) 
    begin
        if(rst)
        begin
            PCF <= 32'hbfc00000;
            Adel <= 1'b0;
        end
        else if(en)
        begin
            PCF <= PC;
            Adel <= PC[1] | PC[0];
        end
    end
endmodule
