// File: logic.sv
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

// File: Q4_all.sv

// File: tb_logic.sv
// ============================================================================
// Testbench : tb_q4_logic
// Purpose   : Verify logic_unit for all function codes.
// Strategy  :
//   - Apply edge-case values of A and B.
//   - Apply random samples.
//   - For each case, calculate the expected result directly in the TB and
//     compare with DUT output.
// ============================================================================
`timescale 1ns/1ps
module tb_q4_logic;
  localparam int N = 2;
  localparam int W = 2*N;

  logic [W-1:0] A, B, Y, expected;
  logic [1:0]   F;

  logic_unit #(.N(N)) dut (.A, .B, .F, .Y);

  // Pretty-printer for Transcript
  task show(input [W-1:0] a, b, input [1:0] f,
            input [W-1:0] y, input [W-1:0] exp);
    $display("%0t | F=%b  A=%h  B=%h  ->  Y=%h  (expected=%h)",
             $time, f, a, b, y, exp);
  endtask

  initial begin
    $display("Time | F  A  B -> Y (expected)");

    // Directed test cases
    A='0; B='0;
    foreach (F[i]) begin
      for (int f=0; f<4; f++) begin
        F=f; #1;
        case (F)
          2'b00: expected = A & B;
          2'b01: expected = A | B;
          2'b10: expected = A ^ B;
          2'b11: expected = ~(A | B);
        endcase
        show(A,B,F,Y,expected);
        assert(Y==expected);
      end
    end

    // More directed corners
    A='1; B='0;      for (int f=0; f<4; f++) begin F=f; #1; case (F) 2'b00:expected=A&B; 2'b01:expected=A|B; 2'b10:expected=A^B; 2'b11:expected=~(A|B); endcase; show(A,B,F,Y,expected); assert(Y==expected); end
    A='0; B='1;      for (int f=0; f<4; f++) begin F=f; #1; case (F) 2'b00:expected=A&B; 2'b01:expected=A|B; 2'b10:expected=A^B; 2'b11:expected=~(A|B); endcase; show(A,B,F,Y,expected); assert(Y==expected); end
    A={W{1'b1}}; B={W{1'b0}}; for (int f=0; f<4; f++) begin F=f; #1; case (F) 2'b00:expected=A&B; 2'b01:expected=A|B; 2'b10:expected=A^B; 2'b11:expected=~(A|B); endcase; show(A,B,F,Y,expected); assert(Y==expected); end
    A={W{1'b1}}; B={W{1'b1}}; for (int f=0; f<4; f++) begin F=f; #1; case (F) 2'b00:expected=A&B; 2'b01:expected=A|B; 2'b10:expected=A^B; 2'b11:expected=~(A|B); endcase; show(A,B,F,Y,expected); assert(Y==expected); end

    // Random sampling
    for (int t=0; t<20; t++) begin
      A=$urandom; B=$urandom; F=$urandom_range(0,3); #1;
      case (F)
        2'b00: expected=A&B;
        2'b01: expected=A|B;
        2'b10: expected=A^B;
        2'b11: expected=~(A|B);
      endcase
      show(A,B,F,Y,expected);
      assert(Y==expected);
    end

    $display("Q4 logic unit: all tests passed.");
    $finish;
  end
endmodule



