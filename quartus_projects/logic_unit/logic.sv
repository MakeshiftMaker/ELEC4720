// ============================================================================
// Module  : logic_unit
// Purpose : Bitwise logic unit over 2N-bit operands.
// Interface:
//   - Parameters:
//       N : natural number; data width is W = 2*N (as per brief wording).
//   - Inputs:
//       A, B : W-bit operands
//       F    : 2-bit function select
//              00 -> AND, 01 -> OR, 10 -> XOR, 11 -> NOR
//   - Outputs:
//       Y    : W-bit result
//
// Design notes:
//   * Purely combinational.
//   * Unique case ensures clear intent and catches X-propagation in sim.
//   * Parameter N lets you align with the brief's "2n-bit" phrasing while
//     staying flexible for later FPGA steps.
// ============================================================================
module logic_unit #(
  parameter int N = 2
) (
  input  logic [2*N-1:0] A,
  input  logic [2*N-1:0] B,
  input  logic [1:0]     F,        // 00 AND, 01 OR, 10 XOR, 11 NOR
  output logic [2*N-1:0] Y,
  // NEW: expose inputs to LEDs
  output logic [2*N-1:0] LED_A,
  output logic [2*N-1:0] LED_B
);
  // Combinational intermediates
  wire [2*N-1:0] andv = A & B;
  wire [2*N-1:0] orv  = A | B;
  wire [2*N-1:0] xorv = A ^ B;
  wire [2*N-1:0] norv = ~(A | B);

  // Select result
  always_comb unique case (F)
    2'b00: Y = andv;
    2'b01: Y = orv;
    2'b10: Y = xorv;
    2'b11: Y = norv;
  endcase

  // Drive LEDs directly with the inputs
  assign LED_A = A;
  assign LED_B = B;
endmodule
