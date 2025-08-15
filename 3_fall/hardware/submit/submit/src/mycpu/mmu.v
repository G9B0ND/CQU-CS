`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/01 15:34:57
// Design Name: 
// Module Name: MMU
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


module mmu(inst_vaddr,inst_paddr,data_vaddr,data_paddr,now_dcache);
    input [31:0] inst_vaddr;
    output [31:0] inst_paddr;
    
    input [31:0] data_vaddr;
    output [31:0] data_paddr;
    output now_dcache;

    wire inst_kseg0, inst_kseg1;
    wire data_kseg0, data_kseg1;

    assign inst_kseg0 = inst_vaddr[31:29] == 3'b100;
    assign inst_kseg1 = inst_vaddr[31:29] == 3'b101;
    assign data_kseg0 = data_vaddr[31:29] == 3'b100;
    assign data_kseg1 = data_vaddr[31:29] == 3'b101;


    assign inst_paddr = (inst_kseg0 | inst_kseg1)? {3'b0,inst_vaddr[28:0]} : inst_vaddr;
    assign data_paddr = (data_kseg0 | data_kseg1)? {3'b0,data_vaddr[28:0]} : data_vaddr;
    assign now_dcache = data_kseg0;
endmodule
