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

