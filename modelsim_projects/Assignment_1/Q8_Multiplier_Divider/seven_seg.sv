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

