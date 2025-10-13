module mips(

    input logic clk,
    input logic reset,
    output logic [31:0] pc_out,
    output logic [31:0] rom_data
);
    logic Zero;     // output from ALU
    logic Branch;   // output from your (yet-to-be-implemented) control unit
    logic PCSrc;    // final ANDed signal for PC mux

    assign PCSrc = Branch & Zero;

    // instantiate the program counter
    PC pc_inst (
        .clk(clk),
        .reset(reset),
        .PC_in(PC1),
	.PC_out(pc_out)
    );

    // ROM in byte/word addressing
    ByteIM rom_inst (
        .Ad(pc_out),
        .Dout(rom_data)
    );
    logic R, B1, J, B2, I, F, M;
    instruction_classifier ic (
	.opcode(rom_data[31:26]),
	.R(R),
	.B1(B1),
	.J(J),
	.B2(B2),
	.I(I),
	.F(F),
	.M(M)
    );

    multiplexer#(.N(2), .WIDTH(4)) writeReg_multiplexer(
	.input_bits({rom_data[20:16], rom_data[15:11]}),
	.selection(write_reg_sel), //output from ControlUnit
	.selected_output(writeReg) //output to regfile
    );

    multiplexer#(.N(2), .WIDTH(32)) ALU_srcB_multiplexer(
	.input_bits({RD2, SignImm}),
	.selection(ALUSrc), 
	.selected_output(SrcB) 
    );

    multiplexer#(.N(2), .WIDTH(32)) PC_multiplexer(
	.input_bits({pc_out, PCBranch}),
	.selection(PCSrc),
	.selection_output(PC1)
);

    multiplexer#(.N(2), .WIDTH(32)) Writeback_multiplexer(
	.input_bits({ALUResult, ReadData}),
	.selection(MemtoReg),
	.selection_output(Result)
);

    regfile regfile_inst(
	.A1(rom_data[25:21]),
	.A2(rom_data[20:16]),
	.RD1(RD1),
	.RD2(RD2),
	.WA(writeReg),
	.WE(RegWrite),
	.WD(Result)
	.clk(clk)
    );

    signExtend signExtend_inst(
	.in(rom_data[15:0]),
	.out(SignImm)
);

    shifter PCBranchShifter(
	.in(SignImm),
	.shamt(2),
	.sh_type(2'b00),
	.out(shift_out)

);

    adder PCBranch_adder(
	.A(shift_out),
	.B(pc_out),
	.SUM(PCBranch)
);

    alu ALU_inst(
	.A(RD1),
	.B(SrcB),
	.Zero(Zero), //add ALU zero output
	.Y(ALUResult),
	.F(ALUControl) // control bits for alu to choose operation
);

    regfile DataMemory(
	.RA1(ALUResult),
	.RD1(ReadData),
	.WD(RD2),
	.WE(MemWrite),
	.clk(clk)
);

    // clock generator (period = 10 time units)
    //initial clk = 0;
    //always #5 clk = ~clk;

endmodule
