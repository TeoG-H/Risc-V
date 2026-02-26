`timescale 1ns / 1ps

module tb_top;

    reg clk = 0;
    reg res = 1;

    top uut (
        .clk(clk),
        .res(res)
    );

    
    always #5 clk = ~clk;

    initial begin
        
        #20;
        res = 0;
        #700;
        $stop;
    end

    

endmodule