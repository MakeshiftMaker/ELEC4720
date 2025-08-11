module top_mult4 (
    input  logic [7:0] SW,   // SW[3:0] = a, SW[7:4] = b
    output logic [6:0] HEX0, // Display A
    output logic [6:0] HEX1, // Display B
    output logic [6:0] HEX2, // Product LSB
    output logic [6:0] HEX3  // Product MSB
);
    logic [3:0] a, b;
    logic [7:0] c;

    assign a = SW[3:0];
    assign b = SW[7:4];

    // Multiplier instance
    mult4 u_mult (
        .a(a),
        .b(b),
        .c(c)
    );

    // Display A
    seg_decoder u_hex0 (
        .D(a),
        .RBI(1'b1),
        .a_to_g(HEX0),
        .RBO()
    );

    // Display B
    seg_decoder u_hex1 (
        .D(b),
        .RBI(1'b1),
        .a_to_g(HEX1),
        .RBO()
    );

    // Product LSB
    seg_decoder u_hex2 (
        .D(c[3:0]),
        .RBI(1'b1),
        .a_to_g(HEX2),
        .RBO()
    );

    // Product MSB
    seg_decoder u_hex3 (
        .D(c[7:4]),
        .RBI(1'b1),
        .a_to_g(HEX3),
        .RBO()
    );

endmodule
