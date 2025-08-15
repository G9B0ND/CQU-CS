`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/07 18:55:20
// Design Name: 
// Module Name: Bridge2x1
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


module Bridge2x1(
    input now_dcache,

    //cache data
    input         ram_data_req,
    input         ram_data_wr,
    input  [1 :0] ram_data_size,
    input  [31:0] ram_data_addr,
    input  [31:0] ram_data_wdata,
    output [31:0] ram_data_rdata,
    output        ram_data_addr_ok,
    output        ram_data_data_ok,

    //conf data
    input         conf_data_req,
    input         conf_data_wr,
    input  [1 :0] conf_data_size,
    input  [31:0] conf_data_addr,
    input  [31:0] conf_data_wdata,
    output [31:0] conf_data_rdata,
    output        conf_data_addr_ok,
    output        conf_data_data_ok,

    //wrap data
    output        wrap_data_req,
    output        wrap_data_wr,
    output [1 :0] wrap_data_size,
    output [31:0] wrap_data_addr,
    output [31:0] wrap_data_wdata,
    input  [31:0] wrap_data_rdata,
    input         wrap_data_addr_ok,
    input         wrap_data_data_ok
    );

    wire no_dcache;
    
    assign no_dcache = (~now_dcache) && (~ram_data_wr);

    //up
    assign ram_data_rdata   = (no_dcache) ? 32'b0 : wrap_data_rdata;
    assign ram_data_addr_ok = (no_dcache) ? 1'b0 : wrap_data_addr_ok;
    assign ram_data_data_ok = (no_dcache) ? 1'b0 : wrap_data_data_ok;

    assign conf_data_rdata   = (no_dcache) ? wrap_data_rdata : 32'b0;
    assign conf_data_addr_ok = (no_dcache) ? wrap_data_addr_ok : 1'b0;
    assign conf_data_data_ok = (no_dcache) ? wrap_data_data_ok : 1'b0;

    //down
    assign wrap_data_req   = (no_dcache) ? conf_data_req : ram_data_req;
    assign wrap_data_wr    = (no_dcache) ? conf_data_wr : ram_data_wr;
    assign wrap_data_size  = (no_dcache) ? conf_data_size : ram_data_size;
    assign wrap_data_addr  = (no_dcache) ? conf_data_addr : ram_data_addr;
    assign wrap_data_wdata = (no_dcache) ? conf_data_wdata : ram_data_wdata;   
endmodule
