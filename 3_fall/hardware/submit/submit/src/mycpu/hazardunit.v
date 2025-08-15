`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/16 22:05:42
// Design Name: 
// Module Name: hazardunit
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


module hazardunit(MemReadE,RegWriteE,MemReadM,RegWriteM,RegWriteW,RsD,RtD,PCSrcD,BranchD,JumpD,JumpSrcD,RsE,RtE,WriteRegE,WriteRegM,WriteRegW,MDUReadyE,RetSrcE,RetSrcM,
ExceptDealM,MemStall,
StallF,StallD,StallE,StallM,StallW,ForwardAD,ForwardBD,FlushD,FlushE,FlushM,FlushW,ForwardAE,ForwardBE);
    input MemReadE;
    input RegWriteE;
    input MemReadM;
    input RegWriteM;
    input RegWriteW;
    input [4:0] RsD,RtD;
    input PCSrcD;
    input [1:0] BranchD;
    input JumpD;
    input JumpSrcD;
    input [4:0] RsE,RtE;
    input [4:0] WriteRegE;
    input [4:0] WriteRegM;
    input [4:0] WriteRegW;
    input MDUReadyE;//MDU
    input [1:0] RetSrcE;
    input [1:0] RetSrcM;

    input ExceptDealM;
    input MemStall;

    output StallF;
    output StallD;
    output StallE;
    output StallM;
    output StallW;
    output [1:0] ForwardAD,ForwardBD;
    output FlushD;
    output FlushE;
    output FlushM;
    output FlushW;
    output [1:0] ForwardAE,ForwardBE;

    wire stalls;
    wire lwstall;
    wire jumpstall;
    wire branchstall;

    wire cp0stall;
    wire MemStall;

    //数据冒险
    assign ForwardAE = (RegWriteM && (WriteRegM != 0) && (WriteRegM == RsE))? 2'b10 ://EX冒险前推信号
                    (RegWriteW && (WriteRegW != 0) && (WriteRegW == RsE))? 2'b01 : 2'b00;//MEM冒险前推信号
    assign ForwardBE=(RegWriteM && (WriteRegM != 0) && (WriteRegM == RtE))? 2'b10 ://EX冒险前推信号
                    (RegWriteW && (WriteRegW != 0) && (WriteRegW == RtE))? 2'b01 : 2'b00;//MEM冒险前推信号
                    
    //lw冒险阻塞信号(充分不必要条件,在后一条指令为某些指令(见"指令及对应机器码")时可能会造成不必要的阻塞,前述的前推控制信号大概也有类似问题)
    assign lwstall = ((RtE != 0) && (RsD == RtE) || (RtD == RtE)) && MemReadE;
    
    //控制冒险
    //仅由$ra产生的Branch阻塞其实可以靠前推解决(因为EX级不需要进行另外的计算),但是应该没什么必要(有什么情况会需要$ra参与比较吗?)
    
    assign jumpstall =  JumpSrcD && ((RegWriteE && (WriteRegE != 0) && (WriteRegE == RsD)) || 
                                    ((MemReadM || RetSrcM[1]) && (WriteRegM == RsD)));
    assign branchstall = BranchD[1]? (RegWriteE && (WriteRegE != 0) && (WriteRegE == RsD)) || 
                                    ((MemReadM || RetSrcM[1]) && (WriteRegM == RsD)) : 
                        BranchD[0]? (RegWriteE && (WriteRegE != 0) && ((WriteRegE == RsD) || (WriteRegE == RtD))) || 
                                    ((MemReadM || RetSrcM[1]) && ((WriteRegM == RsD) || (WriteRegM == RtD))): 1'b0;//EX冒险阻塞信号
    
    assign ForwardAD = (RegWriteM && (WriteRegM != 0) && (WriteRegM == RsD))? 2'b10 :
                        (RegWriteW && (WriteRegW != 0) && (WriteRegW == RsD))? 2'b01 : 2'b00;
    assign ForwardBD = (RegWriteM && (WriteRegM != 0) && (WriteRegM == RtD))? 2'b10 :
                        (RegWriteW && (WriteRegW != 0) && (WriteRegW == RtD))? 2'b01 : 2'b00;

    assign cp0stall = ((RtE != 0) && (RsD == RtE) || (RtD == RtE)) && RetSrcE[1];

    //阻塞与刷新
    assign stalls = lwstall || jumpstall || branchstall || cp0stall;
    //触发异常处理时已经进入流水线的指令可能会阻塞PC,导致PC无法取得异常处理程序地址;由于这些指令此后将被清除,因此其触发的StallF需要一并进行清除
    assign StallF = MemStall || (~ExceptDealM) && (stalls || (~MDUReadyE)) ;//lw,beq和乘除法指令均需阻塞ID级和IF级指令
    assign StallD = MemStall || stalls || (~MDUReadyE);
    assign StallE = MemStall || (~MDUReadyE);//乘除法指令还需要阻塞EX级
    assign StallM = MemStall;
    assign StallW = MemStall;
    //beq指令分支发生时或j指令执行时,如果编译器没有调度合适的延迟槽指令,则需要清空ID级指令(样例默认有)
    // assign FlushD = PCSrcD | JumpD;
    assign FlushD = (~MemStall) && ExceptDealM;
    assign FlushE = (~MemStall) && (ExceptDealM || stalls);//lw数据冒险或beq(数据)控制冒险均在EX级判断,需清空ID级指令影响
    assign FlushM = (~MemStall) && (ExceptDealM || (~MDUReadyE));//若乘除法未结束,则需清空其对MEME级的影响
    assign FlushW = (~MemStall) && ExceptDealM;
endmodule