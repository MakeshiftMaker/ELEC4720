// ============================================================================
// tb_mult4_display
// ----------------------------------------------------------------------------
// Purpose:
//   Quick “integration” testbench that:
//     - drives a few (a,b) pairs,
//     - captures the raw 7-seg vector outputs for A, B, and the 2-digit product.
//
// What this DOES test:
//   - Module boundaries are connected,
//   - 7-seg busses toggle sensibly as (a,b) change,
//   - Bit packing for two-digit display isn't swapped.
//
// What this does NOT fully prove:
//   - Exact glyph pattern for each hex value (do that in the decoder TB),
//   - Ripple blanking behavior (covered in Q1 TB).
//
// NOTE: The DUT name here is 'mult4_display' (no underscore). If your top
//       module is called 'mult_4_display', either rename it or add the
//       1-line wrapper from the other file.
// ============================================================================
module tb_mult4_display;

    logic [3:0] a, b;
    logic [6:0] seg_a, seg_b;
    logic [13:0] seg_c; // two digits packed: {MS digit [13:7], LS digit [6:0]}

    // DUT (see name mismatch note above)
    mult4_display dut (
        .a(a),
        .b(b),
        .seg_a(seg_a),
        .seg_b(seg_b),
        .seg_c(seg_c)
    );

    initial begin
        // A few representative vectors, including corner cases
        a = 4'd3;  b = 4'd5;  #5;  $display("a=%2d, b=%2d, seg_a=%07b, seg_b=%07b, seg_c=%014b", a, b, seg_a, seg_b, seg_c);
        a = 4'd0;  b = 4'd0;  #5;  $display("a=%2d, b=%2d, seg_a=%07b, seg_b=%07b, seg_c=%014b", a, b, seg_a, seg_b, seg_c);
        a = 4'd9;  b = 4'd9;  #5;  $display("a=%2d, b=%2d, seg_a=%07b, seg_b=%07b, seg_c=%014b", a, b, seg_a, seg_b, seg_c);
        a = 4'd15; b = 4'd1;  #5;  $display("a=%2d, b=%2d, seg_a=%07b, seg_b=%07b, seg_c=%014b", a, b, seg_a, seg_b, seg_c);
        a = 4'd1;  b = 4'd15; #5;  $display("a=%2d, b=%2d, seg_a=%07b, seg_b=%07b, seg_c=%014b", a, b, seg_a, seg_b, seg_c);
        a = 4'd7;  b = 4'd8;  #5;  $display("a=%2d, b=%2d, seg_a=%07b, seg_b=%07b, seg_c=%014b", a, b, seg_a, seg_b, seg_c);

        a = 4'd0;  b = 4'd15; #5;  $display("a=%2d, b=%2d, seg_a=%07b, seg_b=%07b, seg_c=%014b", a, b, seg_a, seg_b, seg_c);
        a = 4'd15; b = 4'd15; #5;  $display("a=%2d, b=%2d, seg_a=%07b, seg_b=%07b, seg_c=%014b", a, b, seg_a, seg_b, seg_c);

        $finish;
    end

endmodule
