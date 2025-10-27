module tb_mips1;

    logic clk;
    logic reset;
    logic [31:0] pc_out;
    logic [31:0] rom_data;
    logic [4:0]  dbg_sel = 5'd0;
    logic [31:0] dbg_value;
    logic dbg_mem, dbg_reg, dbg_branch, dbg_jump;

    // Decoded instruction fields for logging
    logic [5:0] opcode, funct;
    logic [4:0] rs, rt, rd;
    logic [15:0] imm16;
    logic [25:0] jump_addr;

    string instr_name;
    string detail;

    // Instantiate the MIPS module
    mips dut (
        .clk(clk),
        .reset(reset),
        .dbg_reg_sel(dbg_sel),
        .dbg_reg_value(dbg_value),
        .pc_out(pc_out),
        .rom_data(rom_data),
        .dbg_mem_write(dbg_mem),
        .dbg_reg_write(dbg_reg),
        .dbg_branch(dbg_branch),
        .dbg_jump(dbg_jump)
    );

    // Clock generation: 10ns period
    initial begin
	clk = 0;
	forever #5 clk = ~clk;
    end
    int branch_taken = 0;
    bit jump_seen = 0;
    bit jump_target_ok = 0;

    always_ff @(posedge clk) begin
        if (reset) begin
            branch_taken   <= 0;
            jump_seen      <= 0;
            jump_target_ok <= 0;
        end else begin
            if (dut.PCSrc && pc_out != 32'h0000004C)
                branch_taken <= branch_taken + 1;
            if (dut.Jump)
                jump_seen <= 1;
            if (pc_out == 32'h0000003C)
                jump_target_ok <= 1;
        end
    end

    // Simulation setup
    initial begin
        $display("Starting simulation...");

        // Apply reset
        reset = 1;
        @(posedge clk);
        reset = 0;
	$display("Reset Released...");

        // Run for enough cycles to execute all instructions
        repeat (80) @(posedge clk);

        $display("Final register state:");
        $display("$t0=%08h $t1=%08h $t2=%08h $t3=%08h",
                 dut.regfile_inst.rf[8], dut.regfile_inst.rf[9],
                 dut.regfile_inst.rf[10], dut.regfile_inst.rf[11]);
        $display("$t4=%08h $t5=%08h $t6=%08h",
                 dut.regfile_inst.rf[12], dut.regfile_inst.rf[13],
                 dut.regfile_inst.rf[14]);
        $display("$t7=%08h $t8=%08h $t9=%08h",
                 dut.regfile_inst.rf[15], dut.regfile_inst.rf[24],
                 dut.regfile_inst.rf[25]);
        $display("$s0=%08h $s1=%08h $s2=%08h $s3=%08h $s4=%08h $s5=%08h $s6=%08h $s7=%08h",
                 dut.regfile_inst.rf[16], dut.regfile_inst.rf[17],
                 dut.regfile_inst.rf[18], dut.regfile_inst.rf[19],
                 dut.regfile_inst.rf[20], dut.regfile_inst.rf[21],
                 dut.regfile_inst.rf[22], dut.regfile_inst.rf[23]);

        // Self-checks for Question 2 expected results
        if (dut.regfile_inst.rf[8]  !== 32'h0000000A) $fatal(1, "t0 mismatch: got %08h", dut.regfile_inst.rf[8]);
        if (dut.regfile_inst.rf[9]  !== 32'h00000007) $fatal(1, "t1 mismatch: got %08h", dut.regfile_inst.rf[9]);
        if (dut.regfile_inst.rf[10] !== 32'h00000007) $fatal(1, "t2 mismatch: got %08h", dut.regfile_inst.rf[10]);
        if (dut.regfile_inst.rf[11] !== 32'h0000000E) $fatal(1, "t3 mismatch: got %08h", dut.regfile_inst.rf[11]);
        if (dut.regfile_inst.rf[12] !== 32'hFFFFFFF9) $fatal(1, "t4 mismatch: got %08h", dut.regfile_inst.rf[12]);
        if (dut.regfile_inst.rf[13] !== 32'h0000000A) $fatal(1, "t5 mismatch: got %08h", dut.regfile_inst.rf[13]);
        if (dut.regfile_inst.rf[14] !== 32'h00000003) $fatal(1, "t6 mismatch: got %08h", dut.regfile_inst.rf[14]);
        if (dut.regfile_inst.rf[15] !== 32'h00000040) $fatal(1, "t7 mismatch: got %08h", dut.regfile_inst.rf[15]);
        if (dut.regfile_inst.rf[24] !== 32'h00000000) $fatal(1, "t8 mismatch: got %08h", dut.regfile_inst.rf[24]);
        if (dut.regfile_inst.rf[25] !== 32'h00000000) $fatal(1, "t9 mismatch: got %08h", dut.regfile_inst.rf[25]);

        if (dut.regfile_inst.rf[16] !== 32'h00000002) $fatal(1, "s0 mismatch: got %08h", dut.regfile_inst.rf[16]);
        if (dut.regfile_inst.rf[17] !== 32'h0000000F) $fatal(1, "s1 mismatch: got %08h", dut.regfile_inst.rf[17]);
        if (dut.regfile_inst.rf[18] !== 32'h0000000D) $fatal(1, "s2 mismatch: got %08h", dut.regfile_inst.rf[18]);
        if (dut.regfile_inst.rf[19] !== 32'hFFFFFFF0) $fatal(1, "s3 mismatch: got %08h", dut.regfile_inst.rf[19]);
        if (dut.regfile_inst.rf[20] !== 32'h00000001) $fatal(1, "s4 mismatch: got %08h", dut.regfile_inst.rf[20]);
        if (dut.regfile_inst.rf[21] !== 32'h00000000) $fatal(1, "s5 mismatch: got %08h", dut.regfile_inst.rf[21]);
        if (dut.regfile_inst.rf[22] !== 32'h00000000) $fatal(1, "s6 mismatch: got %08h", dut.regfile_inst.rf[22]);
        if (dut.regfile_inst.rf[23] !== 32'h00000000) $fatal(1, "s7 mismatch: got %08h", dut.regfile_inst.rf[23]);

        if (dut.data_mem.mem[16] !== 32'h00000007) $fatal(1, "Data memory[16] mismatch: got %08h", dut.data_mem.mem[16]);
        if (dut.data_mem.mem[17] !== 32'h00000000) $fatal(1, "Data memory[17] mismatch: got %08h", dut.data_mem.mem[17]);
        if (dut.data_mem.mem[18] !== 32'h00000000) $fatal(1, "Data memory[18] mismatch: got %08h", dut.data_mem.mem[18]);
        if (dut.data_mem.mem[19] !== 32'h00000000) $fatal(1, "Data memory[19] mismatch: got %08h", dut.data_mem.mem[19]);

        if (branch_taken == 0) $fatal(1, "Expected at least one taken branch, got 0");
        if (!jump_seen) $fatal(1, "Jump instruction was never asserted");
        if (!jump_target_ok) $fatal(1, "Jump target PC 0x3C was not observed after jump");

        $display("All register checks passed.");
        $display("Branch takes observed: %0d", branch_taken);
        $display("Jump taken and target reached: %s", jump_target_ok ? "yes" : "no");
        $display("Simulation finished.");
        $stop;
    end

    // Monitor outputs
    initial begin
        string expr;
        $display("Time\tPC\t\tInstruction\tType\tDetails\tExpr\tALUResult\tMemWrite\tMemRead");
        forever begin
            @(posedge clk);
            opcode    = rom_data[31:26];
            rs        = rom_data[25:21];
            rt        = rom_data[20:16];
            rd        = rom_data[15:11];
            funct     = rom_data[5:0];
            imm16     = rom_data[15:0];
            jump_addr = rom_data[25:0];

            instr_name = decode_instruction(opcode, funct);
            detail     = describe_operation(opcode, funct, rs, rt, rd, imm16, jump_addr);
            expr = format_expression(opcode, funct, rs, rt, rd, imm16, jump_addr,
                                     dut.RD1, dut.RD2, dut.ALUResult, dut.ReadData,
                                     dut.MemWrite, (dut.MemtoReg && dut.RegWrite),
                                     dut.PCSrc, dut.Jump, pc_out);

            $display("%0t\t%08h\t%08h\t%s\t%s\t%s\t%08h\t%b\t%b",
                     $time, pc_out, rom_data, instr_name, detail, expr,
                     dut.ALUResult, dut.MemWrite, (dut.MemtoReg && dut.RegWrite));
        end
    end

    // Return a mnemonic string for the current opcode/funct
    function string decode_instruction(input logic [5:0] op, input logic [5:0] fn);
        case (op)
            6'b000000: begin
                case (fn)
                    6'h20: decode_instruction = "add";
                    6'h21: decode_instruction = "addu";
                    6'h22: decode_instruction = "sub";
                    6'h23: decode_instruction = "subu";
                    6'h24: decode_instruction = "and";
                    6'h25: decode_instruction = "or";
                    6'h26: decode_instruction = "xor";
                    6'h27: decode_instruction = "nor";
                    6'h2A: decode_instruction = "slt";
                    6'h2B: decode_instruction = "sltu";
                    6'h00: decode_instruction = "nop";
                    default: decode_instruction = $sformatf("R?%02h", fn);
                endcase
            end
            6'b001000: decode_instruction = "addi";
            6'b001001: decode_instruction = "addiu";
            6'b100011: decode_instruction = "lw";
            6'b101011: decode_instruction = "sw";
            6'b000100: decode_instruction = "beq";
            6'b000010: decode_instruction = "j";
            default:   decode_instruction = $sformatf("OP?%02h", op);
        endcase
    endfunction

    // Provide additional context for the current instruction
    function string describe_operation(
        input logic [5:0] op,
        input logic [5:0] fn,
        input logic [4:0] rs_f,
        input logic [4:0] rt_f,
        input logic [4:0] rd_f,
        input logic [15:0] imm_f,
        input logic [25:0] jump_f
    );
        case (op)
            6'b000000: begin
                describe_operation = $sformatf("rs=$%0d rt=$%0d rd=$%0d", rs_f, rt_f, rd_f);
            end
            6'b001000,
            6'b001001: describe_operation = $sformatf("rt=$%0d rs=$%0d imm=%0d", rt_f, rs_f, $signed(imm_f));
            6'b000100: describe_operation = $sformatf("rs=$%0d rt=$%0d imm=%0d", rs_f, rt_f, $signed(imm_f));
            6'b100011,
            6'b101011: describe_operation = $sformatf("rt=$%0d base=$%0d offset=%0d", rt_f, rs_f, $signed(imm_f));
            6'b000010: describe_operation = $sformatf("target=%08h", {pc_out[31:28], jump_f, 2'b00});
            default:   describe_operation = "";
        endcase
    endfunction

    function string format_expression(
        input logic [5:0] op,
        input logic [5:0] fn,
        input logic [4:0] rs_f,
        input logic [4:0] rt_f,
        input logic [4:0] rd_f,
        input logic [15:0] imm_f,
        input logic [25:0] jump_f,
        input logic [31:0] rs_val,
        input logic [31:0] rt_val,
        input logic [31:0] alu_val,
        input logic [31:0] read_val,
        input bit          mem_write,
        input bit          mem_read,
        input bit          branch_taken_now,
        input bit          jump_now,
        input logic [31:0] pc_val
    );
        string s;
        int signed imm_signed;
        int signed rs_signed;
        int signed rt_signed;
        longint unsigned rs_unsigned;
        longint unsigned rt_unsigned;

        imm_signed   = $signed(imm_f);
        rs_signed    = $signed(rs_val);
        rt_signed    = $signed(rt_val);
        rs_unsigned  = rs_val;
        rt_unsigned  = rt_val;

        case (op)
            6'b001000: s = $sformatf("%0d + %0d = %0d", rs_signed, imm_signed, $signed(alu_val)); // addi
            6'b001001: s = $sformatf("%0u + %0u = %0u", rs_unsigned, (imm_f & 16'hFFFF), $unsigned(alu_val)); // addiu
            6'b000000: begin
                case (fn)
                    6'h20: s = $sformatf("%0d + %0d = %0d", rs_signed, rt_signed, $signed(alu_val)); // add
                    6'h21: s = $sformatf("%0u + %0u = %0u", rs_unsigned, rt_unsigned, $unsigned(alu_val)); // addu
                    6'h22: s = $sformatf("%0d - %0d = %0d", rs_signed, rt_signed, $signed(alu_val)); // sub
                    6'h23: s = $sformatf("%0u - %0u = %0u", rs_unsigned, rt_unsigned, $unsigned(alu_val)); // subu
                    6'h24: s = $sformatf("%h & %h = %h", rs_val, rt_val, alu_val); // and
                    6'h25: s = $sformatf("%h | %h = %h", rs_val, rt_val, alu_val); // or
                    6'h26: s = $sformatf("%h ^ %h = %h", rs_val, rt_val, alu_val); // xor
                    6'h27: s = $sformatf("~(%h | %h) = %h", rs_val, rt_val, alu_val); // nor
                    6'h2A: s = $sformatf("%0d < %0d ? -> %0d", rs_signed, rt_signed, alu_val); // slt
                    6'h2B: s = $sformatf("%0u < %0u ? -> %0d", rs_unsigned, rt_unsigned, alu_val); // sltu
                    default: s = "";
                endcase
            end
            6'b000100: begin
                string taken;
                taken = branch_taken_now ? "taken" : "not taken";
                s = $sformatf("%0d == %0d -> %s", rs_signed, rt_signed, taken);
            end
            6'b100011: begin
                s = $sformatf("Mem[%08h] -> %08h", alu_val, read_val);
            end
            6'b101011: begin
                s = $sformatf("Mem[%08h] <= %08h", alu_val, rt_val);
            end
            6'b000010: begin
                logic [31:0] target;
                target = {pc_val[31:28], jump_f, 2'b00};
                s = $sformatf("PC <= %08h", target);
            end
            default: s = "";
        endcase

        return s;
    endfunction

endmodule
