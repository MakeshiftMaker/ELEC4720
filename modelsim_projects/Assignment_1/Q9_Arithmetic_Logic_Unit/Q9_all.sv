// File: alu.sv
module alu #(
    parameter N = 32
)(
    input  logic [N-1:0] A, B,
    input  logic [3:0]   F,
    output logic [N-1:0] Y,
    output logic Cout,    // carry out
    output logic OV       // overflow flag
);

    logic signed [N-1:0] As, Bs;  
    assign As = A;
    assign Bs = B;

    always_comb begin
        // default assignments so Quartus is happy
        Y    = '0;
        Cout = 1'b0;
        OV   = 1'b0;

        case (F)
            4'b0000: begin // signed add
                {Cout, Y} = As + Bs;
                OV   = (As[N-1] == Bs[N-1]) && (Y[N-1] != As[N-1]);
            end

            4'b0001: begin // unsigned add
                {Cout, Y} = A + B;
                OV   = 1'b0;
            end

            4'b0010: begin // signed sub
                {Cout, Y} = As - Bs;
                OV   = (As[N-1] != Bs[N-1]) && (Y[N-1] != As[N-1]);
            end

            4'b0011: begin // unsigned sub
                {Cout, Y} = A - B;
                OV   = 1'b0;
            end

            4'b0100: Y = A & B;     
            4'b0101: Y = A | B;     
            4'b0110: Y = A ^ B;     
            4'b0111: Y = ~(A | B);  

            4'b1010: Y = (As < Bs) ? 1 : 0;  // signed less than
            4'b1011: Y = (A < B)   ? 1 : 0;  // unsigned less than

            default: ; // already covered by defaults at top
        endcase
    end
endmodule

// File: Q9_all.sv

// File: tb_alu.sv
`timescale 1ns/1ps

module tb_alu;

    parameter N = 8; // small width for easier viewing
    logic [N-1:0] A, B;
    logic [3:0]   F;
    logic [N-1:0] Y;
    logic Cout, OV;

    // Instantiate ALU
    alu #(.N(N)) uut (
        .A(A), .B(B), .F(F), .Y(Y), .Cout(Cout), .OV(OV)
    );

    initial begin
        $display("Time | F | A | B | Y | Cout | OV");
        $monitor("%4t | %b | %0d | %0d | %0d | %b | %b",
                 $time, F, A, B, Y, Cout, OV);

        // Test signed add
        A = 8'd50;  B = 8'd10;  F = 4'b0000; #10;
        A = 8'd100; B = 8'd100; F = 4'b0000; #10;

        // Test unsigned add
        A = 8'hFF; B = 8'd1; F = 4'b0001; #10;

        // Test signed sub
        A = -8'd20; B = 8'd5; F = 4'b0010; #10;

        // Test unsigned sub
        A = 8'd5; B = 8'd10; F = 4'b0011; #10;

        // Logic ops
        A = 8'hAA; B = 8'h55; F = 4'b0100; #10; // AND
        F = 4'b0101; #10; // OR
        F = 4'b0110; #10; // XOR
        F = 4'b0111; #10; // NOR

        // Signed less than
        A = -8'd5; B = 8'd3; F = 4'b1010; #10;

        // Unsigned less than
        A = 8'd5; B = 8'd250; F = 4'b1011; #10;

        $finish;
    end
endmodule

// File: top_alu_fpga.sv
module top_alu_fpga (
    input  logic [3:0] A, B,   // A and B inputs
    input  logic [3:0] F,  // ALU control F
    output logic [3:0] Y,  // ALU result Y
    output logic [6:0] seg_a, seg_b, seg_y,
    output logic Cout, OV,
    output logic [3:0] A_out, B_out
);

    assign A_out = ~A;
    assign B_out = B;

    alu #(.N(3)) alu_inst (
        .A(A), .B(B), .F(F), .Y(Y), .Cout(Cout), .OV(OV)
    );
    
    multi_digit_display #(.NUM_DIGITS(1)) disp_a (
        .number(A),
	.seg(seg_a)
    );
  
    multi_digit_display #(.NUM_DIGITS(1)) disp_b (
        .number(B),
	.seg(seg_b)
    );

    multi_digit_display #(.NUM_DIGITS(1)) disp_y (
        .number(Y),
	.seg(seg_y)
    );
endmodule

