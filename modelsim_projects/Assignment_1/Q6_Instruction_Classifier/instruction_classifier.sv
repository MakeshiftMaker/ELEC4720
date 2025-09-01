module instruction_classifier (
    input  logic [5:0] opcode,
    output logic R, B1, J, B2, I, F, M
);

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
