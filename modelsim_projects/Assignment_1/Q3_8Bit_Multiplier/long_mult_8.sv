
// 8-bit multiplier using long multiplication
module long_mult_8 (
    input  logic [7:0] a, // 8-bit input A
    input  logic [7:0] b, // 8-bit input B
    output logic [15:0] c // 16-bit product
);
    logic [15:0] p0, p1, p2, p3, p4, p5, p6, p7;

    // Partial products
    assign p0 = {8'b00000000, (a & {8{b[0]}})};
    assign p1 = {7'b0000000,  (a & {8{b[1]}}), 1'b0};
    assign p2 = {6'b000000,   (a & {8{b[2]}}), 2'b00};
    assign p3 = {5'b00000,    (a & {8{b[3]}}), 3'b000};
    assign p4 = {4'b0000,     (a & {8{b[4]}}), 4'b0000};
    assign p5 = {3'b000,      (a & {8{b[5]}}), 5'b00000};
    assign p6 = {2'b00,       (a & {8{b[6]}}), 6'b000000};
    assign p7 = {1'b0,        (a & {8{b[7]}}), 7'b0000000};

    // Sum the partial products
    assign c = p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7;

endmodule
