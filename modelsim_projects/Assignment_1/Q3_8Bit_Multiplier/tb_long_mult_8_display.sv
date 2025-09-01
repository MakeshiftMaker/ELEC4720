module tb_long_mult_8_display;

    logic [7:0] a, b;
    logic [7*4-1:0] seg_c; // two digits packed: {MS digit [13:7], LS digit [6:0]}

    // DUT (see name mismatch note above)
    long_mult_8_display dut (
        .a(a),
        .b(b),
        .seg_c(seg_c)
    );

    initial begin
        $display("   time |    a  |    b  | product (on 7-seg bus)");
        $display("-------------------------------------------------");

        // Small values
        a = 8'd3;   b = 8'd5;    #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd9;   b = 8'd9;    #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);

        // Edge cases
        a = 8'd0;   b = 8'd0;    #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd0;   b = 8'd200;  #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd255; b = 8'd1;    #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);

        // Larger products
        a = 8'd100; b = 8'd200;  #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd123; b = 8'd45;   #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd255; b = 8'd255;  #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);

        $finish;
    end

endmodule