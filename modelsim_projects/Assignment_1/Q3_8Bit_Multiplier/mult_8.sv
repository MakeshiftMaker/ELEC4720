//8 bit multiplier module using descriptive implementation

module mult_8(
	input logic [7:0] a,b, //input
	output logic [15:0] c //result
);

	assign c = a * b;

	//due to the descriptive implementation, this allows the fpga compiler to use arithmatic blocks and be more efficient/less resource intensive
endmodule
