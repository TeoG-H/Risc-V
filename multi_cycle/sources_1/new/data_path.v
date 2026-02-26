`timescale 1ns / 1ps


module data_path(
	input clk,
	input res,
	input PCWriteCond, // valoarea sa intra intr-o poarta si cu ZERO de la ALU , deci cand e o instructiune de salt PCWriteCond trebuie sa fie 1 
	input PCWrite, // valoarea sa intra intr-o poarta sau cu rezultatul de la PCWriteCond & ZERO, Cand e pe 1 val se lui PC se actualizeaza
	input IorD, // cand e pe 0 foloseste val din PC pt a accesa memoria, cand e pe  foloseste rezultatul de la ALU 
	input MemRead, // cand e pe 1 citeste valoarea din memorie specificata de adresa (fie PC fie rez Alu in functie de IORD), ce citesc se trimite prin MemData
    input MemWrite, // cand e pe 1 scrie in mem la adresa specificata,valoarea scrisa fiind cea din Write Data
    input MemtoReg, // controleaza val scrisa in registrul micropro: cand e 0 valoarea e rez din alu cand e 1 e din MDR
    input IRWrite, // cand e 1 val citita din mem e scrisa in reg IR 
	input RegWrite, //  cand e 1 scrie in RD specificat de write reg scrie val write data
	// in alu am 2 parametri care intra si sunt controlati de alusrcA si B
	input ALUSrcA,  // cand e 0 e val din PC (spre ex cand calc o adresa) cand e 1 e val din reg A (cand adun 2 nr)
	input [1:0] ALUSrcB,  // cand e 00 val provine din reg B , cand e 01 val e 4 (PC+4), cand e 10 val e o val imediata 
	input [1:0] ALUOp,  // cand e  00 e adunare (pt lw, sw) cand e 01 e scadere (pt beq) cand e 01 se det instructiunea in functie de campul funct 
	input PCSource, // cand e 0 ai PC+4 cand e 1 ai ALUOut
	output [6:0] op_code);

// in reg am tot ce vreau sa se pastreze intre cicluri si in wire fire intre module 
reg [31:0] PC, IR, ALUout, A, B, MDR, alu, imm ;
reg [7:0] mem [0:1023]; // am un vector de 1024 de locatii (bytes), fiecare locatie cu cate 8 (biti)
reg [31:0] regs [0:31];// am 32 de registre pe 32 de biti 
wire [31:0] addr_mem;
wire Zero;
wire [31:0] da, db, opA, opB;
wire [4:0] ra, rb, rd;
integer i;
reg [31:0] temp_mem [0:512];

//1 byte=8 biti 1 word=4 byte=32 biti
initial begin
	$readmemh("mem.mem", temp_mem);
	 $display("temp_mem[0] = %h", temp_mem[0]);
    $display("temp_mem[1] = %h", temp_mem[1]);
    `define TEXT_OFFSET 0
    `define TEXT_WORDS 64
    `define DATA_OFFSET 256
    `define DATA_WORDS (1024-`DATA_OFFSET)
    // pana la 64 ca de la 0 la 256 am  256 de bytes, o instructiune are 4 bytes deci daca fac 256.4 rezulta 64 practic 64 de instructiuni
    for (i = 0; i < 64; i = i + 1) begin
    //salvez tot din fisier in temp_mem, apoi o parcurg pe toata si o impart in bytes si o salvez in memorie
     	mem[i*4 + 3+`TEXT_OFFSET] = temp_mem[i+`TEXT_OFFSET][31:24];
      mem[i*4 + 2+`TEXT_OFFSET] = temp_mem[i+`TEXT_OFFSET][23:16];
      mem[i*4 + 1+`TEXT_OFFSET] = temp_mem[i+`TEXT_OFFSET][15:8];
      mem[i*4 + 0+`TEXT_OFFSET] = temp_mem[i+`TEXT_OFFSET][7:0];
    end
    // la fel ca mai sus, de la 256 incepe 
    for (i = 0; i < ((1024-256)/4); i = i + 1) begin
      mem[i*4 + 3+`DATA_OFFSET] = temp_mem[i+`DATA_OFFSET][31:24];
      mem[i*4 + 2+`DATA_OFFSET] = temp_mem[i+`DATA_OFFSET][23:16];
      mem[i*4 + 1+`DATA_OFFSET] = temp_mem[i+`DATA_OFFSET][15:8];
      mem[i*4 + 0+`DATA_OFFSET] = temp_mem[i+`DATA_OFFSET][7:0];
    end

$display("mem[0] = %h", mem[0]);
    $display("mem[1] = %h", mem[1]);
    $display("mem[2] = %h", mem[2]);
    $display("mem[3] = %h", mem[3]);
end


// PC 
always@(posedge clk)
	if (res == 1) 
		PC <= 0;
	else
		casex({PCWrite, PCWriteCond, Zero, PCSource})
		  4'b1_x_x_0: PC <= alu;
		  4'b1_x_x_1: PC <= ALUout;
		  4'b0_1_1_0: PC <= alu;
		  4'b0_1_1_1: PC <= ALUout - 4; 
		  default:
		      PC <= PC;
		endcase
		
assign addr_mem = (IorD == 0) ? PC : ALUout;
		
// imm, la fiecare se exinde semnul
always@(IR) begin
	case(IR[6:0])
        7'b0000011,
        7'b0001111,
        7'b0011011,
        7'b1100111,
        7'b1110011,
        7'b0010011: imm = { {20{IR[31]}}, IR[31:20]}; // I 
        7'b0100011: imm = { {20{IR[31]}}, IR[31:25], IR[11:7]}; // S 
        7'b1100011: imm = { {20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};    //B         
        7'b1101111: imm = { {12{IR[31]}}, IR[19:12], IR[20], IR[30:25], IR[11:8], 1'b0};     //J        
        7'b0010111,
        7'b0110111: imm = { IR[31:12], {12{1'b0}}}; //U
        default:
            imm = 32'h0000_0000;
	endcase
end


// IR 
always@(posedge clk)
    if (res == 1) 
		IR <= 0;
	else
	   if (IRWrite==1)
	    IR <= {mem[addr_mem+3], mem[addr_mem+2], mem[addr_mem+1], mem[addr_mem]};

assign ra = IR[19:15];
assign rb = IR[24:20];
assign rd = IR[11:7];	

integer j;
always @(posedge clk)
    if (res) begin
        for (j = 0; j < 32; j = j + 1)
            regs[j] <= 0;
    end
    else if (rd != 0 && RegWrite)
        regs[rd] <= (MemtoReg) ? MDR : ALUout;

assign da = regs[ra];
assign db = regs[rb];


always@(posedge clk)
	if (MemWrite == 1) begin
		mem[addr_mem+3]	<= B[31:24];
		mem[addr_mem+2] <= B[23:16];
		mem[addr_mem+1] <= B[15:8];
		mem[addr_mem+0] <= B[7:0];	
	end
	
assign op_code = IR[6:0];

always@(posedge clk) begin
	MDR[31:24] 	<= mem[addr_mem+3];
	MDR[23:16] 	<= mem[addr_mem+2];
	MDR[15:8] 	<= mem[addr_mem+1];
	MDR[7:0] 	<= mem[addr_mem];	
end

always@(posedge clk)
	A <= da;

always@(posedge clk)
	B <= db;


assign Zero = (alu == 0) ? 1 : 0;

assign opA = (ALUSrcA == 1) ? A : PC;

assign opB = (ALUSrcB == 2'b00) ? 	B :
			 ((ALUSrcB == 2'b01) ? 	4 :
			 ((ALUSrcB == 2'b10) ? 	imm : 0 ));


// ALU 
always@(ALUOp or IR[31:25] or IR[14:12] or opA or opB)
    casex({ALUOp, IR[31:25], IR[14:12]})
        12'b00_xxxxxxx_xxx: alu = opA + opB; // lw sw
        12'b01_xxxxxxx_xxx: alu = opA - opB; // beq
            
        12'b10_0000000_000: alu = opA + opB; // add
        12'b10_0100000_000: alu = opA - opB; // sub            
        12'b10_0000000_111: alu = opA & opB; // and
        12'b10_0000000_110: alu = opA | opB; // or
        12'b10_0000000_100: alu = opA ^ opB; // xor
       
            
        12'b11_xxxxxxx_000: alu = opA + opB; // addi
        12'b11_xxxxxxx_111: alu = opA & opB; // andi
        12'b11_xxxxxxx_110: alu = opA | opB; // ori
        12'b11_xxxxxxx_100: alu = opA ^ opB; // xori           
            
        default:
            alu = 32'b0;
	endcase

always@(posedge clk)
	ALUout <= alu;



endmodule
