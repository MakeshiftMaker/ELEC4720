module mips(

    input logic clk,
    input logic reset,
    input logic [4:0] dbg_reg_sel,
    output logic [31:0] dbg_reg_value,
    output logic [31:0] pc_out,
    output logic [31:0] rom_data,
    output logic        dbg_mem_write,
    output logic        dbg_reg_write,
    output logic        dbg_branch,
    output logic        dbg_jump
);
    logic Zero;       // output from ALU
    logic Branch;     // output from the control unit
    logic PCSrc;      // final ANDed signal for PC mux
    logic OV;

    assign PCSrc = Branch & Zero;

    // Control signals
    logic MemtoReg;
    logic MemWrite;
    logic [3:0] ALUControl;
    logic ALUSrc;
    logic RegDst;
    logic RegWrite;
    logic Jump;

    // Internal datapath signals
    logic [31:0] RD1, RD2, SrcB, ALUResult, ReadData, Result;
    logic [31:0] SignImm, PCBranch, pc_plus4, pc_next;
    logic [31:0] branch_offset;
    logic [31:0] pc_branch_sel, PCJump;
    logic [4:0]  writeReg;

    logic [4:0]  writeReg_inputs   [1:0];
    logic [31:0] srcB_inputs       [1:0];
    logic [31:0] writeback_inputs  [1:0];

    assign branch_offset = SignImm << 2;

    // Control Unit instance
    ControlUnit CU (
        .opcode    (rom_data[31:26]),  // instruction[31:26]
        .funct     (rom_data[5:0]),    // instruction[5:0]
        .MemtoReg  (MemtoReg),
        .MemWrite  (MemWrite),
        .Branch    (Branch),
        .ALUControl(ALUControl),
        .ALUSrc    (ALUSrc),
        .RegDst    (RegDst),
        .RegWrite  (RegWrite),
        .Jump      (Jump)
    );

    // Program counter
    PC pc_inst (
        .clk   (clk),
        .reset (reset),
        .PC_in (pc_next),
        .PC_out(pc_out)
    );

    // ROM in byte/word addressing
    ByteIM #(.m(8), .n(2)) rom_inst (
        .Ad(pc_out[7:0]),
        .Dout(rom_data)
    );

    // Multiplexer inputs
    assign writeReg_inputs[0]  = rom_data[20:16];
    assign writeReg_inputs[1]  = rom_data[15:11];
    assign srcB_inputs[0]      = RD2;
    assign srcB_inputs[1]      = SignImm;
    assign writeback_inputs[0] = ALUResult;
    assign writeback_inputs[1] = ReadData;

    multiplexer #(.N(2), .WIDTH(5)) writeReg_multiplexer(
        .input_bits     (writeReg_inputs),
        .selection      (RegDst),
        .selected_output(writeReg)
    );

    multiplexer #(.N(2), .WIDTH(32)) ALU_srcB_multiplexer(
        .input_bits     (srcB_inputs),
        .selection      (ALUSrc),
        .selected_output(SrcB)
    );

    assign pc_branch_sel = PCSrc ? PCBranch : pc_plus4;
    assign PCJump        = {pc_plus4[31:28], rom_data[25:0], 2'b00};
    assign pc_next       = Jump ? PCJump : pc_branch_sel;

    multiplexer #(.N(2), .WIDTH(32)) Writeback_multiplexer(
        .input_bits     (writeback_inputs),
        .selection      (MemtoReg),
        .selected_output(Result)
    );

    regfile regfile_inst(
        .RA1(rom_data[25:21]),
        .RA2(rom_data[20:16]),
        .RD1(RD1),
        .RD2(RD2),
        .WA (writeReg),
        .WE (RegWrite),
        .WD (Result),
        .clk(clk),
        .RA3(dbg_reg_sel),
        .RD3(dbg_reg_value)
    );

    signExtend signExtend_inst(
        .in (rom_data[15:0]),
        .out(SignImm)
    );

    adder PCPlus4_adder(
        .A  (pc_out),
        .B  (32'd4),
        .SUM(pc_plus4)
    );

    adder PCBranch_adder(
        .A  (pc_plus4),
        .B  (branch_offset),
        .SUM(PCBranch)
    );

    alu ALU_inst(
        .A   (RD1),
        .B   (SrcB),
        .Zero(Zero),
        .Y   (ALUResult),
        .F   (ALUControl),
        .OV  (OV)
    );

    dataMemory #(.ADDR_WIDTH(8)) data_mem (
        .clk  (clk),
        .we   (MemWrite),
        .addr (ALUResult),
        .wd   (RD2),
        .rd   (ReadData)
    );

    assign dbg_mem_write = MemWrite;
    assign dbg_reg_write = RegWrite;
    assign dbg_branch    = Branch;
    assign dbg_jump      = Jump;

endmodule
