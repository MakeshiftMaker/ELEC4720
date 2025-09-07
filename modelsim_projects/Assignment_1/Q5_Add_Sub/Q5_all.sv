// File: add_sub.sv
// ============================================================================
// Module  : adder
// Purpose : Parameterised combinational adder (behavioural).
// ============================================================================
module adder #(parameter int W = 4) (
  input  logic [W-1:0] A,
  input  logic [W-1:0] B,
  input  logic         Cin,
  output logic [W-1:0] S,
  output logic         Cout
);
  assign {Cout, S} = A + B + Cin;
endmodule


// ============================================================================
// Local helper : seven_segment_decoder_local
// Purpose      : Decode a 4-bit hex value into segments {a,b,c,d,e,f,g}.
// Notes        : Returns segments in ACTIVE_LOW/ACTIVE_HIGH per parameter.
// ============================================================================
// ============================================================================
// Local helper : seven_segment_decoder_local
// Purpose      : Decode a 4-bit hex value into segments {a,b,c,d,e,f,g}.
// Notes        : hex7 returns ACTIVE-HIGH patterns. We only invert at the end
//                if the board is active-low (common-anode).
// ============================================================================
module seven_segment_decoder_local #(
  parameter bit ACTIVE_LOW = 1'b1 // 1 = active-low outputs; 0 = active-high
) (
  input  logic [3:0] D,
  output logic [6:0] seg  // {a,b,c,d,e,f,g}
);
  // Active-HIGH patterns for 0..F (1 = LED on)
  function automatic logic [6:0] hex7 (input logic [3:0] x);
    unique case (x)
      4'h0: hex7 = 7'b1111110;
      4'h1: hex7 = 7'b0110000;
      4'h2: hex7 = 7'b1101101;
      4'h3: hex7 = 7'b1111001;
      4'h4: hex7 = 7'b0110011;
      4'h5: hex7 = 7'b1011011;
      4'h6: hex7 = 7'b1011111;
      4'h7: hex7 = 7'b1110000;
      4'h8: hex7 = 7'b1111111;
      4'h9: hex7 = 7'b1111011;
      4'hA: hex7 = 7'b1110111; // A
      4'hB: hex7 = 7'b0011111; // b
      4'hC: hex7 = 7'b1001110; // C
      4'hD: hex7 = 7'b0111101; // d
      4'hE: hex7 = 7'b1001111; // E
      4'hF: hex7 = 7'b1000111; // F
      default: hex7 = 7'b0000000;
    endcase
  endfunction

  wire [6:0] seg_hi = hex7(D);

  // Apply required polarity ONCE
  assign seg = (ACTIVE_LOW) ? ~seg_hi : seg_hi;
endmodule



// ============================================================================
// Local helper : multi_digit_display_local
// Purpose      : Take NUM_DIGITS hex nibbles and decode to 7-seg per digit.
// Interface    : number packs digits as number[i*4 +: 4] (i=0 is digit 0).
// Notes        : Simple per-digit decoding (no ripple-blanking).
// ============================================================================
module multi_digit_display_local #(
  parameter int NUM_DIGITS = 3,
  parameter bit ACTIVE_LOW = 1'b1
) (
  input  logic [NUM_DIGITS*4-1:0] number,
  output logic [NUM_DIGITS-1:0][6:0] seg  // seg[i] = {a,b,c,d,e,f,g} for digit i
);
  genvar i;
  generate
    for (i = 0; i < NUM_DIGITS; i++) begin : gen_digits
      seven_segment_decoder_local #(.ACTIVE_LOW(ACTIVE_LOW)) u_dec (
        .D  ( number[i*4 +: 4] ),
        .seg( seg[i] )
      );
    end
  endgenerate
endmodule


// ============================================================================
// Module  : add_sub
// Purpose : ADD/SUB and display A, B, Y on 3x seven-seg (one digit each).
// Notes   : Shows LOWER 4 BITS of each. ACTIVE_LOW controls segment polarity.
// ============================================================================
module add_sub #(
  parameter int W = 4,
  parameter bit ACTIVE_LOW = 1'b1   // 1: segments are active-low (common-anode)
) (
  input  logic [W-1:0] A,
  input  logic [W-1:0] B,
  input  logic         s,      // 0: add, 1: subtract (A-B)
  output logic [W-1:0] Y,
  output logic         Cout,
  output logic         OV,

  // one 7-seg digit each for A, B, Y
  output logic [6:0]   seg_A,  // shows A[3:0]
  output logic [6:0]   seg_B,  // shows B[3:0]
  output logic [6:0]   seg_Y   // shows Y[3:0]
);

  // -------- core add/sub -----------------------------------------------------
  wire [W-1:0] Bsel = s ? ~B : B;
  wire         Cin  = s;

  adder #(.W(W)) u_add (.A(A), .B(Bsel), .Cin(Cin), .S(Y), .Cout(Cout));

  // Signed overflow detection (two's complement)
  always_comb begin
    if (!s) begin
      OV = (A[W-1] == B[W-1]) && (Y[W-1] != A[W-1]); // ADD
    end else begin
      OV = (A[W-1] != B[W-1]) && (Y[W-1] != A[W-1]); // SUB
    end
  end

  // -------- 7-seg display (A, B, Y) -----------------------------------------
  // Safely extract a 4-bit nibble (zero-extend if W<4)
  function automatic logic [3:0] lo_nib (input logic [W-1:0] v);
    if (W >= 4) lo_nib = v[3:0];
    else        lo_nib = {{(4-W){1'b0}}, v};
  endfunction

  localparam int NUM_DIGITS = 3;

  // Pack digits: digit 0 = A, digit 1 = B, digit 2 = Y
  wire [NUM_DIGITS*4-1:0] digits_packed = { lo_nib(Y), lo_nib(B), lo_nib(A) };

  // Decode to segments for each digit
  logic [NUM_DIGITS-1:0][6:0] seg_mat;

  multi_digit_display_local #(
    .NUM_DIGITS(NUM_DIGITS),
    .ACTIVE_LOW(ACTIVE_LOW)
  ) u_disp (
    .number(digits_packed),
    .seg   (seg_mat)
  );

  // Expose each digit’s segments on its own 7-wire port
  assign seg_A = seg_mat[0];
  assign seg_B = seg_mat[1];
  assign seg_Y = seg_mat[2];

endmodule

// File: Q5_all.sv

// File: tb_add_sub.sv
// ============================================================================
// Testbench : tb_q5_addsub
// Purpose   : Verify addsub for both addition and subtraction.
// Strategy  :
//   - Directed edge cases (zeros, all-ones, +/- limits).
//   - Small exhaustive window (0..15).
//   - Random trials.
//   - Prints to Transcript and uses assertions.
// ============================================================================
`timescale 1ns/1ps
module tb_q5_addsub;
  localparam int W = 4;

  // DUT I/O
  logic [W-1:0] A, B, Y;
  logic         s;         // 0=add, 1=sub
  logic         Cout, OV;

  addsub #(.W(W)) dut (.A, .B, .s, .Y, .Cout, .OV);

  // Scratch regs for expected values
  logic [W:0]   es;        // expected sum incl. carry bit (W+1)
  logic         eOV;       // expected overflow

  // Compute expected (unsigned sum incl. carry)
  function automatic [W:0] exp_sum (input logic [W-1:0] a,
                                    input logic [W-1:0] b,
                                    input logic         sub);
    // Same datapath as DUT: A + (sub ? ~B : B) + sub
    exp_sum = ({1'b0,a}) + ({1'b0,(sub ? ~b : b)}) + sub;
  endfunction

  // Compute expected signed overflow (two's-complement)
  function automatic logic exp_ov(input logic [W-1:0] a,
                                  input logic [W-1:0] b,
                                  input logic         sub,
                                  input logic [W-1:0] y);
    logic sa, sb, sy;
    begin
      sa = a[W-1]; sb = b[W-1]; sy = y[W-1];
      if (!sub) exp_ov = (sa == sb) && (sy != sa);       // ADD
      else      exp_ov = (sa != sb) && (sy != sa);       // SUB
    end
  endfunction

  // Pretty print one line
  task automatic show(input string tag);
    $display("%0t | %s s=%0d  A=%0d (0x%0h)  B=%0d (0x%0h)  ->  Y=%0d (0x%0h)  C=%0b  OV=%0b",
             $time, tag, s, $signed(A), A, $signed(B), B, $signed(Y), Y, Cout, OV);
  endtask

  initial begin
    $display("Time | Q5 add/sub results");

    // -------- Directed: zeros
    A=0; B=0; s=0; #1;
    es = exp_sum(A,B,s); eOV = exp_ov(A,B,s,Y); show("ADD");
    assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);

    A=0; B=0; s=1; #1;
    es = exp_sum(A,B,s); eOV = exp_ov(A,B,s,Y); show("SUB");
    assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);

    // -------- Directed: max/min patterns
    A={W{1'b1}}; B=0; s=0; #1; es=exp_sum(A,B,s); eOV=exp_ov(A,B,s,Y); show("ADD"); assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);
    A={W{1'b1}}; B=1; s=0; #1; es=exp_sum(A,B,s); eOV=exp_ov(A,B,s,Y); show("ADD"); assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);

    A={W{1'b0}}; B=1; s=1; #1; es=exp_sum(A,B,s); eOV=exp_ov(A,B,s,Y); show("SUB"); assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);
    A=8'h80;     B=8'h01; s=1; #1; es=exp_sum(A,B,s); eOV=exp_ov(A,B,s,Y); show("SUB"); assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);

    // -------- Small exhaustive (0..15)
    for (int i=0;i<16;i++)
      for (int j=0;j<16;j++) begin
        A=i; B=j; s=0; #1; es=exp_sum(A,B,s); eOV=exp_ov(A,B,s,Y); assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);
        A=i; B=j; s=1; #1; es=exp_sum(A,B,s); eOV=exp_ov(A,B,s,Y); assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);
      end

	// 50 random examples (decimal print)
	for (int t=0; t<50; t++) begin
  	A = $urandom(); B = $urandom(); s = $urandom_range(0,1); #1;
  	es = exp_sum(A,B,s); eOV = exp_ov(A,B,s,Y);

  	// Decimal-first line:
  	$display("RAND[%0d] s=%0d A=%0d  B=%0d  ->  Y=%0d  C=%0b  OV=%0b  (exp=%0d/%0b/%0b)",
           t, s, $signed(A), $signed(B), $signed(Y), Cout, OV,
           $signed(es[W-1:0]), es[W], eOV);

  	assert(Y==es[W-1:0] && Cout==es[W] && OV==eOV);
	end

    $display("Q5 add/sub: all tests passed.");
    $finish;
  end
endmodule



