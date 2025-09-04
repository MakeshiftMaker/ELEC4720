// ============================================================================
// Q8 top for FPGA demo
//  - A, B, F come from switches
//  - clk is a button (posedge latch)
//  - Show lower nibble of Y, LO, HI on HEX0, HEX1, HEX2 (active-low)
//  - N defaults to 3 (per assignment demo); you can raise it if you want.
// ============================================================================
module q8_board_top #(
  parameter int N = 3
)(
  input  logic             clk_btn,              // pushbutton as clock
  input  logic [N-1:0]     SW_A,
  input  logic [N-1:0]     SW_B,
  input  logic [3:0]       SW_F,
  output logic [6:0]       HEX0,                 // Y  lower nibble
  output logic [6:0]       HEX1,                 // LO lower nibble
  output logic [6:0]       HEX2,                 // HI lower nibble
  output logic [N-1:0]     LED_Y,                // (optional) LEDs for Y
  output logic [N-1:0]     LED_LO,               // (optional)
  output logic [N-1:0]     LED_HI                // (optional)
);
  // Registers are inside the core; we just forward switch values to it.
  logic [N-1:0] a, b, y, hi, lo;
  logic [3:0]   F;

  // Simple input latching on button edge to make UX stable (optional)
  // If you prefer "live" switches into the core, wire SW_* directly.
  always_ff @(posedge clk_btn) begin
    a <= SW_A;
    b <= SW_B;
    F <= SW_F;
  end

  muldiv_q8 #(.N(N)) u_core (
    .clk (clk_btn),   // state updates when you press the button
    .a(a), .b(b), .F(F),
    .y(y), .hi(hi), .lo(lo)
  );

  // Optional LEDs
  assign LED_Y  = y;
  assign LED_LO = lo;
  assign LED_HI = hi;

  // 7-seg: lower nibble of each
  logic [6:0] seg_y, seg_lo, seg_hi;
  logic rbo0, rbo1; // not used but connected

  seven_segment_decoder u_hex_y  (.D({1'b0, y[2:0]}),  .RBI(1'b1), .seg(seg_y),  .RBO(rbo0));
  seven_segment_decoder u_hex_lo (.D({1'b0, lo[2:0]}), .RBI(1'b1), .seg(seg_lo), .RBO(rbo1));
  seven_segment_decoder u_hex_hi (.D({1'b0, hi[2:0]}), .RBI(1'b1), .seg(HEX2),   .RBO(/*unused*/));

  // If your board?s HEX are active-low, drive directly; if active-high, invert here.
  assign HEX0 = seg_y;
  assign HEX1 = seg_lo;
  // HEX2 already driven by u_hex_hi
endmodule

