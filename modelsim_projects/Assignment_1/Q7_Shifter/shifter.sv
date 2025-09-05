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
