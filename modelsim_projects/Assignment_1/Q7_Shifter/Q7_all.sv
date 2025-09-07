// File: Q7_all.sv

// File: Shifter_sim.sv
// ============================================================================
// Module  : shifter
// Author  : 
// Purpose : Parameterised shifter over W=2*N bits with 3 functions:
//             F[1:0] = 00 -> logical left  (<<)
//                        01 -> logical right (>>)
//                        11 -> arithmetic right (>>>)
// Notes   :
//   * Purely combinational.
//   * Amount width is N bits; data width is W=2*N (matches "2n-bit" style).
//   * Arithmetic right uses $signed(A).
// ============================================================================
module shifter #(
  parameter int N = 4,
  parameter int W = 2*N
)(
  input  logic [W-1:0] A,
  input  logic [N-1:0] Sh,
  input  logic [1:0]   F,   // 00<<, 01>>, 11>>> (10 -> >>)
  output logic [W-1:0] Y
);
  logic signed [W-1:0] As;

  always_comb begin
    As = A;
    Y  = '0;                // <-- default each cycle (prevents X retention)
    casez (F)               // <-- tolerate X/Z in F bits if they ever appear
      2'b00: Y = A  << Sh;  // logical left
      2'b01: Y = A  >> Sh;  // logical right
      2'b11: Y = As >>> Sh; // arithmetic right
      default: Y = A >> Sh; // 2'b10 or anything else -> logical right
    endcase
  end
endmodule

// ============================================================================
// Module  : shifter_mips
// Author  : 
// Purpose : MIPS-style wrapper that selects shift amount from either:
//            - immediate c[N-1:0], or
//            - low N bits of b (variable shift),
//           and maps a 3-bit F to the operation.
// Interface:
//   a[W-1:0]  : data to shift
//   b[W-1:0]  : secondary operand (low N bits hold variable amount)
//   c[N-1:0]  : immediate amount
//   F[2:0]    : 000 a<<c, 001 a>>c, 011 a>>>c,
//               100 a<<b[N-1:0], 101 a>>b[N-1:0], 111 a>>>b[N-1:0]
//   y[W-1:0]  : result
// ============================================================================
module shifter_mips #(
  parameter int N = 4,
  parameter int W = 2*N
)(
  input  logic [W-1:0] a, b,
  input  logic [N-1:0] c,
  input  logic [2:0]   F,
  output logic [W-1:0] y
);
  logic [N-1:0] amt;
  logic [1:0]   f2;

  always_comb begin                 // <-- avoids any init-at-decl weirdness
    amt = F[2] ? b[N-1:0] : c;
    f2  = F[1:0];
  end

  shifter #(.N(N), .W(W)) u_sh (
    .A (a),
    .Sh(amt),
    .F (f2),
    .Y (y)
  );
endmodule



// File: shifter.sv
// ===================== shifter_core =====================
module shifter_core (
  input  logic [3:0] A,
  input  logic [1:0] B,
  input  logic [1:0] C,
  input  logic [2:0] F,
  output logic [3:0] Y
);
  function automatic [3:0] rol4(input [3:0] x, input [1:0] sh);
    case (sh)
      2'd0: rol4 = x;
      2'd1: rol4 = {x[2:0], x[3]};
      2'd2: rol4 = {x[1:0], x[3:2]};
      default: rol4 = {x[0], x[3:1]};
    endcase
  endfunction

  function automatic [3:0] ror4(input [3:0] x, input [1:0] sh);
    case (sh)
      2'd0: ror4 = x;
      2'd1: ror4 = {x[0], x[3:1]};
      2'd2: ror4 = {x[1:0], x[3:2]};
      default: ror4 = {x[2:0], x[3]};
    endcase
  endfunction

  always_comb begin
    unique case (F)
      3'b000: Y = A;                   // passthrough
      3'b001: Y = (A << B);            // LSL by B
      3'b010: Y = (A >> B);            // LSR by B
      3'b011: Y = ($signed(A) >>> B);  // ASR by B
      3'b100: Y = rol4(A, C);          // ROL by C
      3'b101: Y = ror4(A, C);          // ROR by C
      3'b110: Y = (A << 1);            // extra op
      default: Y = 4'b0000;
    endcase
  end
endmodule

// ===================== seven_seg_hex =====================
module seven_seg_hex(
  input  logic [3:0] val,
  output logic [6:0] HEX          // active-LOW {g,f,e,d,c,b,a}
);
  always_comb begin
    unique case (val)
      4'h0: HEX = 7'b1000000;
      4'h1: HEX = 7'b1111001;
      4'h2: HEX = 7'b0100100;
      4'h3: HEX = 7'b0110000;
      4'h4: HEX = 7'b0011001;
      4'h5: HEX = 7'b0010010;
      4'h6: HEX = 7'b0000010;
      4'h7: HEX = 7'b1111000;
      4'h8: HEX = 7'b0000000;
      4'h9: HEX = 7'b0010000;
      4'hA: HEX = 7'b0001000;
      4'hB: HEX = 7'b0000011;
      4'hC: HEX = 7'b1000110;
      4'hD: HEX = 7'b0100001;
      4'hE: HEX = 7'b0000110;
      4'hF: HEX = 7'b0001110;
      default: HEX = 7'b1111111;
    endcase
  end
  endmodule

// ===================== TOP: Shifter =====================
module Shifter (
  input  logic [3:0] BTN_A,   // 4 buttons for A
  input  logic [2:0] SW_F,    // 3 switches for F
  input  logic [1:0] SW_B,    // 2 switches for B
  input  logic [1:0] SW_C,    // 2 switches for C
  output logic [3:0] LED_A,   // show A
  output logic [3:0] LED_Y,   // show Y
  output logic [6:0] HEX_B,   // show B
  output logic [6:0] HEX_C    // show C
);
  // Declare then assign (no non-constant init in decls)
  logic [3:0] A;  assign A = BTN_A;
  logic [1:0] B;  assign B = SW_B;
  logic [1:0] C;  assign C = SW_C;
  logic [2:0] F;  assign F = SW_F;

  assign LED_A = ~A;

  logic [3:0] Y;
  shifter_core u_core (.A(A), .B(B), .C(C), .F(F), .Y(Y));
  assign LED_Y = ~Y;

  seven_seg_hex u_hex_b (.val({2'b00, B}), .HEX(HEX_B));
  seven_seg_hex u_hex_c (.val({2'b00, C}), .HEX(HEX_C));
endmodule

// File: tb_shifter.sv
`timescale 1ns/1ps
// ModelSim testbench for a Q7 shifter with ports: A,B,C,F,Y (F is 2 bits).
// If your DUT module name is Shifter_sim, change the instantiation below.

module tb_Shifter;
  localparam int N = 2;
  localparam int W = 2*N;

  // DUT I/O
  logic [W-1:0] a, b, y;
  logic [N-1:0] c;
  logic [2:0]   F;

  // ---- DUT (lowercase ports, 3-bit F). If your module name is different, change it here.
  shifter_mips #(.N(N), .W(W)) dut ( .a(a), .b(b), .c(c), .F(F), .y(y) );

  // Golden (F[2]=variable shift via b[N-1:0]; else by c)
  function automatic [W-1:0] y_golden(input logic [W-1:0] a_i,b_i, input logic [N-1:0] c_i, input logic [2:0] F_i);
    logic [N-1:0] amt = (F_i[2]) ? b_i[N-1:0] : c_i;
    case (F_i[1:0])
      2'b00: y_golden = (a_i <<  amt);
      2'b01: y_golden = (a_i >>  amt);
      2'b11: y_golden = ($signed(a_i) >>> amt);
      default: y_golden = (a_i >> amt);
    endcase
  endfunction

  task automatic show_and_check(string tag);
    logic [W-1:0] exp; #1; exp = y_golden(a,b,c,F);
    $display("%0t | %s F=%03b a=%0d (%04b) b=%0d (%04b) c=%0d (%02b) -> y=%0d (%04b) exp=%0d (%04b)",
             $time, tag, F, a,a, b,b, c,c, y,y, exp,exp);
    if (y !== exp) $fatal(1, "Mismatch");
  endtask

  initial begin
    $display("TB F=3, ports a,b,c,F,y");
    a=4'b1011; b=4'h0; c=2'd0; F=3'b000; show_and_check("SLL c=0");
    c=2'd1;             F=3'b000; show_and_check("SLL c=1");
    c=2'd2;             F=3'b001; show_and_check("SRL c=2");
    c=2'd1;             F=3'b011; show_and_check("SRA c=1");

    a=4'b0011; b=4'b0010; c=2'd0; F=3'b100; show_and_check("SLLV b");
                          F=3'b101; show_and_check("SRLV b");
                          F=3'b111; show_and_check("SRAV b");

    for (int i=0;i<12;i++) begin
      a=$urandom_range(0,15); b=$urandom_range(0,15); c=$urandom_range(0,3);
      unique case ($urandom_range(0,5))
        0:F=3'b000; 1:F=3'b001; 2:F=3'b011; 3:F=3'b100; 4:F=3'b101; default:F=3'b111;
      endcase
      show_and_check($sformatf("RAND[%0d]", i));
    end
    $display("PASS"); $finish;
  end
endmodule

