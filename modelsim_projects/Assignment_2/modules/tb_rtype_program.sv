module tb_rtype_program;

    localparam int INSTR_COUNT = 12;

    // Instruction memory loaded with the provided R-type sequence.
    logic [31:0] instr_mem [0:INSTR_COUNT-1] = '{
        32'h01084023,
        32'h012A5821,
        32'h012B6022,
        32'h018D7020,
        32'h012D8024,
        32'h012D8825,
        32'h012D9026,
        32'h012D9827,
        32'h018EA02A,
        32'h018EA82B,
        32'h00000000,
        32'h00000000
    };

    // Simple register file for the testbench.
    logic [31:0] reg_file [0:31];

    // Decoded instruction fields.
    logic [31:0] instr;
    logic [5:0]  opcode, funct;
    logic [4:0]  rs, rt, rd, shamt;
    logic [15:0] imm16;

    // Control and datapath signals.
    logic        MemtoReg, MemWrite, Branch, ALUSrc, RegDst, RegWrite;
    logic [3:0]  ALUControl;
    logic [31:0] imm_ext;
    logic [31:0] rs_val, rt_val;
    logic [31:0] alu_A, alu_B, alu_Y;
    logic        Zero, OV;

    // Helper wires for formatted output.
    logic [4:0] dest_reg;
    string      dest_name, op_name, writeback;

    // Instantiate the control unit and ALU from the design.
    ControlUnit control (
        .opcode    (opcode),
        .funct     (funct),
        .MemtoReg  (MemtoReg),
        .MemWrite  (MemWrite),
        .Branch    (Branch),
        .ALUControl(ALUControl),
        .ALUSrc    (ALUSrc),
        .RegDst    (RegDst),
        .RegWrite  (RegWrite)
    );

    signExtend se_imm (
        .in  (imm16),
        .out (imm_ext)
    );

    alu #(.N(32)) alu_core (
        .A   (alu_A),
        .B   (alu_B),
        .F   (ALUControl),
        .Y   (alu_Y),
        .Zero(Zero),
        .OV  (OV)
    );

    // Register name helper for nicer printing.
    function string reg_name(input logic [4:0] idx);
        case (idx)
            5'd0:  reg_name = "$zero";
            5'd8:  reg_name = "$t0";
            5'd9:  reg_name = "$t1";
            5'd10: reg_name = "$t2";
            5'd11: reg_name = "$t3";
            5'd12: reg_name = "$t4";
            5'd13: reg_name = "$t5";
            5'd14: reg_name = "$t6";
            5'd16: reg_name = "$s0";
            5'd17: reg_name = "$s1";
            5'd18: reg_name = "$s2";
            5'd19: reg_name = "$s3";
            5'd20: reg_name = "$s4";
            5'd21: reg_name = "$s5";
            default: reg_name = $sformatf("$r%0d", idx);
        endcase
    endfunction

    // Decode the mnemonic for logging purposes (R-type subset only).
    function string decode_opcode(input logic [5:0] op, input logic [5:0] fn);
        if (op == 6'b000000) begin
            case (fn)
                6'h20: decode_opcode = "add";
                6'h21: decode_opcode = "addu";
                6'h22: decode_opcode = "sub";
                6'h23: decode_opcode = "subu";
                6'h24: decode_opcode = "and";
                6'h25: decode_opcode = "or";
                6'h26: decode_opcode = "xor";
                6'h27: decode_opcode = "nor";
                6'h2A: decode_opcode = "slt";
                6'h2B: decode_opcode = "sltu";
                6'h00: decode_opcode = "nop";
                default: decode_opcode = "rtype?";
            endcase
        end else begin
            decode_opcode = "unsupported";
        end
    endfunction

    initial begin
        // Initialise registers to zero then seed the ones used by the program.
        foreach (reg_file[idx]) reg_file[idx] = 32'd0;

        reg_file[8]  = 32'd9;   // $t0
        reg_file[9]  = 32'd21;  // $t1
        reg_file[10] = 32'd2;   // $t2
        reg_file[13] = 32'd3;   // $t5

        $display("Running R-type sequence through ControlUnit + ALU");
        $display("----------------------------------------------------------------------------");
        $display("PC Instr      Mnemonic | rs            rt            -> ALU_Y    Zero OV | Writeback");

        for (int pc = 0; pc < INSTR_COUNT; pc++) begin
            instr  = instr_mem[pc];
            opcode = instr[31:26];
            rs     = instr[25:21];
            rt     = instr[20:16];
            rd     = instr[15:11];
            shamt  = instr[10:6];
            funct  = instr[5:0];
            imm16  = instr[15:0];

            rs_val = reg_file[rs];
            rt_val = reg_file[rt];

            #1; // allow combinational control logic to settle

            alu_A = rs_val;
            alu_B = (ALUSrc) ? imm_ext : rt_val;

            if ($isunknown(ALUControl) || $isunknown(RegDst) ||
                $isunknown(RegWrite) || $isunknown(ALUSrc)) begin
                $fatal(1, "Control signals unknown at PC %0d (opcode %0b funct %0b)", pc, opcode, funct);
            end

            if ($isunknown(alu_A) || $isunknown(alu_B)) begin
                $fatal(1, "Operand contains X at PC %0d: A=%h B=%h", pc, alu_A, alu_B);
            end

            #1; // allow ALU to compute result

            dest_reg = RegDst ? rd : rt;
            dest_name = reg_name(dest_reg);
            op_name   = decode_opcode(opcode, funct);

            if (RegWrite && dest_reg != 5'd0) begin
                reg_file[dest_reg] = alu_Y;
                writeback = $sformatf("%s = 0x%08h", dest_name, reg_file[dest_reg]);
            end else begin
                writeback = "none";
            end

            $display("%2d 0x%08h %-7s | %s=0x%08h %s=0x%08h -> 0x%08h  %0b    %0b | %s",
                     pc, instr, op_name,
                     reg_name(rs), rs_val,
                     reg_name(rt), rt_val,
                     alu_Y, Zero, OV, writeback);

            #1;
        end

        $display("----------------------------------------------------------------------------");
        $display("Final register values of interest:");
        $display("$t0=0x%08h $t1=0x%08h $t2=0x%08h $t3=0x%08h",
                 reg_file[8], reg_file[9], reg_file[10], reg_file[11]);
        $display("$t4=0x%08h $t5=0x%08h $t6=0x%08h",
                 reg_file[12], reg_file[13], reg_file[14]);
        $display("$s0=0x%08h $s1=0x%08h $s2=0x%08h $s3=0x%08h",
                 reg_file[16], reg_file[17], reg_file[18], reg_file[19]);
        $display("$s4=0x%08h $s5=0x%08h",
                 reg_file[20], reg_file[21]);

        $finish;
    end

endmodule
