module mult4_display (
    input  logic [3:0] a,
    input  logic [3:0] b,
    output logic [6:0] seg_a,       // single digit
    output logic [6:0] seg_b,       // single digit
    output logic [13:0] seg_c       // 2 digits
);
    // Product
    logic [7:0] product;

    // Multiplier
    mult4 u_mult (
        .a(a),
        .b(b),
        .c(product)
    );

    // Displays
    multi_digit_display #(.NUM_DIGITS(1)) disp_a (
        .number(a),
        .seg(seg_a)
    );

    multi_digit_display #(.NUM_DIGITS(1)) disp_b (
        .number(b),
        .seg(seg_b)
    );

    multi_digit_display #(.NUM_DIGITS(2)) disp_c (
        .number(product),
        .seg(seg_c)
    );

endmodule

