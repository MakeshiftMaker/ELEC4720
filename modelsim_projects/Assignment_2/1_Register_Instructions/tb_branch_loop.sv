module tb_branch_loop;

    logic clk;
    logic reset;
    logic [31:0] pc_out;
    logic [31:0] rom_data;
    logic [31:0] dbg_val;
    logic dbg_mem, dbg_reg, dbg_branch, dbg_jump;

    int branch_taken = 0;

    mips dut (
        .clk(clk),
        .reset(reset),
        .dbg_reg_sel(5'd0),
        .dbg_reg_value(dbg_val),
        .pc_out(pc_out),
        .rom_data(rom_data),
        .dbg_mem_write(dbg_mem),
        .dbg_reg_write(dbg_reg),
        .dbg_branch(dbg_branch),
        .dbg_jump(dbg_jump)
    );

    // 10 ns clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        @(posedge clk);
        reset = 0;

        repeat (80) begin
            @(posedge clk);
            if (dut.PCSrc && pc_out != 32'h0000004C) begin
                branch_taken++;
            end
        end

        $display("Branch taken count: %0d", branch_taken);
        if (branch_taken == 0) begin
            $fatal(1, "Expected at least one taken branch, got %0d", branch_taken);
        end

        if (dut.regfile_inst.rf[8] !== 32'h0000000A) begin
            $fatal(1, "Loop counter (t0) mismatch: got %08h", dut.regfile_inst.rf[8]);
        end

        $display("tb_branch_loop completed successfully.");
        $stop;
    end

    initial begin
        $display("Time\tPC\t\tInstr\tBranch PCSrc Zero");
        forever begin
            @(posedge clk);
            $display("%0t\t%08h\t%08h\t%b\t%b\t%b",
                     $time, pc_out, rom_data,
                     dut.Branch, dut.PCSrc, dut.Zero);
        end
    end

endmodule
