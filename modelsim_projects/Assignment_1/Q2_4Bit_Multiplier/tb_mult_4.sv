// ============================================================================
// tb_mult4
// ----------------------------------------------------------------------------
// Purpose:
//   Exhaustive simulation testbench for the 4×4 behavioural multiplier.
//   Sweeps all 256 input pairs and prints the result.
//
// Notes:
//   - Uses a tiny #1 time delay after driving inputs to allow combinational
//     logic to settle before $display.
//   - For self-checking, you can add an assertion comparing c to (a*b).
// ============================================================================
module tb_mult4;
    logic [3:0] a, b;
    logic [7:0] c;

    // DUT: behavioural unsigned 4×4 multiplier
    mult_4 uut (
        .a(a),
        .b(b),
        .c(c)
    );

    initial begin
        $display("Time | a    b    | c");
        $display("----------------------");
        
        // Exhaustive sweep: all 256 combinations
        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 16; j++) begin
                a = i[3:0];
                b = j[3:0];
                #1; // allow signals to propagate (combinational)
                $display("%4t | %2d x %2d = %3d (0x%02h)", $time, a, b, c, c);

                // OPTIONAL: self-check
                if (c !== (i*j)) begin
                    $error("Mismatch: %0d * %0d => got %0d, expected %0d", i, j, c, i*j);
                end
            end
        end
        
        $stop;
    end
endmodule
