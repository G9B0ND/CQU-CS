`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/14 01:06:42
// Design Name: 
// Module Name: regfile
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


module regfile(clk,rst,RegWrite,ReadReg1,ReadReg2,WriteReg,WriteData,ReadData1,ReadData2);
    input clk,rst;
    input RegWrite;
    input [4:0] ReadReg1,ReadReg2,WriteReg;
    input [31:0] WriteData;
    output [31:0] ReadData1,ReadData2;

    reg [31:0] GPR [31:0];
    integer i;
    
    always@(negedge clk or posedge rst)
    begin
        if(rst)
        begin
            // 调试过程中注释以便于观察波形图
            for(i = 0; i < 32 ; i = i + 1)
            begin
                GPR[i] <= 32'b0;
            end
        end
        else if(RegWrite)
            GPR[WriteReg] <= WriteData;
    end

    assign ReadData1 = (ReadReg1)? GPR[ReadReg1] : 32'b0;
    assign ReadData2 = (ReadReg2)? GPR[ReadReg2] : 32'b0;
endmodule
