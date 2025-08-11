module tb_multi_digit_display;

    // Parameters
    localparam int NUM_DIGITS = 4;

    // Signals
    logic [NUM_DIGITS*4-1:0] number;                   // Packed hex digits
    logic [NUM_DIGITS-1:0][6:0] seg;                    // Segments per digit

    // DUT (Device Under Test)
    multi_digit_display #(.NUM_DIGITS(NUM_DIGITS)) uut (
        .number(number),
        .seg(seg)
    );

    // Test sequence
    initial begin
        $display("Time | Number | Segments (per digit, MSB first)");
        $monitor("%4t | %h | %p", $time, number, seg);

        // Cycle through all possible values
        for (int val = 0; val < (1 << (NUM_DIGITS*4)); val++) begin
            number = val;
            #10;
        end

        $finish;
    end

endmodule
