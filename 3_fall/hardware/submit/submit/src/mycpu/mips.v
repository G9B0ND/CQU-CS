`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/17 10:08:15
// Design Name: 
// Module Name: MIPS
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


module mips(
    input clk,
    input rst,
    input [5:0] Int,
    
    //inst
    output wire inst_req,
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok,
    input wire [31:0] inst_rdata,

    //data
    output wire data_req,
    output wire data_wr,
    output wire [1:0] data_size,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input wire data_addr_ok,
    input wire data_data_ok,
    input wire [31:0] data_rdata,

    //debug
    output [31:0] debug_wb_pc,
    output [3 :0] debug_wb_rf_wen,
    output [4 :0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
    );

    wire [5:0] opD,FunctD;//controller
    wire [1:0] BranchD;
    wire LinkE;
    wire LinkDstE;
    wire PCSrcD;
    wire JumpD;
    wire JumpSrcD;
    wire [4:0] ALUControlE;
    wire AluSrcE;
    wire RegDstE;
    wire MemReadE;
    wire RegWriteE;
    wire RegWriteM;
    wire MemWriteM;
    wire MemReadM;
    wire MemReadW;
    wire RegWriteW;
    wire [31:0] Inst;//datapath
    wire InstEnableF;
    wire [31:0] PCF;
    wire [4:0] RsD,RtD;
    wire [4:0] RsE,RtE;
    wire [31:0] ReadDataM;
    wire MemEnableM;
    wire [3:0] MemWenM;
    wire [31:0] MemAddrM;
    wire [31:0] TWriteDataM;
    wire [4:0] WriteRegE,WriteRegM,WriteRegW;
    wire [31:0] PCW;
    wire [31:0] WriteData3W;
    wire StallD;//hazardUnit
    wire StallF;
    wire StallE;
    wire StallM;
    wire StallW;
    wire FlushD;
    wire FlushE;
    wire FlushM;
    wire FlushW;
    wire [1:0] ForwardAD,ForwardBD;
    wire [1:0] ForwardAE,ForwardBE;

    wire HiloWriteE,HilotoRegE,HiloSrcE;//HILO
    wire [1:0] RetSrcE;
    wire [1:0] RetSrcM;
    wire [1:0] RetSrcW;
    wire MDUReadyE;//MDU

    wire EretD;
    wire BreakD;
    wire SyscallD;
    wire ReserveD;
    wire CP0WriteM;
    wire DelaySlotM;
    wire ExceptDealM;

    wire MemStall;

    wire inst_sram_en;
    wire [3:0] inst_sram_wen;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;

    wire data_sram_en;
    wire [3:0] data_sram_wen;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata; 

    controller controller(clk,rst,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW,opD,FunctD,RsD,RtD,EretD,
    BranchD,JumpD,JumpSrcD,ALUControlE,AluSrcE,RegDstE,MemReadE,RegWriteE,LinkE,LinkDstE,RegWriteM,MemWriteM,MemReadM,RegWriteW,MemReadW,
    HiloWriteE,HilotoRegE,HiloSrcE,RetSrcE,RetSrcM,RetSrcW,BreakD,SyscallD,ReserveD,CP0WriteM,DelaySlotM);
    
    datapath datapath(clk,rst,Int,Inst,StallF,JumpD,JumpSrcD,StallD,FlushD,ForwardAD,ForwardBD,ALUControlE,AluSrcE,RegDstE,LinkE,LinkDstE,StallE,FlushE,ForwardAE,
                        ForwardBE,StallM,FlushM,MemWriteM,MemReadM,ReadDataM,StallW,FlushW,RegWriteW,MemReadW,HiloWriteE,HilotoRegE,HiloSrcE,RetSrcM,RetSrcW,
                        BreakD,SyscallD,ReserveD,CP0WriteM,DelaySlotM,
    InstEnableF,PCF,opD,FunctD,RsD,RtD,EretD,PCSrcD,RsE,RtE,WriteRegE,MemEnableM,MemWenM,MemAddrM,TWriteDataM,WriteRegM,WriteRegW,MDUReadyE,PCW,WriteData3W,ExceptDealM);
    
    hazardunit hazardunit(MemReadE,RegWriteE,MemReadM,RegWriteM,RegWriteW,RsD,RtD,PCSrcD,BranchD,JumpD,JumpSrcD,RsE,RtE,WriteRegE,WriteRegM,WriteRegW,MDUReadyE,RetSrcE,RetSrcM,
                            ExceptDealM,MemStall,
    StallF,StallD,StallE,StallM,StallW,ForwardAD,ForwardBD,FlushD,FlushE,FlushM,FlushW,ForwardAE,ForwardBE);

    

    //debug
    assign debug_wb_pc = PCW;
    assign debug_wb_rf_wen = (InstStall || DataStall)? 4'b0 : {4{RegWriteW}};
    assign debug_wb_rf_wnum = WriteRegW;
    assign debug_wb_rf_wdata = WriteData3W;
    //1.datapath通过Translator向外提供sram类型的接口

    assign inst_sram_en = InstEnableF;//inst
    // assign inst_sram_wen = 4'b0;
    assign inst_sram_addr = PCF;
    // assign inst_sram_wdata = 32'b0;
    assign Inst = inst_sram_rdata;

    assign data_sram_en = MemEnableM;//data
    assign data_sram_wen = MemWenM;
    assign data_sram_addr = MemAddrM;
    assign data_sram_wdata = TWriteDataM;
    assign ReadDataM = data_sram_rdata;

    //2.MIPS将上述sram类型的接口转换为sram-like后向外提供

    //inst
    assign MemStall = InstStall || DataStall;
    instsramlike instsramlike(clk,rst,StallF,InstStall,
                            inst_sram_en,inst_sram_addr,inst_sram_rdata,                            
                            inst_req,inst_wr,inst_size,inst_addr,inst_wdata,inst_addr_ok,inst_data_ok,inst_rdata);
    //data
    datasramlike datasramlike(clk,rst,StallM,DataStall,
                            data_sram_en,data_sram_wen,data_sram_addr,data_sram_wdata,data_sram_rdata,
                            data_req,data_wr,data_size,data_addr,data_wdata,data_addr_ok,data_data_ok,data_rdata);
endmodule
