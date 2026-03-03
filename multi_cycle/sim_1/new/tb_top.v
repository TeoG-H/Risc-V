`timescale 1ns / 1ps

module tb_top;

    reg clk = 0;
    reg res = 1;

    integer instr_count = 0;
    integer cycle_count = 0;

    reg [3:0] prev_state;

    top risc( clk, res);

    
    always #5 clk = ~clk;

    initial begin
        
        #20;
        res = 0;
        #700;
        $display("TEST PASSED");
        $stop;
    end
 



    always @(posedge clk) begin
        if (!res) begin
            if (prev_state != 0 && risc.CP.cs == 0) begin
                instr_count = instr_count + 1;
                $display("Instruction %0d commpleted", instr_count);
                $display("New PC = %h", risc.DP.PC);
                $display("IR     = %h", risc.DP.IR);
                end 
            prev_state <= risc.CP.cs;
        end
    end
    
    always @(posedge clk) begin
        if (!res) begin
    
            if (risc.RegWrite && risc.DP.rd != 0)
                $display("RegWrite  x%0d = %h",risc.DP.rd,(risc.MemtoReg ? risc.DP.MDR : risc.DP.ALUout));
            if (risc.DP.MemWrite)
                $display("MemWrite  addr=%h data=%h", risc.DP.addr_mem, risc.DP.B);
        end
    end

    integer counter = 0;
    reg [3:0] last_state;

    always @(posedge clk) begin
        if (!res) begin
            if (risc.CP.cs == last_state)
                counter = counter + 1;
            else
                counter = 0;

            if (counter > 10) begin
                $display("FSM  stuck in state %0d", risc.CP.cs);
                $stop;
            end

            last_state <= risc.CP.cs;
        end
    end


endmodule