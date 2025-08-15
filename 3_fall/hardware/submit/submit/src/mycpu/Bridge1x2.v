`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/07 18:55:20
// Design Name: 
// Module Name: Bridge1x2
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


module Bridge1x2(
    input         now_dcache,
    
    //cpu data
    input         cpu_data_req,
    input         cpu_data_wr,
    input  [1 :0] cpu_data_size,
    input  [31:0] cpu_data_addr,
    input  [31:0] cpu_data_wdata,
    output [31:0] cpu_data_rdata,
    output        cpu_data_addr_ok,
    output        cpu_data_data_ok,

    //cache data
    output         ram_data_req,
    output         ram_data_wr,
    output  [1 :0] ram_data_size,
    output  [31:0] ram_data_addr,
    output  [31:0] ram_data_wdata,
    input   [31:0] ram_data_rdata,
    input          ram_data_addr_ok,
    input          ram_data_data_ok,

    //conf data
    output         conf_data_req,
    output         conf_data_wr,
    output  [1 :0] conf_data_size,
    output  [31:0] conf_data_addr,
    output  [31:0] conf_data_wdata,
    input   [31:0] conf_data_rdata,
    input          conf_data_addr_ok,
    input          conf_data_data_ok 
    );

    //up
    assign cpu_data_rdata = (now_dcache)? ram_data_rdata : conf_data_rdata;
    assign cpu_data_addr_ok = (now_dcache)? ram_data_addr_ok : conf_data_addr_ok;
    assign cpu_data_data_ok = (now_dcache)? ram_data_data_ok : conf_data_data_ok;

    //down
    assign ram_data_req = (now_dcache)? cpu_data_req : 1'b0;
    assign ram_data_wr = (now_dcache)? cpu_data_wr : 1'b0;
    assign ram_data_size = (now_dcache)? cpu_data_size : 2'b0;
    assign ram_data_addr = (now_dcache)? cpu_data_addr : 32'b0;
    assign ram_data_wdata = (now_dcache)? cpu_data_wdata : 32'b0;

    assign conf_data_req = (now_dcache)? 1'b0 : cpu_data_req;
    assign conf_data_wr = (now_dcache)? 1'b0 : cpu_data_wr;
    assign conf_data_size = (now_dcache)? 2'b0 : cpu_data_size;
    assign conf_data_addr = (now_dcache)? 32'b0 : cpu_data_addr;
    assign conf_data_wdata = (now_dcache)? 32'b0 : cpu_data_wdata;

endmodule
