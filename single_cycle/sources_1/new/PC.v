`timescale 1ns / 1ps

module PC(input clk, input reset, input [31:0] PC_in, output reg [31:0] PC_out );

    always @(posedge clk or posedge reset)
    // la frontul pozitv sau la reset
    begin
    if(reset)
        PC_out <= 32'b0;
    else
        PC_out <= PC_in;
    end

endmodule


module adder_PC_4(input [31:0] adder_4_in, output [31:0] adder_4_out);

    assign adder_4_out = 4 +adder_4_in;

endmodule




module Instruction_Mem(input  [31:0] read_address, output [31:0] instruction);

    reg [7:0] mem [0:1023];      // 1024 bytes 
    reg [31:0] temp_mem [0:255];
    integer i;

    initial begin
        $readmemh("program.mem", temp_mem);

        for (i = 0; i < 64; i = i + 1) begin
            mem[i*4 + 3] = temp_mem[i][31:24];
            mem[i*4 + 2] = temp_mem[i][23:16];
            mem[i*4 + 1] = temp_mem[i][15:8];
            mem[i*4 + 0] = temp_mem[i][7:0];
        end
    end

    assign instruction = {mem[read_address+3],
                          mem[read_address+2],
                          mem[read_address+1],
                          mem[read_address]};

endmodule


module Reg_File(clk, reset, RegWrite, Rs1, Rs2, Rd, write_data, read_data1, read_data2);

    input clk, reset, RegWrite;
    input [4:0] Rs1, Rs2, Rd;
    input [31:0] write_data;
    output [31:0] read_data1, read_data2;
    
    reg [31:0] Registers[31:0];
    integer k;
    
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            for (k=0; k<32; k=k+1) begin
                Registers[k] <= 32'b0;
            end
        end
        else if (RegWrite  && (Rd != 5'd0)) begin  // registrul 0 trebuie sa fie mereu 0
            Registers[Rd] <= write_data;
        end
    end
    
    assign read_data1 = Registers[Rs1]; // data folosita e data care se gaseste in registrul Rs1 sau 2 
    assign read_data2 = Registers[Rs2];

endmodule




module ImmGen(Opcode, instruction, ImmExt);

    input [6:0] Opcode;
    input [31:0] instruction;
    output reg [31:0] ImmExt;
    
    always @(*)
    begin
        case (Opcode)
            7'b0000011: ImmExt = {{20{instruction[31]}}, instruction[31:20]};// la instructiune de tip I lw sau addi , valoarea imediata e pe 12 biti si ii exitnd semnul 
            7'b0100011: ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};// la inst de tip S val imediata e impartita in 2 ex sw
           7'b0010011: ImmExt = {{20{instruction[31]}}, instruction[31:20]}; // addi (I-type)
            7'b1100011: ImmExt = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};   // la inst de tip B  ex beq , la final e 0 pt Branch offset este mereu multiplu de 2. 
            default: ImmExt = 32'b0;
        endcase
    end

endmodule



module Control_Unit(
    input  [6:0] instruction,
    output reg Branch,  //pt PC la salturi intra in poarta and cu zero de la alu
    output reg MemRead, // citeste din mem
    output reg MemtoReg, // ce e la iesire 0-Alu , 1-data din mem
    output reg MemWrite, //scrie in mem
    output reg ALUSrc, // daca al 2 operand din alu e din rs sau val imm
    output reg RegWrite, // se scrie Rd la front clk
    output reg [1:0] ALUOp // 00 add, 01, sub, 10 de tip R ajunge in alucontrol
);

    always @(*) 
    begin
        case (instruction)
            7'b0110011: {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00100010; //R-type
            7'b0000011: {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b11110000; //lw
            7'b0100011: {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b10001000; //sw
            7'b1100011: {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00000101; //beq
            7'b0010011: {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b10100011; //I-type

            default:   {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00000000;
        endcase
    end

endmodule





module ALU_unit(A, B, ALU_control_in, ALU_Result, zero);

    input [31:0] A, B;
    input [3:0] ALU_control_in;
    output reg zero;
    output reg [31:0] ALU_Result;
    
    always @(ALU_control_in or A or B)
    begin
        case (ALU_control_in)
            4'b0000: begin ALU_Result = A & B; end
            4'b0001: begin ALU_Result = A | B; end
            4'b0010: begin ALU_Result = A + B; end
            4'b0110: begin ALU_Result = A - B; end
            4'b0011: begin ALU_Result = A ^ B; end
            default: ALU_Result = 32'b0;
            
        endcase
        zero = (ALU_Result == 0);// si intra in poarta si sa vada daca sare la alta adr
    end

endmodule



module ALU_Control(ALUOp, fun7, fun3, Control_out);

    input fun7;
    input [2:0] fun3;
    input [1:0] ALUOp;
    output reg [3:0] Control_out;
    
    always @(*)
    begin
    /*
        case ({ALUOp, fun7, fun3})
            6'b00_0_000: Control_out = 4'b0010;
            6'b10_0_000: Control_out = 4'b0010;
            6'b01_0_000: Control_out = 4'b0110;
            6'b10_0_111: Control_out = 4'b0000;
            6'b10_0_110: Control_out = 4'b0001;
            default:  Control_out = 4'b0000;
        endcase
        */
        case (ALUOp)
        2'b00: Control_out = 4'b0010; // ADD  (lw/sw)
        2'b01: Control_out = 4'b0110; // SUB  (beq)
        2'b10: begin // R-type
                case ({fun7, fun3})
                    4'b0_000: Control_out = 4'b0010; // ADD
                    4'b1_000: Control_out = 4'b0110; // SUB
                    4'b0_111: Control_out = 4'b0000; // AND
                    4'b0_110: Control_out = 4'b0001; // OR
                    4'b0_100: Control_out = 4'b0011; // XOR  << added
                    default:  Control_out = 4'b0010; // default ADD
                endcase
            end

            2'b11: begin // I-type ALU (addi/andi/ori/xori)
                case (fun3)
                    3'b000: Control_out = 4'b0010; // ADDI
                    3'b111: Control_out = 4'b0000; // ANDI
                    3'b110: Control_out = 4'b0001; // ORI
                    3'b100: Control_out = 4'b0011; // XORI
                    default: Control_out = 4'b0010;
                endcase
            end

        default: Control_out = 4'b0010;
    endcase
    end

endmodule




module Data_Memory(clk, reset, MemWrite, MemRead, read_address, Write_data, MemData_out);

    input clk, reset, MemWrite, MemRead;
    input [31:0] read_address, Write_data;
    output [31:0] MemData_out;
    
    reg [7:0] mem [0:1023];    // EXACT ca multicycle
    integer k;

    localparam DATA_OFFSET = 32'd256;

    wire [31:0] addr = read_address;

    always @(posedge clk or posedge reset)
    begin
        if (reset)
            for (k=0; k<1024; k=k+1)
                mem[k] <= 8'b0;
        else if (MemWrite)
        begin
            mem[addr + 3] <= Write_data[31:24];
            mem[addr + 2] <= Write_data[23:16];
            mem[addr + 1] <= Write_data[15:8];
            mem[addr + 0] <= Write_data[7:0];
        end
    end

    assign MemData_out = (MemRead) ?
                        {mem[addr+3],
                         mem[addr+2],
                         mem[addr+1],
                         mem[addr]} :
                         32'b0;
endmodule

module Mux(sel, A, B, Mux_out);

    input sel;
    input [31:0] A, B;
    output [31:0] Mux_out;
    
    assign Mux_out = (sel == 1'b0) ? A : B;

endmodule





module AND_gate(branch, zero, and_out);

    input branch, zero;
    output and_out;
    
    assign and_out = branch & zero;

endmodule


module Adder(in_1, in_2, Sum_out);

input [31:0] in_1, in_2;
output [31:0] Sum_out;

assign Sum_out = in_1 + in_2;

endmodule







