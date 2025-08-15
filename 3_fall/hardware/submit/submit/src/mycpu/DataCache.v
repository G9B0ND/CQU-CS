`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/07 20:04:11
// Design Name: 
// Module Name: DataCache
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


module DataCache(
    input clk,
    input rst,
    
    //cpu
    input cpu_data_req,
    input cpu_data_wr,
    input [1:0] cpu_data_size,
    input [31:0] cpu_data_addr,
    input [31:0] cpu_data_wdata,
    output [31:0] cpu_data_rdata,
    output cpu_data_addr_ok, 
    output cpu_data_data_ok,
    
    //axi
    output cache_data_req,
    output cache_data_wr,
    output [1:0] cache_data_size,
    output [31:0] cache_data_addr,
    output [31:0] cache_data_wdata,
    input [31:0] cache_data_rdata,
    input cache_data_addr_ok,
    input cache_data_data_ok
    );

    //Cache规格
    parameter SIZE_WIDTH = 9;//Cache总块数位宽
    parameter BLOCK_WIDTH = 32;//单Cache块大小位宽
    parameter OFFSET_WIDTH = 2;//单Cache块字节数位宽
    parameter ASSOCIATIVITY_WIDTH = 2;//组相联度位宽
    parameter INDEX_WIDTH= SIZE_WIDTH - ASSOCIATIVITY_WIDTH;//索引位宽
    parameter TAG_WIDTH = 32 - INDEX_WIDTH - OFFSET_WIDTH;//标记位宽

    parameter ASSOCIATIVITY = 1 << ASSOCIATIVITY_WIDTH;//组相联度
    parameter CACHE_DEEPTH= 1 << INDEX_WIDTH;//Cache深度

    reg cache_valid [CACHE_DEEPTH-1:0][ASSOCIATIVITY-1:0];//有效位
    reg cache_dirty [CACHE_DEEPTH-1:0][ASSOCIATIVITY-1:0];//脏位
    reg [TAG_WIDTH-1:0] cache_tag [CACHE_DEEPTH-1:0][ASSOCIATIVITY-1:0];//标记位
    reg [BLOCK_WIDTH-1:0] cache_block [CACHE_DEEPTH-1:0][ASSOCIATIVITY-1:0];//数据

    //本次访问的地址解析
    wire [TAG_WIDTH-1:0] tag;//标记
    wire [INDEX_WIDTH-1:0] index;//索引
    wire [OFFSET_WIDTH-1:0] offset;//字节偏移

    assign tag = cpu_data_addr[31:INDEX_WIDTH + OFFSET_WIDTH];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH-1:OFFSET_WIDTH];
    assign offset = cpu_data_addr[OFFSET_WIDTH-1:0];

    //判断是否命中
    reg [ASSOCIATIVITY_WIDTH-1:0] target;
    wire [ASSOCIATIVITY-1:0] hits;
    wire hit;

    genvar i;
    generate
        for(i = 0;i < ASSOCIATIVITY;i = i + 1)
        begin:Hits
            assign hits[i] = cache_valid[index][i] && (tag == cache_tag[index][i]);
        end
    endgenerate
    
    always@(*)
    begin
        case(hits)
        4'b0001: target <= 2'b00;
        4'b0010: target <= 2'b01;
        4'b0100: target <= 2'b10;
        4'b1000: target <= 2'b11;
        default: target <= 2'b00;
        endcase
    end
    assign hit= |hits;

    //替换策略更新
    wire [ASSOCIATIVITY_WIDTH-1:0] replace [CACHE_DEEPTH-1:0];
    wire enable [CACHE_DEEPTH-1:0];

    generate
    for(i = 0;i < CACHE_DEEPTH;i = i + 1)
    begin:FLRUs
        assign enable[i] = hit && (index == i); 
        FLRU LRU(clk,rst,enable[i],target,replace[i]);
    end
    endgenerate

    //掩码和处理后的写入数据
    reg [3:0] mask;
    wire [31:0] masks;
    wire [31:0] write_data;
    wire [31:0] rwrite_data;

    always@(*)
    begin
        case(cpu_data_size)
        2'b00: mask <= {4'b0001} << offset; 
        2'b01: mask <= {4'b0011} << offset;
        default: mask <= 4'b1111;
        endcase
    end

    assign masks = {{8{mask[3]}},{8{mask[2]}},{8{mask[1]}},{8{mask[0]}}};
    assign write_data = (cache_block[index][target] & (~masks)) | (cpu_data_wdata & masks);
    assign rwrite_data = (cache_data_rdata & (~masks)) | (cpu_data_wdata & masks);

    //FSM
    parameter IDLE=2'b00,RM=2'b01,WB=2'b10;
    reg [1:0] state;
    
    wire [INDEX_WIDTH-1:0] store_index;
    wire [ASSOCIATIVITY_WIDTH-1:0] store_target;

    always@(posedge clk or posedge rst)
    begin
        if(rst)
            state <= IDLE;
        else 
        begin
            case(state)
                IDLE: state <= (cpu_data_req && (~hit))? RM : IDLE;
                RM: state <= (~cache_data_data_ok)? RM:
                            (cache_dirty[store_index][store_target])? WB : IDLE;
                WB: state <= (~cache_data_data_ok)? WB:
                            (cpu_data_req && (~hit))? RM : IDLE;
                default state <= IDLE;
            endcase
        end
    end

    //地址发送成功后拉低请求信号
    reg send_req;

    always@(posedge clk or posedge rst)
    begin
        if(rst)
            send_req <= 1'b1;
        else begin
            send_req <= (cache_data_req && cache_data_addr_ok)? 1'b0 :
                        (cache_data_data_ok)? 1'b1 : send_req;
        end
    end

    //写缓冲区
    reg store_dirty;
    reg [BLOCK_WIDTH-1:0] store_buffer;
    reg [31:0] store_addr;
    wire [TAG_WIDTH-1:0] store_tag;
    wire store_write;
    
    assign store_tag = store_addr[31:INDEX_WIDTH+OFFSET_WIDTH];
    assign store_index = store_addr[INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];
    assign store_write = (state == RM)? cache_data_data_ok : (cpu_data_req && cpu_data_wr && hit);
    assign store_target = (state == RM)? replace[store_index] : target;

    always@(*)
    begin
        store_addr <= cpu_data_addr;
        if(state == RM)
        begin
            if(cpu_data_wr)
            begin
                store_dirty <= 1'b1;
                store_buffer <= rwrite_data;
            end
            else begin
                store_dirty <= 1'b0;
                store_buffer <= cache_data_rdata;
            end
        end
        else begin
            store_dirty <= 1'b1;
            if(cpu_data_req)
                store_buffer <= write_data;
            else store_buffer <= 32'b0;
        end          
    end

    integer j,k;
    always@(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            for(j = 0;j < CACHE_DEEPTH;j = j + 1)
            for(k = 0;k < ASSOCIATIVITY;k = k + 1)
            begin
                cache_valid[j][k] = 1'b0;
                cache_dirty[j][k] = 1'b0;
                cache_tag[j][k] = 1'b0;
                cache_block[j][k] = 32'b0;
            end
        end
        else if(store_write)
        begin
            cache_dirty[store_index][store_target] <= store_dirty;
            cache_valid[store_index][store_target] <= 1'b1;
            cache_tag[store_index][store_target] <= store_tag;
            cache_block[store_index][store_target] <= store_buffer;
        end
    end

    //写回缓冲区
    reg [BLOCK_WIDTH-1:0] write_buffer;
    reg [31:0] write_addr;

    always@(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            write_buffer <= 32'b0;
            write_addr <= 32'b0;
        end
        else if((state == RM) && cache_dirty[store_index][store_target])
        begin
            write_buffer <= cache_block[store_index][store_target];
            write_addr <= {cache_tag[store_index][store_target],store_index,2'b00};
        end
    end

    //MIPS Core接口
    assign cpu_data_addr_ok = (cpu_data_req && hit) || (cache_data_req && cache_data_addr_ok);
    assign cpu_data_data_ok = (cpu_data_req && hit) || ((state == RM) && cache_data_data_ok);
    assign cpu_data_rdata = (hit)? cache_block[index][target] : cache_data_rdata;

    //AXI接口
    assign cache_data_req = (state != IDLE) && send_req;
    assign cache_data_wr = (state == WB);
    assign cache_data_wdata = write_buffer;
    assign cache_data_size = 2'b10;// 读写均为整块
    assign cache_data_addr = (state == WB)? write_addr : {cpu_data_addr[31:2],2'b00};// 读地址低位清空(写缺失也是读的一种,写地址在转换时并未清空)
endmodule
