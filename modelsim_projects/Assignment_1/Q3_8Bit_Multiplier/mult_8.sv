module mult_8(
	input logic [7:0] a,b,
	output logic [15:0] c
);

	assign c = a * b;
endmodule
