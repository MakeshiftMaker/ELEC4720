// File: muldiv.sv
// ============================================================================
// Q8: MIPS-style Multiply/Divide with HI/LO (n-bit)  -- ELEC4720 A1
// Core state machine controlled by F[3:0], updates on posedge clk.
//
// F[3:0] behavior (from assignment):
// 0000: y = [hi]                      (no write)
// 0001: [hi] <= a                     (write HI)
// 0010: y = [lo]                      (no write)
// 0011: [lo] <= a                     (write LO)
// 1000: {HI, LO} <= a * b             (signed/unsigned not specified -> unsigned here)
// 1010: HI <= a % b; LO <= a / b      (unsigned divide; if b==0 -> leave HI/LO unchanged)
//
// Notes:
// * HI/LO are n-bit registers; {HI,LO} concatenation uses high/low n bits of the 2n-bit product.
// * For divide-by-zero, HI/LO hold their previous values (y remains whatever the table demands).
// * Purely synchronous state updates; y is combinational per F.
// ============================================================================
module muldiv_q8 #(
  parameter int N = 3
)(
  input  logic           clk,
  input  logic [N-1:0]   a,
  input  logic [N-1:0]   b,
  input  logic [3:0]     F,
  output logic [N-1:0]   y,
  output logic [N-1:0]   hi,
  output logic [N-1:0]   lo
);
  // ---------- next-state wires ----------
  logic [N-1:0] hi_next, lo_next;
  logic         we_hi, we_lo;

  // ---------- default hold ----------
  always_comb begin
    we_hi = 1'b0;
    we_lo = 1'b0;
    hi_next = hi;
    lo_next = lo;

    case (F)
      4'b0001: begin
        we_hi  = 1'b1;
        hi_next = a;
      end

      4'b0011: begin
        we_lo  = 1'b1;
        lo_next = a;
      end

      4'b1000: begin
        // multiply: split 2N-bit product into hi/lo n-bit halves (unsigned by default)
        logic [2*N-1:0] p;
        p = a * b;
        we_hi  = 1'b1;  hi_next = p[2*N-1:N];
        we_lo  = 1'b1;  lo_next = p[N-1:0];
      end

      4'b1010: begin
        // divide: update on valid divisor; on b==0, leave registers unchanged
        if (b != '0) begin
          we_hi  = 1'b1;  hi_next = a % b;  // remainder
          we_lo  = 1'b1;  lo_next = a / b;  // quotient
        end
      end

      default: ; // no writes
    endcase
  end

  // ---------- state registers ----------
  always_ff @(posedge clk) begin
    if (we_hi) hi <= hi_next;
    if (we_lo) lo <= lo_next;
  end

  // ---------- output y ----------
  always_comb begin
    unique case (F)
      4'b0000: y = hi;  // view HI
      4'b0010: y = lo;  // view LO
      default: y = '0;  // "don't care" in spec -> tie to zero for hardware neatness
    endcase
  end

endmodule


// File: muldiv_top.sv
// ============================================================================
// ELEC4720 A1 - Q8 (N=3, seven-seg outputs per digit)
//   - Mul_Div        : HI/LO unit (F[3:0]) with 3-bit data paths
//   - seven_seg_0to7 : active-LOW 7-seg decoder for 3-bit values 0..7
//   - muldiv_top     : top with three 7-seg outputs: HEX_Y, HEX_LO, HEX_HI
// ----------------------------------------------------------------------------

// ============================================================================

// ---------------------------
// Q8 core: 3-bit version
// ---------------------------
// Q8 core (N=3 typical). Unsigned MULT/DIV; y=0 for 0001/0011/1000/1010.
module MulDiv #(
  parameter int N = 3,
  parameter bit DIV_ZERO_HOLD = 1   // if 1, ignore DIV when b==0 (hold HI/LO)
)(
  input  logic           clk,
  input  logic [N-1:0]   a,
  input  logic [N-1:0]   b,
  input  logic [3:0]     F,
  output logic [N-1:0]   y,
  output logic [N-1:0]   hi,
  output logic [N-1:0]   lo
);

  logic [N-1:0] hi_next, lo_next;
  logic         we_hi, we_lo;

  // ---------- Next-state for HI/LO ----------
  always_comb begin
    we_hi   = 1'b0;
    we_lo   = 1'b0;
    hi_next = hi;      // default: hold
    lo_next = lo;      // default: hold

    unique case (F)
      4'b0001: begin                  // [HI] <- a
        we_hi   = 1'b1;
        hi_next = a;
      end

      4'b0011: begin                  // [LO] <- a
        we_lo   = 1'b1;
        lo_next = a;
      end

      4'b1000: begin                  // MULT (unsigned)
        logic [2*N-1:0] p;
        // explicit widen & unsigned to avoid truncation/signed surprises
        p      = $unsigned(a) * $unsigned(b);
        we_hi   = 1'b1;  hi_next = p[2*N-1:N];  // upper half -> HI
        we_lo   = 1'b1;  lo_next = p[N-1:0];    // lower half -> LO
      end

      4'b1010: begin                  // DIV (unsigned): HI=rem, LO=quot
        if (!DIV_ZERO_HOLD || b != '0) begin
          we_hi   = 1'b1;  hi_next = (b=='0) ? hi : ($unsigned(a) % $unsigned(b));
          we_lo   = 1'b1;  lo_next = (b=='0) ? lo : ($unsigned(a) / $unsigned(b));
        end
      end

      default: ; // 0000/0010: no writes
    endcase
  end

  // ---------- State registers ----------
  always_ff @(posedge clk) begin
    if (we_hi) hi <= hi_next;
    if (we_lo) lo <= lo_next;
  end

  // ---------- y output ----------
  always_comb begin
    unique case (F)
      4'b0000: y = hi;   // view HI
      4'b0010: y = lo;   // view LO

      // You asked for y=0 on the load rows; also make it 0 for mult/div
      4'b0001,
      4'b0011,
      4'b1000,
      4'b1010: y = '0;

      default: y = '0;   // any other codes -> 0
    endcase
  end

endmodule



// ---------------------------
// Seven-seg decoder for 3-bit values (0..7).
// Active-LOW segments: seg = {a,b,c,d,e,f,g}.
// Values outside 0..7 show a dash ("-").
// ---------------------------
module seven_seg_0to7(
  input  logic [2:0] val,  // 3-bit value 0..7
  output logic [6:0] seg   // active-LOW segments
);
  always_comb
    unique case (val)
      3'd0: seg = 7'b1000000; // "0"
      3'd1: seg = 7'b1111001; // "1"
      3'd2: seg = 7'b0100100; // "2"
      3'd3: seg = 7'b0110000; // "3"
      3'd4: seg = 7'b0011001; // "4"
      3'd5: seg = 7'b0010010; // "5"
      3'd6: seg = 7'b0000010; // "6"
      3'd7: seg = 7'b1111000; // "7"
      default: seg = 7'b0111111; // "-" (dash) for safety
    endcase
endmodule

// ---------------------------
// Board Top: exposes one 7-seg bus per displayed value
//   Inputs:
//     CLK_BTN       : button clock (posedge updates HI/LO and latches inputs)
//     SW_A[2:0]     : 3-bit A from switches/buttons
//     SW_B[2:0]     : 3-bit B from switches
//     SW_F[3:0]     : 4-bit function
//   Outputs:
//     HEX_Y[6:0]    : seven-seg for Y (view port)
//     HEX_LO[6:0]   : seven-seg for LO
//     HEX_HI[6:0]   : seven-seg for HI
// ---------------------------
module Mul_Div #(
  parameter int N = 3
)(
  input  logic         CLK_BTN,
  input  logic [N-1:0] SW_A,
  input  logic [N-1:0] SW_B,
  input  logic [3:0]   SW_F,
  output logic [6:0]   HEX_Y,
  output logic [6:0]   HEX_LO,
  output logic [6:0]   HEX_HI
);
  // If inputs are active-LOW on your board, invert here:
  wire [N-1:0] A_in = SW_A;
  wire [N-1:0] B_in = SW_B;
  wire [3:0]   F_in = SW_F;

  // Latch inputs on button edge (for stable UX). Remove this block
  // and wire A_in/B_in/F_in directly to the core if you want "live" behavior.
  logic [N-1:0] a_q, b_q;
  logic [3:0]   F_q;
  always_ff @(posedge CLK_BTN) begin
    a_q <= A_in;
    b_q <= B_in;
    F_q <= F_in;
  end

  // Core
  logic [N-1:0] y, hi, lo;
  MulDiv #(.N(N)) u_core (
    .clk (CLK_BTN),
    .a   (a_q),
    .b   (b_q),
    .F   (F_q),
    .y   (y),
    .hi  (hi),
    .lo  (lo)
  );

  // Seven-seg encoders (one per output)
  seven_seg_0to7 u_hex_y  (.val(y),  .seg(HEX_Y));
  seven_seg_0to7 u_hex_lo (.val(lo), .seg(HEX_LO));
  seven_seg_0to7 u_hex_hi (.val(hi), .seg(HEX_HI));

  // If your physical seven-seg are ACTIVE-HIGH, invert here:
  // assign HEX_Y  = ~HEX_Y;
  // assign HEX_LO = ~HEX_LO;
  // assign HEX_HI = ~HEX_HI;
endmodule

// File: Q8_all.sv

// File: seven_seg.sv
// ============================================================================
// 7-seg decoder with ripple blanking (RBI in, RBO out), active-LOW segments.
// Inputs:
//   D[3:0] : hex digit
//   RBI    : ripple-blanking input (active low blanking enable)
// Outputs:
//   seg[6:0] : a..g (active-low)
//   RBO      : ripple-blanking output (active low when D==0 and RBI low)
// ============================================================================
module seven_segment_decoder(
  input  logic [3:0] D,
  input  logic       RBI,   // active-low enable for leading zero blanking
  output logic [6:0] seg,   // {a,b,c,d,e,f,g} active-low
  output logic       RBO
);
  logic blank;
  assign blank = (~RBI) && (D == 4'd0); // when blanking chain says "blank" and digit==0
  assign RBO   = blank ? 1'b0 : 1'b1;   // propagate active-low when we blank this zero

  always_comb begin
    if (blank) begin
      seg = 7'b111_1111; // all off (active-low)
    end else begin
      unique case (D)
        4'h0: seg = 7'b100_0000;
        4'h1: seg = 7'b111_1001;
        4'h2: seg = 7'b010_0100;
        4'h3: seg = 7'b011_0000;
        4'h4: seg = 7'b001_1001;
        4'h5: seg = 7'b001_0010;
        4'h6: seg = 7'b000_0010;
        4'h7: seg = 7'b111_1000;
        4'h8: seg = 7'b000_0000;
        4'h9: seg = 7'b001_0000;
        4'hA: seg = 7'b000_1000;
        4'hB: seg = 7'b000_0011;
        4'hC: seg = 7'b100_0110;
        4'hD: seg = 7'b010_0001;
        4'hE: seg = 7'b000_0110;
        default: seg = 7'b000_1110; // F
      endcase
    end
  end
endmodule


// File: tb_muldiv.sv
`timescale 1ns/1ps
module tb_muldiv_q8;
  // ---- Parameters ----
  localparam int N  = 3;   // HI/LO width (3 bits: 0..7)
  localparam int W2 = 6;   // 2*N (product width)

  // ---- DUT I/O ----
  logic             clk;
  logic [N-1:0]     a, b, y, hi, lo;
  logic [3:0]       F;

  // Instantiate your Q8 core (must be in muldiv_q8.sv)
  muldiv_q8 #(.N(N)) dut (
    .clk(clk), .a(a), .b(b), .F(F),
    .y(y), .hi(hi), .lo(lo)
  );

  // ---- Clock & tick ----
  initial clk = 1'b0;
  always  #5 clk = ~clk;       // 100 MHz / arbitrary for sim
  task tick; begin @(negedge clk); @(posedge clk); end endtask

  // ---- Temps for prints (tool-friendly: declared at module scope) ----
  logic [W2-1:0] p;            // 2N-bit product
  logic [N-1:0]  hi_exp, lo_exp;
  logic [N-1:0]  q_exp,  r_exp;
  integer        i, op;

  // ---- Pretty printers (fixed widths: %03b for N, %06b for 2N) ----
  task show_mult; begin
    $display("\n[MULT] a=%0d (%03b), b=%0d (%03b)", a, a, b, b);
    $display("       product p = %0d (%06b)", p, p);
    $display("       expect HI=%0d (%03b), LO=%0d (%03b)", hi_exp, hi_exp, lo_exp, lo_exp);
    $display("       dut    HI=%0d (%03b), LO=%0d (%03b)", hi, hi, lo, lo);
  end endtask

  task show_div; begin
    if (b==0) begin
      $display("\n[DIV ] a=%0d (%03b), b=0 -> DIV BY ZERO (regs hold)", a, a);
      $display("       dut    HI=%0d (%03b), LO=%0d (%03b)", hi, hi, lo, lo);
    end else begin
      $display("\n[DIV ] a=%0d (%03b), b=%0d (%03b)", a, a, b, b);
      $display("       expect Q =%0d (%03b), R =%0d (%03b)", q_exp, q_exp, r_exp, r_exp);
      $display("       dut    LO=%0d (%03b), HI=%0d (%03b)", lo, lo, hi, hi);
    end
  end endtask

  // ---- Test sequence ----
  initial begin
    $display("Q8 TB ? fixed-width binary prints  N=%0d  2N=%0d", N, W2);

    // Deterministic init: set HI=0, LO=0 via loads
    a=0; b=0; F=4'b0001; tick;     // HI <= 0
    F=4'b0011; tick;               // LO <= 0

    // 1) Load HI=3, view HI
    a=3; F=4'b0001; tick;          // HI <= 3
    F=4'b0000; #1;
    $display("\n[VIEW HI] y=%0d (%03b), HI=%0d (%03b)", y, y, hi, hi);

    // 2) Load LO=5, view LO
    a=5; F=4'b0011; tick;          // LO <= 5
    F=4'b0010; #1;
    $display("[VIEW LO] y=%0d (%03b), LO=%0d (%03b)", y, y, lo, lo);

    // 3) MULT: 5*6 -> p=30 (011110), HI=011(3), LO=110(6)
    a=5; b=6;
    p      = a*b;
    hi_exp = p[5:3];
    lo_exp = p[2:0];
    F=4'b1000; tick; show_mult();

    // 4) DIV: 7/3 -> Q=2 (010), R=1 (001)
    a=7; b=3;
    q_exp = a/b;
    r_exp = a%b;
    F=4'b1010; tick; show_div();

    // 5) DIV by zero -> regs hold
    a=7; b=0; F=4'b1010; tick; show_div();

    // 6) View via y (doesn't change regs)
    F=4'b0000; #1; $display("\n[VIEW HI] y=%0d (%03b)", y, y);
    F=4'b0010; #1; $display("[VIEW LO] y=%0d (%03b)", y, y);

    // ---- Six random printed examples ----
    $display("\n---- Six Random Examples ----");
    for (i=0; i<6; i=i+1) begin
      a  = $random & 3'b111;
      b  = $random & 3'b111;
      op = $random % 4; if (op<0) op = -op;
      case (op)
        0: begin
             F=4'b0001; tick; // load HI
             $display("\n[RAND%0d] LOAD HI  a=%0d (%03b) -> HI=%0d (%03b)", i, a, a, hi, hi);
           end
        1: begin
             F=4'b0011; tick; // load LO
             $display("\n[RAND%0d] LOAD LO  a=%0d (%03b) -> LO=%0d (%03b)", i, a, a, lo, lo);
           end
        2: begin
             p      = a*b; hi_exp = p[5:3]; lo_exp = p[2:0];
             F=4'b1000; tick; show_mult();
           end
        default: begin
             // Note: for b==0, core holds regs; we print that fact.
             q_exp = (b==0) ? lo : (a/b);
             r_exp = (b==0) ? hi : (a%b);
             F=4'b1010; tick; show_div();
           end
      endcase
    end

    $display("\nQ8 TB: done.");
    $finish;
  end
endmodule


