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
