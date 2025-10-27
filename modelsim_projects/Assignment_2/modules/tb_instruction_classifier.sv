module tb_instruction_classifier;

    logic [5:0] opcode;
    logic [5:0] opcode_out;
    logic R, B1, J, B2, I, F, M;
    logic exp_R, exp_B1, exp_J, exp_B2, exp_I, exp_F, exp_M;
    logic [6:0] expected_flags, actual_flags;
    int   error_count = 0;

    instruction_classifier dut (
        .opcode     (opcode),
        .opcode_out (opcode_out),
        .R          (R),
        .B1         (B1),
        .J          (J),
        .B2         (B2),
        .I          (I),
        .F          (F),
        .M          (M)
    );

    initial begin
        $display("Opcode | R B1 J B2 I F M");
        for (int i=0; i<64; i++) begin
            opcode = i[5:0];
            #1; // small delay to propagate

            exp_R  = (opcode == 6'b000000);
            exp_B1 = (opcode == 6'b000001);
            exp_J  = (opcode[5:1] == 5'b00001);
            exp_B2 = (opcode[5:2] == 4'b0001);
            exp_I  = (opcode[5:3] == 3'b001);
            exp_F  = (opcode[5:4] == 2'b01);
            exp_M  = opcode[5];

            expected_flags = {exp_R, exp_B1, exp_J, exp_B2, exp_I, exp_F, exp_M};
            actual_flags   = {R, B1, J, B2, I, F, M};

            $display("%06b | %b %b %b %b %b %b %b", opcode, R, B1, J, B2, I, F, M);

            if (opcode_out !== opcode) begin
                $error("Opcode echo mismatch: expected %06b, got %06b", opcode, opcode_out);
                error_count++;
            end

            if (actual_flags !== expected_flags) begin
                $error("Classification mismatch at opcode %06b: expected %07b, got %07b",
                       opcode, expected_flags, actual_flags);
                error_count++;
            end

            if ($countones(actual_flags) != $countones(expected_flags)) begin
                $error("Category overlap/priority issue at opcode %06b: expected %0d highs, got %0d",
                       opcode, $countones(expected_flags), $countones(actual_flags));
                error_count++;
            end
        end

        if (error_count == 0) begin
            $display("All opcode classifications passed.");
        end else begin
            $fatal(1, "%0d classification errors detected.", error_count);
        end

        $finish;
    end

endmodule
