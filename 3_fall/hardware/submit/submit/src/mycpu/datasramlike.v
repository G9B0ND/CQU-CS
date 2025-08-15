`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/06 15:02:01
// Design Name: 
// Module Name: datasramlike
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


module datasramlike(
    input clk,rst,
    input StallM,
    output DataStall,

    input data_sram_en,
    input [3:0] data_sram_wen,
    input [31:0] data_sram_addr,
    input [31:0] data_sram_wdata,
    output [31:0] data_sram_rdata,

    output wire data_req,
    output wire data_wr,
    output wire [1:0] data_size,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input wire data_addr_ok,
    input wire data_data_ok,
    input wire [31:0] data_rdata
    );

    reg addr_rcv;//地址收到
    reg data_rcv;//读:收到cache数据,等待cpu接受 写:cache数据已写入
    reg [31:0] data_buffer;//数据被接收前的缓存

    always@(posedge clk)
    begin
        addr_rcv <= (rst)? 1'b0 :
                    (data_data_ok)? 1'b0 :
                    (data_req && data_addr_ok)? 1'b1 : addr_rcv;
    end

    always@(posedge clk)
    begin
        data_rcv <= (rst)? 1'b0 :
                (data_data_ok)? 1'b1 :
                (~StallM)? 1'b0 : data_rcv;
    end

    //读:收到数据确认信号时同步保留数据 写:无意义
    always@(posedge clk)
    begin
        data_buffer <= (rst)? 32'b0 :
                    (data_data_ok)? data_rdata : data_buffer;
    end

    assign data_req = data_sram_en && (~addr_rcv) && (~data_rcv);//请求的发出在IF阶段开始
    assign data_wr = |data_sram_wen;
    assign data_size = (data_sram_wen==4'b0001 || data_sram_wen==4'b0010 || data_sram_wen==4'b0100 || data_sram_wen==4'b1000) ? 2'b00:
                       (data_sram_wen==4'b0011 || data_sram_wen==4'b1100 ) ? 2'b01 : 2'b10;
    assign data_addr = data_sram_addr;
    assign data_wdata = data_sram_wdata;

    assign DataStall = data_sram_en && (~data_rcv);//从下个周期开始,流水线阻塞(刷新)
    assign data_sram_rdata = data_buffer;
endmodule
