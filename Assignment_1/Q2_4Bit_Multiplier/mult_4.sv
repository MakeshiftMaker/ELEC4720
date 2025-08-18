module mult_4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    output logic [7:0] c
);
    assign c = a * b;
endmodule

