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
