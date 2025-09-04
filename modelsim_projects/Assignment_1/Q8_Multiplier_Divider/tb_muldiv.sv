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

