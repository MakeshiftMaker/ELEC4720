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
    assign c = a * b;
endmodule
