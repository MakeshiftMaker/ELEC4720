// File: long_mult_4.sv
// 4-bit multiplier using long multiplication
module mult4 (
    input  logic [3:0] a, // 4-bit input A
    input  logic [3:0] b, // 4-bit input B
    output logic [7:0] c  // 8-bit product
);
    logic [7:0] p0, p1, p2, p3;
    // Partial products

    //due to us using long multiplication (hardware) and not descriptive multiplication, the fpga will not be using the implemented arithmetic blocks, which results in more blocks being used in an inefficient way

    assign p0 = {4'b0000, a & {4{b[0]}}};
    assign p1 = {3'b000,  a & {4{b[1]}}, 1'b0};
    assign p2 = {2'b00,   a & {4{b[2]}}, 2'b00};
    assign p3 = {1'b0,    a & {4{b[3]}}, 3'b000};

    // Sum the partial products
    assign c = p0 + p1 + p2 + p3;

endmodule

// File: mult_4.sv
// ============================================================================
// mult_4
// ----------------------------------------------------------------------------
// Purpose:
//   4-bit × 4-bit unsigned multiplier producing an 8-bit product.
//   This is the behavioural (high-level) version using the '*' operator.
//
// Interface:
//   a[3:0] : multiplicand (unsigned)
//   b[3:0] : multiplier   (unsigned)
//   c[7:0] : product      (unsigned)
//
// Notes:
//   * Synthesis will usually infer an FPGA DSP/multiplier block here.
//   * For the “long multiplication” structural version (ANDs + adders),
//     implement in a separate module for comparison.
// ============================================================================
module mult_4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    output logic [7:0] c
);
    // Single-cycle combinational multiply (unsigned).
    // If you ever need signed, cast both operands to signed before '*'.
    //this implementation allows the fpga board to use implemented artihmetic blocks making it more efficient and fast
    assign c = a * b;
endmodule

// File: multi_segment_multiplication.sv
// ============================================================================
// mult_4_display
// ----------------------------------------------------------------------------
// Purpose:
//   Small top-level that:
//     1) multiplies 4-bit a and b using mult_4,
//     2) shows 'a' and 'b' each on a single 7-seg digit,
//     3) shows the 8-bit product on two 7-seg digits.
//   Intended for quick board demo: a, b → 1 digit each; product → 2 digits.
//
// Display interface:
//   - seg_a : 7-bit [a..g] for the 'a' digit (ACTIVE-LOW inside decoder).
//   - seg_b : 7-bit [a..g] for the 'b' digit.
//   - seg_c : two digits packed as [1:0][6:0] → flattened to [13:0] here.
//
// Dependencies:
//   - mult_4                (this repo, behavioural 4×4 multiplier)
//   - multi_digit_display   (your Q1 module; parametrised digit count)
//   - seven_segment_decoder (used by multi_digit_display)
// 
// NOTE: Your original file had an ellipsis "..." where an instantiation
//       presumably belongs (likely the display for 'a'). I’ve annotated that
//       section below. Also, your testbench instantiates 'mult4_display'
//       (no underscore). Keep names consistent or add a 1-line wrapper.
// ============================================================================
module mult_4_display (
    input  logic [3:0] a,
    input  logic [3:0] b,
    output logic [6:0] seg_a,       // single digit for 'a'
    output logic [6:0] seg_b,       // single digit for 'b'
    output logic [13:0] seg_c       // two digits for product (LS digit = seg_c[6:0])
);
    // ------------------------------------------------------------------------
    // 1) Multiply a and b
    // ------------------------------------------------------------------------
    logic [7:0] product;

    mult_4 u_mult (
        .a(a),
        .b(b),
        .c(product)
    );

    // ------------------------------------------------------------------------
    // 2) Display a, b, and product on 7-seg(s)
    //    - For single digits, instantiate multi_digit_display with NUM_DIGITS=1
    //      and feed a single nibble.
    //    - For product (8 bits), NUM_DIGITS=2, feeding two nibbles (LS digit is LSB).
    // ------------------------------------------------------------------------

    // Show 'a' on one digit
    multi_digit_display #(.NUM_DIGITS(1)) disp_a (
        .number(a),   // lower 4 bits used
        .seg   (seg_a)
    );

    // Show 'b' on one digit
    multi_digit_display #(.NUM_DIGITS(1)) disp_b (
        .number(b),
        .seg   (seg_b)
    );

    // Show product on two digits
    multi_digit_display #(.NUM_DIGITS(2)) disp_c (
        .number(product),
        .seg   (seg_c)
    );

endmodule

// -----------------------------------------------------------------------------
// OPTIONAL: If you want to keep your existing testbench name (mult4_display),
// add this 1-line wrapper to avoid renaming files everywhere:
//
// module mult4_display(input  logic [3:0] a, b,
//                      output logic [6:0] seg_a, seg_b,
//                      output logic [13:0] seg_c);
//   mult_4_display i(.a(a), .b(b), .seg_a(seg_a), .seg_b(seg_b), .seg_c(seg_c));
// endmodule
// -----------------------------------------------------------------------------



// File: Q2_all.sv

// File: tb_mult_4.sv
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

// File: tb_multi_segment_multiplication.sv
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

