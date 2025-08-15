`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/27 13:08:20
// Design Name: 
// Module Name: MDU
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
module MDU(clk,rst,clear,en,MDUControl,A,B,MDUResult,MDUReady);
    input clk,rst;
    input clear;
    input en;
    input [4:0] MDUControl;
    input [31:0] A;
    input [31:0] B;

    output reg [63:0] MDUResult;
    output MDUReady;

    reg MulStart;//MUL
    wire MulAnnul;
    wire MulEn;
    wire MulSigned;
    wire [63:0] MulResult;
    wire MulReady;
    wire MulClaim;    
    
    assign MulAnnul = clear;
    assign MulEn = en;
    assign MulSigned = (MDUControl == `MULT_CONTROL);
    mul mul(clk,rst,MulSigned,A,B,MulStart,MulEn,MulAnnul,MulResult,MulReady,MulClaim);
    
    reg DivStart;//DIV
    wire DivAnnul;
    wire DivEn;
    wire DivSigned;
    wire [63:0] DivResult;
    wire DivReady;
    wire DivClaim;

    assign DivAnnul = clear;
    assign DivEn = en;
    assign DivSigned = (MDUControl == `DIV_CONTROL);
    div div(clk,rst,DivSigned,A,B,DivStart,DivEn,DivAnnul,DivResult,DivReady,DivClaim);

    always@(*)
    begin
        case(MDUControl)
            `MULT_CONTROL,`MULTU_CONTROL: MDUResult <= MulResult;
            `DIV_CONTROL,`DIVU_CONTROL: MDUResult <= DivResult;      
            default: MDUResult <= {64{1'b0}};
        endcase
    end        
    
    always@(*)
    begin
        case(MDUControl)
            `MULT_CONTROL,`MULTU_CONTROL:
                begin
                    MulStart <= ~MulReady;
                    DivStart <= 1'b0;
                end
            `DIV_CONTROL,`DIVU_CONTROL:
                begin
                    MulStart <= 1'b0;
                    DivStart <= ~DivReady;
                end
            default: 
                begin
                    MulStart <= 1'b0;
                    DivStart <= 1'b0;
                end
        endcase
    end    
    assign MDUReady = (MDUControl == `MULT_CONTROL || MDUControl == `MULTU_CONTROL)? MulReady || MulClaim :
                        (MDUControl == `DIV_CONTROL || MDUControl == `DIVU_CONTROL)? DivReady || DivClaim : 1'b1;
endmodule
