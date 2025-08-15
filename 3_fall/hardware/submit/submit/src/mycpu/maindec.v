`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/09 08:52:20
// Design Name: 
// Module Name: maindec
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

module maindec(op,Funct,rs,rt,eret,RegWrite,RegDst,RetSrc,AluSrc,MemWrite,MemRead,HiloWrite,HilotoReg,HiloSrc,Branch,Jump,JumpSrc,Link,LinkDst,Break,Syscall,CP0Write,Reserve);
    input [5:0] op;
    input [5:0] Funct;
    input [4:0] rs;
    input [4:0] rt;
    input eret;

    output RegWrite;
    output RegDst;
    output [1:0] RetSrc;
    output AluSrc;
    output MemWrite;
    output MemRead;
    output HiloWrite;
    output HilotoReg;
    output HiloSrc;
    output [1:0] Branch;
    output Jump;
    output JumpSrc;
    output Link;
    output LinkDst;
    output Break;
    output Syscall;
    output Reserve;
    output CP0Write;

    reg [19:0] Controls;
// RegWrite:写寄存器堆
// RegDst:目的寄存器号来源,0->Rt字段,1->Rd字段
// AluSrc:第二个ALU操作数源,0->第二个寄存器堆输出,1->立即数符号扩展
// RetSrc:MEMResultM源,0->E0ResultM,1->HILO寄存器,2->CP0寄存器
// MemWrite:写数据存储器
// MemRead:读数据存储器,写入寄存器数据源(等效MemtoReg),0->来自Result,1->来自数据存储器()
// HiloWrite:写HILO寄存器
// HilotoReg:读/写HILO寄存器源,0->Lo字段,1->Hi字段
// HiloSrc:写HILO寄存器源,0->ALU,1->数据移动指令
// Branch:高位为1表示为BLTZ或BGEZ指令,低位为1表示为其他非Link类型的Branch指令
// Jump:Jump指令
// JumpSrc:Jump的地址源,0->立即数,1->rs寄存器
// Link:ResultE源,0->来自ALUResultE,1->来自Xal(r)指令指定的PC值
// LinkDst:WriteRegE源,0->来自目的寄存器号(rd),1->$ra
// Eret:ERET指令,直接在Datapth中判断(全字段匹配)并接入控制器,以免误判为保留指令
// Break:BREAK指令
// Syscall:SYSCALL指令
// Reserve:保留的指令
// CP0Write:写CP0寄存器
// DelaySlot:延迟槽指令,在Controller中连接BranchD,JumpD至IF阶段判断
assign {RegWrite,RegDst,AluSrc,RetSrc,
        MemWrite,MemRead,
        HiloWrite,HilotoReg,HiloSrc,
        Branch,
        Jump,JumpSrc,
        Link,LinkDst,
        Break,Syscall,Reserve,
        CP0Write} = Controls;
always @(*) 
begin
    if(eret)
        Controls <= 20'b00000_00_000_00_00_00_000_0;
    else begin
        case (op)
            `R_TYPE:
                case (Funct)
                    `AND,`OR,`XOR,`NOR,`SLL,`SRL,`SRA,`SLLV,`SRLV,`SRAV,`ADD,`ADDU,`SUB,`SUBU,`SLT,`SLTU: Controls <= 20'b11000_00_000_00_00_00_000_0;
                    `MFHI: Controls <= 20'b11001_00_010_00_00_00_000_0;
                    `MFLO: Controls <= 20'b11001_00_000_00_00_00_000_0;
                    `MTHI: Controls <= 20'b00000_00_111_00_00_00_000_0;
                    `MTLO: Controls <= 20'b00000_00_101_00_00_00_000_0;
                    `MULT,`MULTU,`DIV,`DIVU: Controls <= 20'b00000_00_100_00_00_00_000_0;
                    `JR: Controls <= 20'b00000_00_000_00_11_00_000_0;
                    `JALR: Controls <= 20'b11000_00_000_00_11_10_000_0;
                    `BREAK: Controls <= 20'b00000_00_000_00_00_00_100_0;
                    `SYSCALL: Controls <= 20'b00000_00_000_00__00_00_010_0;
                    default: Controls <= 20'b00000_00_000_00_00_00_001_0;
                endcase
            `ANDI,`XORI,`ORI,`LUI,`ADDI,`ADDIU,`SLTI,`SLTIU: Controls <= 20'b10100_00_000_00_00_00_000_0;
            `BEQ,`BNE,`BLEZ,`BGTZ: Controls <= 20'b00000_00_000_01_00_00_000_0;
            `REGIMM_INST: Controls <= (rt == `BLTZ || rt == `BGEZ)? 20'b00000_00_000_10_00_00_000_0 :20'b11000_00_000_10_00_11_000_0;
            `J: Controls <= 20'b00000_00_000_00_10_00_000_0;
            `JAL: Controls <= 20'b11000_00_000_00_10_11_000_0;
            `SW,`SH,`SB: Controls <= 20'b00100_10_000_00_00_00_000_0;
            `LW,`LH,`LHU,`LB,`LBU: Controls <= 20'b10100_01_000_00_00_00_000_0;
            `SPECIAL3_INST:
                case(rs)
                `MFC0: Controls <= 20'b10010_00_000_00_00_00_000_0;
                `MTC0: Controls <= 20'b00000_00_000_00_00_00_000_1;
                default:  Controls <= 20'b00000_00_000_00_00_00_001_0;
                endcase
            default: Controls <= 20'b00000_00_000_00_00_00_001_0;
        endcase
    end
end
endmodule
