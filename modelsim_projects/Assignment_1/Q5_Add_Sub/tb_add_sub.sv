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


