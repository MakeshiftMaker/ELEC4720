// 4-bit multiplier using long multiplication
module mult4 (
    input  logic [3:0] a, // 4-bit input A
    input  logic [3:0] b, // 4-bit input B
    output logic [7:0] c  // 8-bit product
);
    logic [7:0] p0, p1, p2, p3;
    // Partial products

    //due to us using long multiplication (hardware) and not descriptive multiplication, the fpga will not be using the implemented arithmetic blocks, which results in more blocks being used in an inefficient way

    assign p0 = {4'b0000, a & {4{b[0]}}};
    assign p1 = {3'b000,  a & {4{b[1]}}, 1'b0};
    assign p2 = {2'b00,   a & {4{b[2]}}, 2'b00};
    assign p3 = {1'b0,    a & {4{b[3]}}, 3'b000};

    // Sum the partial products
    assign c = p0 + p1 + p2 + p3;

endmodule
