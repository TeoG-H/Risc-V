`timescale 1ns/1ps

module reg_tb;

    reg clk;
    reg reset;
    
    wire [31:0] PC_debug;
    wire [31:0] instruction_debug;
    wire RegWrite_debug;
    wire [4:0] Rd_debug;
    wire [31:0] WriteBack_debug;
    wire MemWrite_debug;
    wire [31:0] MemAddress_debug;
    wire [31:0] MemWriteData_debug;


    top DUT ( clk,
            reset,
            PC_debug,
            instruction_debug,
            RegWrite_debug,
            Rd_debug,
            WriteBack_debug,
            MemWrite_debug,
            MemAddress_debug,
            MemWriteData_debug);
    
    
   always #5 clk = ~clk;


  reg [31:0] model_reg [0:31];
  reg [7:0]  model_mem [0:1023];
  reg [31:0] model_pc;

  integer i;

// functii care ma ajuta sa extind semnul le folosesc mai jos
  function [31:0] sext12(input [11:0] imm);
    sext12 = {{20{imm[11]}}, imm};
  endfunction

  function [31:0] imm_i(input [31:0] instr);
    imm_i = sext12(instr[31:20]);
  endfunction

  function [31:0] imm_s(input [31:0] instr);
    imm_s = sext12({instr[31:25], instr[11:7]});
  endfunction

  function [31:0] imm_b(input [31:0] instr);
    imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
  endfunction

  function [31:0] load_word(input [31:0] addr);
    load_word = {model_mem[addr+3],model_mem[addr+2],model_mem[addr+1],model_mem[addr]};
  endfunction

  task store_word(input [31:0] addr, input [31:0] data);
    begin
      model_mem[addr+3] = data[31:24];
      model_mem[addr+2] = data[23:16];
      model_mem[addr+1] = data[15:8];
      model_mem[addr]   = data[7:0];
    end
  endtask


  initial begin
    clk = 0;
    reset = 1;

    for (i=0; i<32; i=i+1)
      model_reg[i] = 0;

    for (i=0; i<1024; i=i+1)
      model_mem[i] = 0;

    model_pc = 0;

    #15;
    reset = 0;

    #200;
    $display("E PREA FRUMOS DACA VAD ASTA");
    $finish;
  end

      reg [31:0] expected_wb; // wb urmareste write_back adica iesirea din alu care urmeaza sa fie scris in regd
      reg [31:0] expected_pc;
      reg expected_regwrite;
      reg expected_memwrite;
      reg [6:0] opcode;
      reg [2:0] funct3;
      reg       funct7;
      reg [4:0] rs1, rs2, rd;
      reg [31:0] rs1_val, rs2_val;
      
      
  always @(negedge clk) begin  // modific si verific la negedge ca sa fie semnalele stabile 
    if (!reset) begin

      opcode   = instruction_debug[6:0];
      funct3   = instruction_debug[14:12];
      funct7 = instruction_debug[30];
      rs1      = instruction_debug[19:15];
      rs2      = instruction_debug[24:20];
      rd       = instruction_debug[11:7];
      rs1_val = model_reg[rs1];
      rs2_val = model_reg[rs2];
      
      expected_regwrite = 0;
      expected_memwrite = 0;
      expected_wb = 0;
      expected_pc = PC_debug + 4;

      if (opcode == 7'b0110011) begin // R
        expected_regwrite = 1;

        case ({funct7, funct3})
          4'b0_000: expected_wb = rs1_val + rs2_val;
          4'b1_000: expected_wb = rs1_val - rs2_val;
          4'b0_111: expected_wb = rs1_val & rs2_val;
          4'b0_110: expected_wb = rs1_val | rs2_val;
          4'b0_100: expected_wb = rs1_val ^ rs2_val;
          default: expected_wb = 0;
        endcase
      end

      if (opcode == 7'b0010011) begin // I
        expected_regwrite = 1;

        case (funct3)
          3'b000: expected_wb = rs1_val + imm_i(instruction_debug);
          3'b111: expected_wb = rs1_val & imm_i(instruction_debug);
          3'b110: expected_wb = rs1_val | imm_i(instruction_debug);
          3'b100: expected_wb = rs1_val ^ imm_i(instruction_debug);
        endcase
      end

      if (opcode == 7'b0000011) begin //LW
        expected_regwrite = 1;
        expected_wb = load_word(rs1_val + imm_i(instruction_debug));
      end

      if (opcode == 7'b0100011) begin //SW
        expected_memwrite = 1; // in sw memwrite trebuie sa fie 1
      end

      if (opcode == 7'b1100011) begin //beq
        if (rs1_val == rs2_val)
          expected_pc = PC_debug + imm_b(instruction_debug);
      end

// aici verific niste functionalitati generale
      if (RegWrite_debug !== expected_regwrite) begin
        $display("RegWrite ERROR at PC=%h", PC_debug);
        $stop;
      end

      if (MemWrite_debug !== expected_memwrite) begin
        $display("MemWrite ERROR at PC=%h", PC_debug);
        $stop;
      end
//aici verific daca rezultatul pt wb e bun
      if (expected_regwrite) begin
        if (WriteBack_debug !== expected_wb) begin
          $display("WB ERROR at PC=%h expected=%h got=%h",
                    PC_debug, expected_wb, WriteBack_debug);
          $stop;
        end
      end
// PC sa creasca mereu corect sa fie alineat
      if (PC_debug % 4 != 0) begin
        $display("PC ALIGNMENT ERROR");
        $stop;
      end

      //aici modific reg si memoria ca dupa sa pot sa analizez in continuare corect
      if (expected_regwrite && rd != 0)
        model_reg[rd] = expected_wb;

      if (expected_memwrite)
        store_word(rs1_val + imm_s(instruction_debug), rs2_val);

      model_reg[0] = 0;
      model_pc = expected_pc;

    end
  end

endmodule



