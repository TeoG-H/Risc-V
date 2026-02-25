`timescale 1ns / 1ps


module top( input clk, input res);
    
	wire PCWriteCond;
	wire PCWrite;
	wire IorD;
	wire MemRead;
	wire MemWrite;
	wire MemtoReg;
	wire IRWrite;
	wire RegWrite; 
    wire ALUSrcA;
	wire [1:0] ALUSrcB; 
	wire [1:0] ALUOp; 
	wire PCSource;
	wire [6:0] op_code;
	
     data_path DP (
        .clk(clk),
        .res(res),

        .PCWriteCond(PCWriteCond),
        .PCWrite(PCWrite),
        .IorD(IorD),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .IRWrite(IRWrite),
        .RegWrite(RegWrite),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUOp(ALUOp),
        .PCSource(PCSource),

        .op_code(op_code)
    );

    control_path CP (
        .clk(clk),
        .res(res),
        .op_code(op_code),

        .PCWriteCond(PCWriteCond),
        .PCWrite(PCWrite),
        .IorD(IorD),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .IRWrite(IRWrite),
        .RegWrite(RegWrite),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUOp(ALUOp),
        .PCSource(PCSource)
    );   
endmodule
