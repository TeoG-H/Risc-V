`timescale 1ns/1ps

module reg_tb;

reg clk;
reg reset;

// instanțiem procesorul
top DUT (
    .clk(clk),
    .reset(reset)
);

// generare clock 10ns
always #5 clk = ~clk;

initial begin

    clk = 0;
    reset = 1;

    #10;
    reset = 0;

    // lăsăm să ruleze câteva cicluri
    #100;

    $finish;

end

endmodule
