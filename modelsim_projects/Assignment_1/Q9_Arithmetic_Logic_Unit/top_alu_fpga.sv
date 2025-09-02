module top_alu_fpga (
    input  logic [3:0] A, B,   // A and B inputs
    input  logic [3:0] F,  // ALU control F
    output logic [3:0] Y,  // ALU result Y
    output logic [6:0] seg_a, seg_b, seg_y,
    output logic Cout, OV,
    output logic [3:0] A_out, B_out
);

    assign A_out = ~A;
    assign B_out = B;

    alu #(.N(3)) alu_inst (
        .A(A), .B(B), .F(F), .Y(Y), .Cout(Cout), .OV(OV)
    );
    
    multi_digit_display #(.NUM_DIGITS(1)) disp_a (
        .number(A),
	.seg(seg_a)
    );
  
    multi_digit_display #(.NUM_DIGITS(1)) disp_b (
        .number(B),
	.seg(seg_b)
    );

    multi_digit_display #(.NUM_DIGITS(1)) disp_y (
        .number(Y),
	.seg(seg_y)
    );
endmodule
