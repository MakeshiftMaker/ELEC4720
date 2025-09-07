// File: instruction_classifier.sv
module instruction_classifier (
    input  logic [5:0] opcode,
    output logic [5:0] opcode_out,
    output logic R, B1, J, B2, I, F, M
);

    assign opcode_out = opcode; //we need an output to drive the leds'

    //using assign, the compiler automatically creates the most optimal logic-gate array using boolean arithmatic, instead of using a chain of if/else statements. This allows it to have minimal propogation delay.

    // R-type: opcode == 000000
    assign R  = (opcode == 6'b000000);

    // B1: opcode == 000001
    assign B1 = (opcode == 6'b000001);

    // J-type: opcode[5:1] == 00001x  -> check upper 5 bits
    assign J  = (opcode[5:1] == 5'b00001);

    // B2: opcode[5:3] == 0001xx
    assign B2 = (opcode[5:2] == 4'b0001);

    // I: opcode[5:3] == 001xxx
    assign I  = (opcode[5:3] == 3'b001);

    // F: opcode[5:4] == 01xxxx
    assign F  = (opcode[5:4] == 2'b01);

    // M: opcode[5] == 1xxxx
    assign M  = opcode[5];

endmodule

// File: Q6_all.sv

// File: tb_instruction_classifier.sv
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

