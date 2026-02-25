`timescale 1ns / 1ps

module tb_top;

    reg clk = 0;
    reg res = 1;

    // instanțiere top
    top uut (
        .clk(clk),
        .res(res)
    );

    // clock 10ns period
    always #5 clk = ~clk;

    initial begin
        // reset activ la început
        #20;
        res = 0;

        // rulează suficient timp
        #500;

        $stop;
    end
    initial begin
    #100;
    $display("IR = %h", uut.DP.IR);
end
    

endmodule