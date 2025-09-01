module mult_8_display (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7*4-1:0] seg_c       // 4 digits for product (LS digit = seg_c[6:0])
);
    // ------------------------------------------------------------------------
    // 1) Multiply a and b
    // ------------------------------------------------------------------------
    logic [15:0] product;

    mult_8 mult (
        .a(~a),
        .b(b),
        .c(product)
    );


    // Show product on 4 digits
    multi_digit_display #(.NUM_DIGITS(4)) disp_c (
        .number(product),
        .seg   (seg_c)
    );

endmodule

