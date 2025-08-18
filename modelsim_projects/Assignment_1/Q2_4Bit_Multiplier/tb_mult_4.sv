//`timescale 1ns/1ps

module tb_mult4;
    logic [3:0] a, b;
    logic [7:0] c;

    // Instantiate multiplier
    mult_4 uut (
        .a(a),
        .b(b),
        .c(c)
    );

    initial begin
        $display("Time | a    b    | c");
        $display("----------------------");
        
        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 16; j++) begin
                a = i;
                b = j;
                #1; // small delay for signals to settle
                $display("%4t | %d x %d = %d", $time, a, b, c);
            end
        end
        
        $stop;
    end
endmodule
