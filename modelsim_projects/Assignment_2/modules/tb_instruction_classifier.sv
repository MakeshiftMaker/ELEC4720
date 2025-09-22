module tb_instruction_classifier;

    logic [5:0] opcode;
    logic R, B1, J, B2, I, F, M;

    instruction_classifier dut (.opcode(opcode), .R(R), .B1(B1), .J(J),
                          .B2(B2), .I(I), .F(F), .M(M));

    initial begin
        $display("Opcode | R B1 J B2 I F M");
        for (int i=0; i<64; i++) begin
            opcode = i;
            #1; // small delay to propagate
            $display("%06b | %b %b %b %b %b %b %b", opcode, R, B1, J, B2, I, F, M);
        end
        $finish;
    end

endmodule
