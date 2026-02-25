`timescale 1ns / 1ps

module control_path(
    input clk,
    input res,
    input [6:0] op_code,
    output PCWriteCond,
    output PCWrite,
    output IorD,
    output MemRead,
    output MemWrite,
    output MemtoReg,
    output IRWrite,
    output RegWrite,
    output ALUSrcA,
    output [1:0] ALUSrcB,
    output [1:0] ALUOp,
    output PCSource
);
    
    reg [3:0] cs;
    reg [3:0] ns;
    reg [13:0] control; 
    
    assign {PCWriteCond, PCWrite, IorD, MemRead, MemWrite, MemtoReg, IRWrite, RegWrite, ALUSrcA, ALUSrcB, ALUOp, PCSource} = control; 
    
    // compute next state
    always@(cs or op_code)
        casex({cs,op_code})
            11'b0000_xxxxxxx: ns = 1; 
            
            11'b0001_0000011,         // lw
            11'b0001_0100011: ns = 2; // sw
            11'b0001_0000001: ns = 6;
            11'b0001_0110011: ns = 6; // R
            11'b0001_1100011: ns = 8; // beq
            11'b0001_0010011: ns = 9; // I (some) -- similar to R
            
            11'b0010_0000011: ns = 3; // lw
            11'b0010_0100011: ns = 5; // sw
            
            11'b0011_xxxxxxx: ns = 4; // lw
            
            11'b0100_xxxxxxx: ns = 0; // lw
            
            11'b0101_xxxxxxx: ns = 0; // sw
            
            11'b0110_xxxxxxx: ns = 7; // R
            11'b0111_xxxxxxx: ns = 0; // R
            
            11'b1000_xxxxxxx: ns = 0; // beq
            
            11'b1001_xxxxxxx: ns = 10; // I (some)
            11'b1010_xxxxxxx: ns = 0; // I (some)
            
            default:
                ns = 0;
                                    
        endcase
              
    // update current state
    always @(posedge clk)
        if (res == 1)
            cs <= 0;
        else
            cs <= ns; 
    
    // compute (and generate) outputs
    always @(cs)
        case(cs)  // PCWriteCond, PCWrite, IorD, MemRead, MemWrite, MemtoReg, IRWrite, RegWrite, ALUSrcA, ALUSrcB, ALUOp, PCSource
            4'b0000: control = 14'b0_1_0_1_0_0_1_0_0_01_00_0;
            4'b0001: control = 14'b0_0_0_0_0_0_0_0_0_10_00_x;
            4'b0010: control = 14'b0_0_0_0_0_0_0_0_1_10_00_x;
            4'b0011: control = 14'b0_0_1_1_0_0_0_0_x_xx_xx_x;
            4'b0100: control = 14'b0_0_0_0_0_1_0_1_x_xx_xx_x;
            4'b0101: control = 14'b0_0_1_0_1_0_0_0_x_xx_xx_x;
            4'b0110: control = 14'b0_0_0_0_0_0_0_0_1_00_10_x;
            4'b0111: control = 14'b0_0_0_0_0_0_0_1_x_xx_xx_x;
            4'b1000: control = 14'b1_0_0_0_0_0_0_0_1_00_01_1;
            4'b1001: control = 14'b0_0_0_0_0_0_0_0_1_10_11_x;
            4'b1010: control = 14'b0_0_0_0_0_0_0_1_x_xx_xx_x;
            default:
                control = 14'b0;            
            
        endcase
                
endmodule