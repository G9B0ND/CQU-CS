`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/16 22:05:42
// Design Name: 
// Module Name: datapath
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
module datapath(clk,rst,Int,Inst,StallF,JumpD,JumpSrcD,StallD,FlushD,ForwardAD,ForwardBD,ALUControlE,AluSrcE,RegDstE,LinkE,LinkDstE,StallE,FlushE,ForwardAE,
                ForwardBE,StallM,FlushM,MemWriteM,MemReadM,ReadDataM,StallW,FlushW,RegWriteW,MemReadW,HiloWriteE,HilotoRegE,HiloSrcE,RetSrcM,RetSrcW,
                BreakD,SyscallD,
                ReserveD,CP0WriteM,DelaySlotM,
InstEnableF,PCF,opD,FunctD,RsD,RtD,EretD,PCSrcD,RsE,RtE,WriteRegE,MemEnableM,MemWenM,MemAddrM,TWriteDataM,WriteRegM,WriteRegW,MDUReadyE,
PCW,WriteData3W,
ExceptDealM);
    input clk;
    input rst;
    input [5:0] Int;
    input [31:0] Inst;
    input StallF;//IF

    input JumpD;//ID
    input JumpSrcD;
    input StallD;
    input FlushD;
    input [1:0] ForwardAD,ForwardBD;
    input [4:0] ALUControlE;//EX
    input AluSrcE;
    input RegDstE;
    input LinkE;
    input LinkDstE;
    input StallE;
    input FlushE;
    input [1:0] ForwardAE,ForwardBE;
    input StallM;//MEM
    input FlushM;
    input MemWriteM;
    input MemReadM;
    input [31:0] ReadDataM;
    input StallW;//WB
    input FlushW;
    input RegWriteW;
    input MemReadW;

    input HiloWriteE,HilotoRegE,HiloSrcE;//HILO
    input [1:0] RetSrcM;
    input [1:0] RetSrcW;
    input BreakD;//Exception
    input SyscallD;
    input ReserveD;
    input CP0WriteM;//CP0
    input DelaySlotM;

    output InstEnableF;//IF
    output [31:0] PCF;
    output [5:0] opD,FunctD;
    output [4:0] RsD,RtD;//ID
    output EretD;
    output PCSrcD;
    output [4:0] RsE,RtE;//EX
    output [4:0] WriteRegE;
    output MemEnableM;//MEM
    output [3:0] MemWenM;
    output [31:0] MemAddrM;
    output [31:0] TWriteDataM;
    output [4:0] WriteRegM;
    output [4:0] WriteRegW;//WB
    output MDUReadyE;//MDU

    output [31:0] PCW;//debug
    output [31:0] WriteData3W;

    output ExceptDealM;

    wire [31:0] PC;//IF
    wire [31:0] InstF;
    wire [31:0] PCPlus4F;
    wire [31:0] Branch_AddrD;
    wire [31:0] Jump_AddrD;
    wire [31:0] PCD;//ID
    wire [31:0] InstD;
    wire [31:0] PCPlus4D;
    wire [4:0] RdD;
    wire EqualD;
    wire [31:0] SrcAD,BeqSrcBD;
    wire [31:0] ReadData1D,ReadData2D;
    wire [31:0] ExtendD;
    wire [4:0] saD;
    wire [31:0] PCE;//EX
    wire [5:0] opE;
    wire [31:0] ReadData1E,ReadData2E;
    wire [4:0] RdE;
    wire [31:0] ExtendE;
    wire [4:0] saE;
    wire [31:0] WriteDataE;
    wire [31:0] SrcAE,SrcBE;
    wire [31:0] ALUResultE;
    wire [31:0] EXResultE;
    wire [31:0] PCM;//MEM
    wire [5:0] opM;
    wire [4:0] RdM;
    wire [2:0] SelM;
    wire [31:0] MEMResultM;
    wire [31:0] TReadDataM;
    wire [31:0] WriteDataM;
    wire [31:0] EXResultM;
    wire [31:0] ReadDataW;//WB
    wire [31:0] MEMResultW;
    wire [4:0] WriteRegW;

    wire [31:0] HiloutM;//HILO
    wire HiloStallM;

    wire [63:0] MDUResultE;//MDU

    wire [31:0] ExcepTypeF,ExcepTypeD,ExcepTypeE,ExcepTypeM;//Exception & CP0
    wire AdelF;
    wire IntegerOverflowE;
    wire AdelM;
    wire AdesM;
    wire EretM;
    wire [31:0] RWriteDataM;
    wire [31:0] Badaddr;
    wire [4:0] EXcCode;
    wire [31:0] CP0outM;
    wire [31:0] CP0outW;
    wire [31:0] BadVAddr;
    wire [31:0] Count;
    wire [31:0] Status;
    wire [31:0] Cause;
    wire [31:0] EPC;


    //取址
    PC pcreg(clk,rst,~StallF,PC,AdelF,PCF);//IF
    
    assign InstEnableF = ~AdelF; //如果AdelF为1（即发生地址异常），则不允许提取指令。
    assign InstF = (InstEnableF)? Inst : 32'b0;
    assign ExcepTypeF = 32'b0;
    assign PCPlus4F = PCF + 32'd4;//IF

    //PC选择器
    assign PC = (EretM)? EPC : // 如果 EretM 为真（即 1），那么程序计数器（PC）会被设置为 EPC（异常返回地址）
                (ExceptDealM)? 32'hbfc00380 : //如果 ExceptDealM 为真，表示处理异常的状态下，程序计数器（PC）将设置为常量 32'hbfc00380
                (JumpD)? ((JumpSrcD)? SrcAD : Jump_AddrD) : //如果 JumpD 为真，表示跳转操作被激活，此时程序计数器的值将根据 JumpSrcD 来选择
                (PCSrcD)? Branch_AddrD : PCPlus4F; //如果 PCSrcD 为真，表示跳转到分支地址，PC 被设置为 Branch_AddrD（分支地址） 如果 PCSrcD 为假，表示没有跳转，程序计数器将被设置为 PCPlus4F，即当前指令地址加上 4

    Flopenrc #(128) piplinereg_IF_ID(clk,rst,FlushD,~StallD,{PCF,InstF,PCPlus4F,{ExcepTypeF[31:5],AdelF,ExcepTypeF[3:0]}},
                                                            {PCD,InstD,PCPlus4D,ExcepTypeD});//IF_ID

    //译码
    regfile regfileD(clk,rst,RegWriteW,RsD,RtD,WriteRegW,WriteData3W,ReadData1D,ReadData2D);//ID

    BranchCompare branchcompare(opD,RtD,SrcAD,BeqSrcBD,PCSrcD);//分支跳转选择

    assign opD = InstD[31:26];//ID
    assign RsD = InstD[25:21];
    assign RtD = InstD[20:16];
    assign RdD = InstD[15:11];
    assign saD = InstD[10:6]; //移位量
    assign FunctD = InstD[5:0];

    //SrcAD 是 分支判断 的输入之一，它根据转发控制信号的状态，从不同阶段选择数据源
    assign SrcAD = (ForwardAD == 2'b00)? ReadData1D : //直接从寄存器文件获取数据
                (ForwardAD == 2'b01)? WriteData3W : //是写回阶段（WB阶段）写回的数据
                (ForwardAD == 2'b10)? MEMResultM : 32'b0; //是存储器访问阶段（MEM阶段）返回的结果
   //分支判断第二个输入
    assign BeqSrcBD = (ForwardBD == 2'b00)? ReadData2D :
                (ForwardBD == 2'b01)? WriteData3W :
                (ForwardBD == 2'b10)? MEMResultM : 32'b0;

    //零扩展和字符扩展
    assign ExtendD = (opD[3:2] == 2'b11) ? {{16{1'b0}},InstD[15:0]} : {{16{InstD[15]}},InstD[15:0]};//扩展立即数
    
    assign Branch_AddrD = PCPlus4D + {ExtendD[30:0],2'b00}; //计算分支目标地址
    assign Jump_AddrD = {PCPlus4D[31:28],InstD[25:0],2'b00};//计算跳转目标地址

    assign EretD = (InstD == `ERET);//异常返回（ERET）指令

    Flopenrc #(186) piplinereg_ID_EX(clk,rst,FlushE,~StallE,
                                    {PCD,opD,RsD,RtD,RdD,ExtendD,saD,ReadData1D,ReadData2D,{ExcepTypeD[31:15],EretD,ExcepTypeD[13:11],ReserveD,BreakD,SyscallD,ExcepTypeD[7:0]}},
                                    {PCE,opE,RsE,RtE,RdE,ExtendE,saE,ReadData1E,ReadData2E,ExcepTypeE});//ID_EX

    //计算                                
    ALU alu(ALUControlE,SrcAE,SrcBE,saE,ALUResultE,IntegerOverflowE);//加法器
    MDU mdu(clk,rst,FlushE,~StallE,ALUControlE,SrcAE,SrcBE,MDUResultE,MDUReadyE);//乘法器

    //ALU (算术逻辑单元) 的第一个输入
    assign SrcAE = (ForwardAE == 2'b00)? ReadData1E:
                    (ForwardAE == 2'b01)? WriteData3W:
                    (ForwardAE == 2'b10)? MEMResultM : 32'b0;

    //ALU (算术逻辑单元) 的第二个输入
    assign WriteDataE = (ForwardBE == 2'b00)? ReadData2E:
                        (ForwardBE == 2'b01)? WriteData3W:
                        (ForwardBE == 2'b10)? MEMResultM : 32'b0;
    assign SrcBE = (AluSrcE)? ExtendE : WriteDataE;

    //即写回阶段（WB）使用的目标寄存器
    assign WriteRegE = (RegDstE)? ((LinkDstE)? 32'd31 : RdE) : RtE;
    //选择 EXResultE 的值，作为执行阶段的输出
    assign EXResultE = (LinkE)? PCPlus4D : ALUResultE;

    Flopenrc #(144) piplinereg_EX_MEM(clk,rst,FlushM,~StallM,
                                        {PCE,opE,EXResultE,WriteDataE,WriteRegE,RdE,{ExcepTypeE[31:13],IntegerOverflowE,ExcepTypeE[11:0]}},
                                        {PCM,opM,EXResultM,WriteDataM,WriteRegM,RdM,ExcepTypeM});//EX_MEM
    //写入HILO寄存器
    HILO Hilo(clk,rst,~HiloStallM,HiloWriteE,HilotoRegE,HiloSrcE,SrcAE,MDUResultE,HiloutM);//MEM流水线刷新的时候,Hilo应该是阻塞
    //处理内存访问的译码操作，执行对内存的读取和写入
    //读取字节、字、半字
    Translator translator(opM,MemWriteM,MemReadM,MemEnableM,MemWenM,EXResultM,MemAddrM,ReadDataM,TReadDataM,WriteDataM,TWriteDataM,AdelM,AdesM);
    //输出错误编码
    Exception exception(rst,ExcepTypeM,AdelM,AdesM,EXcCode);
    //CP0模块处理与异常
    CP0 CP0(clk,rst,~StallM,CP0WriteM,RdM,SelM,WriteDataM,Int,EXcCode,Badaddr,DelaySlotM,PCM,
            CP0outM,BadVAddr,Count,Status,Cause,EPC,ExceptDealM);
    
    assign HiloStallM = StallM || FlushM;
    assign SelM = 3'b0;
    //指示当前指令是否是 ERET（异常返回）指令
    assign EretM = (ExceptDealM && (EXcCode == `Eret));
    //表示一个“错误地址”
    assign Badaddr = (AdelM || AdesM)? EXResultM : PCM;
    //根据RetSrcM选择来自HILO模块的结果还是EX阶段的结果
    assign MEMResultM = (RetSrcM[0])? HiloutM : EXResultM;

    Flopenrc #(133) piplinereg_MEM_WB(clk,rst,FlushW,~StallW,
                                    {PCM,TReadDataM,MEMResultM,WriteRegM,CP0outM},
                                    {PCW,ReadDataW,MEMResultW,WriteRegW,CP0outW});//MEM_WB
   //决定在WB阶段写回的数据来源，可能是CP0寄存器、内存读取结果或MEM阶段的结果
    assign WriteData3W = (RetSrcW[1])? CP0outW : 
                        (MemReadW)? ReadDataW : MEMResultW;
endmodule
