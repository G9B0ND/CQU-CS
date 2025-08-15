`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/29 16:41:35
// Design Name: 
// Module Name: CLZ
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


module clz(Datain,clz);
    input [31:0] Datain;
    output [4:0] clz;

    wire [4:0] Check;
    wire [15:0] Range1;
    wire [7:0] Range2;
    wire [3:0] Range3;
    wire [1:0] Range4;

    assign Check = {|Datain[31:16], |Range1[15:8], |Range2[7:4], |Range3[3:2], |Range4[1]};
    assign Range1 = Check[4] ? Datain[31:16] : Datain[15:0];
    assign Range2 = Check[3] ? Range1[15:8] : Range1[7:0]; 
    assign Range3 = Check[2] ? Range2[7:4] : Range2[3:0];
    assign Range4 = Check[1] ? Range3[3:2] : Range3[1:0];

    assign clz = (|Datain)? ~Check : 5'b0;

endmodule
