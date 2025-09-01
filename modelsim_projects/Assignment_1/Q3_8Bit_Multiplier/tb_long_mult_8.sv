module tb_long_mult_8;
    logic [7:0] a, b;
    logic [15:0] c;

    long_mult_8 uut (
        .a(a),
        .b(b),
        .c(c)
    );

    initial begin
        // Header
        $display("   Time |   a   |   b   |     c");
        $display("----------------------------------");

        // Test 1: 5 * 10 = 50
        a = 8'd5; b = 8'd10;
        #10 $display("%6t | %3d  | %3d  | %5d", $time, a, b, c);

        // Test 2: 15 * 3 = 45
        a = 8'd15; b = 8'd3;
        #10 $display("%6t | %3d  | %3d  | %5d", $time, a, b, c);

        // Test 3: 255 * 2 = 510
        a = 8'd255; b = 8'd2;
        #10 $display("%6t | %3d  | %3d  | %5d", $time, a, b, c);

        // Test 4: 100 * 200 = 20000
        a = 8'd100; b = 8'd200;
        #10 $display("%6t | %3d  | %3d  | %5d", $time, a, b, c);

        $stop;
    end
endmodule
