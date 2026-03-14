`timescale 1ns / 1ps

module top(input clk,
            input reset,
            output [31:0] PC_debug,
            output [31:0] instruction_debug,
            output RegWrite_debug,
            output [4:0] Rd_debug,
            output [31:0] WriteBack_debug,
            output MemWrite_debug,
            output [31:0] MemAddress_debug,
            output [31:0] MemWriteData_debug);



    wire [31:0] PC_top, PCin_top, NextPC_top, instruction_top, Rd1_top, Rd2_top, ImmExt_top, mux1_top, Sum_out_top,   address_top, Memdata_top, WriteBack_top;
    wire RegWrite_top, ALUSrc_top, zero_top, branch_top, sel2_top, MemtoReg_top, MemWrite_top, MemRead_top;
    wire [1:0] ALUOp_top;
    wire [3:0] control_top;
    
    
    assign PC_debug = PC_top;
    assign instruction_debug = instruction_top;
    assign RegWrite_debug = RegWrite_top;
    assign Rd_debug = instruction_top[11:7];
    assign WriteBack_debug = WriteBack_top;
    assign MemWrite_debug = MemWrite_top;
    assign MemAddress_debug = address_top;
    assign MemWriteData_debug = Rd2_top;
    

    PC   PC_real( .clk(clk), .reset(reset), .PC_in(PCin_top), .PC_out(PC_top));
    
    
    adder_PC_4    PC_Adder(.adder_4_in(PC_top), .adder_4_out(NextPC_top));
    
    
    Instruction_Mem  Inst_Memory(.read_address(PC_top), .instruction(instruction_top) );
    
    
    Reg_File Reg_File( .clk(clk), .reset(reset), .RegWrite(RegWrite_top), .Rs1(instruction_top[19:15]), .Rs2(instruction_top[24:20]), .Rd(instruction_top[11:7]), .write_data(WriteBack_top),
                       .read_data1(Rd1_top), .read_data2(Rd2_top));
   
    
    ImmGen ImmGen(  .instruction(instruction_top), .ImmExt(ImmExt_top));
    

    Control_Unit Control_Unit( .instruction(instruction_top[6:0]), 
                               .Branch(branch_top), .MemRead(MemRead_top), .MemtoReg(MemtoReg_top), .ALUOp(ALUOp_top), .MemWrite(MemWrite_top), .ALUSrc(ALUSrc_top), .RegWrite(RegWrite_top) );
    
    
    
    ALU_Control ALU_Control( .ALUOp(ALUOp_top), .fun7(instruction_top[30]), .fun3(instruction_top[14:12]),    .Control_out(control_top));
    
    Mux ALU_mux(.sel(ALUSrc_top), .A(Rd2_top),.B(ImmExt_top),  .Mux_out(mux1_top));


    ALU_unit ALU( .A(Rd1_top), .B(mux1_top), .ALU_control_in(control_top),
                  .ALU_Result(address_top), .zero(zero_top));

 
    Adder Adder(.in_1(PC_top), .in_2(ImmExt_top), .Sum_out(Sum_out_top));
      
    AND_gate AND1(.branch(branch_top),.zero(zero_top),.and_out(sel2_top) );
     
    Mux Adder_mux(.sel(sel2_top), .A(NextPC_top), .B(Sum_out_top),.Mux_out(PCin_top));
  
    Data_Memory Data_mem(.clk(clk),.reset(reset),.MemWrite(MemWrite_top),.MemRead(MemRead_top),.read_address(address_top),.Write_data(Rd2_top),
                         .MemData_out(Memdata_top));
        
    Mux Memory_mux( .sel(MemtoReg_top), .A(address_top),.B(Memdata_top), .Mux_out(WriteBack_top));
    
    endmodule




