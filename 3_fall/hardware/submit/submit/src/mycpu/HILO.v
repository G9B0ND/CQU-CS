`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/27 14:17:37
// Design Name: 
// Module Name: HILO
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


module HILO(clk,rst,HiloEn,HiloWrite,HilotoReg,HiloSrc,Hiloin,MDUResult,Hilout);
    input clk,rst;
    input HiloEn;
    input HiloWrite;
    input HilotoReg;
    input HiloSrc;
    input [31:0] Hiloin;
    input [63:0] MDUResult;

    output reg [31:0] Hilout;
    
    reg [31:0] Hi,Lo;
    always@(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            Hi <= 32'b0;
            Lo <= 32'b0;
            Hilout <= 32'b0;
        end
        else if(HiloEn) begin
            if(HilotoReg)
                Hilout <= Hi;
            else Hilout <= Lo;
 
            if(HiloWrite) 
            begin
                if(HiloSrc)
                begin
                    if(HilotoReg)
                        Hi <= Hiloin;
                    else Lo <= Hiloin;
                end
                else begin
                    {Hi,Lo} <= MDUResult;
                end
            end
        end
    end

endmodule
