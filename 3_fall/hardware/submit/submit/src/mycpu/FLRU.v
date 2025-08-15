`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/09 17:32:32
// Design Name: 
// Module Name: FLRU
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


module FLRU(
    input clk,rst,
    input enable,
    input [1:0] target,
    output [1:0] replace
    );

    reg rt;
    reg [1:0] sn;

    always@(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            rt <= 1'b0;
            sn <= 2'b0;
        end
        else if(enable)
        begin
            rt <= ~target[1];
            sn[target[1]] <= ~target[0];
        end
    end

    assign replace = {rt,sn[rt]};
endmodule
