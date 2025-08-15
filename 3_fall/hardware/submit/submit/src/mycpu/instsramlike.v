`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/06 15:02:01
// Design Name: 
// Module Name: instsramlike
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


module instsramlike(
    input clk,rst,
    input StallF,
    output InstStall,

    input inst_sram_en,
    input [31:0] inst_sram_addr,
    output [31:0] inst_sram_rdata,
    
    output wire inst_req,
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok,
    input wire [31:0] inst_rdata
    );

    reg addr_rcv;//cache收到地址
    reg data_rcv;//收到cache数据,等待cpu接受
    reg [31:0] data_buffer;//数据被接收前的缓存

    always@(posedge clk)
    begin
        addr_rcv <= (rst)? 1'b0 :
                    (inst_data_ok)? 1'b0 :
                    (inst_req && inst_addr_ok)? 1'b1 : addr_rcv;
    end

    always@(posedge clk)
    begin
        data_rcv <= (rst)? 1'b0 :
                (inst_data_ok)? 1'b1 :
                (~StallF)? 1'b0 : data_rcv;
    end
    always@(posedge clk)//收到数据确认信号时同步保留数据(安全性考虑,目前应该不是必要的,在下一个沿到来前数据应该不会发生变化)
    begin
        data_buffer <= (rst)? 32'b0 :
                    (inst_data_ok)? inst_rdata : data_buffer;
    end

    assign inst_req = inst_sram_en && (~addr_rcv) && (~data_rcv);//请求的发出在IF阶段开始
    assign inst_wr = 1'b0;
    assign inst_size = 2'b10;
    assign inst_addr = inst_sram_addr;
    assign inst_wdata = 32'b0;

    assign InstStall = inst_sram_en && (~data_rcv);//从下个周期开始,流水线阻塞(刷新)
    assign inst_sram_rdata = data_buffer;
endmodule
