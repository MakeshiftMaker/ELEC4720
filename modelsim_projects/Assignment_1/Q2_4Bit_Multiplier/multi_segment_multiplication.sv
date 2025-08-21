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


