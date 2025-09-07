// File: long_mult_8_display.sv

module long_mult_8_display (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7*4-1:0] seg_c       // 4 digits for product (LS digit = seg_c[6:0])
);
    // ------------------------------------------------------------------------
    // 1) Multiply a and b
    // ------------------------------------------------------------------------
    logic [15:0] product;

    long_mult_8 long_mult (
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



// File: long_mult_8.sv

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

    //same as Q2, the hardware implementation does not allow the compiler to automatically use arithmatic blocks, making this implementation less efficient and more resource intensive

    // Sum the partial products
    assign c = p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7;

endmodule

// File: mult_8_display.sv
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


// File: mult_8.sv
//8 bit multiplier module using descriptive implementation

module mult_8(
	input logic [7:0] a,b, //input
	output logic [15:0] c //result
);

	assign c = a * b;

	//due to the descriptive implementation, this allows the fpga compiler to use arithmatic blocks and be more efficient/less resource intensive
endmodule

// File: Q3_all.sv

// File: tb_long_mult_8_display.sv
module tb_long_mult_8_display;

    logic [7:0] a, b;
    logic [7*4-1:0] seg_c; // two digits packed: {MS digit [13:7], LS digit [6:0]}

    // DUT (see name mismatch note above)
    long_mult_8_display dut (
        .a(a),
        .b(b),
        .seg_c(seg_c)
    );

    initial begin
        $display("   time |    a  |    b  | product (on 7-seg bus)");
        $display("-------------------------------------------------");

        // Small values
        a = 8'd3;   b = 8'd5;    #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd9;   b = 8'd9;    #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);

        // Edge cases
        a = 8'd0;   b = 8'd0;    #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd0;   b = 8'd200;  #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd255; b = 8'd1;    #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);

        // Larger products
        a = 8'd100; b = 8'd200;  #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd123; b = 8'd45;   #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);
        a = 8'd255; b = 8'd255;  #5;  $display("%6t | %4d | %4d | %028b", $time, a, b, seg_c);

        $finish;
    end

endmodule
// File: tb_long_mult_8.sv
module tb_long_mult_8;
    logic [7:0] a, b;
    logic [15:0] c;

    long_mult_8 uut (
        .a(a),
        .b(b),
        .c(c)
    );

    initial begin
        // Header
        $display("   Time |   a   |   b   |     c");
        $display("----------------------------------");

        // Test 1: 5 * 10 = 50
        a = 8'd5; b = 8'd10;
        #10 $display("%6t | %3d  | %3d  | %5d", $time, a, b, c);

        // Test 2: 15 * 3 = 45
        a = 8'd15; b = 8'd3;
        #10 $display("%6t | %3d  | %3d  | %5d", $time, a, b, c);

        // Test 3: 255 * 2 = 510
        a = 8'd255; b = 8'd2;
        #10 $display("%6t | %3d  | %3d  | %5d", $time, a, b, c);

        // Test 4: 100 * 200 = 20000
        a = 8'd100; b = 8'd200;
        #10 $display("%6t | %3d  | %3d  | %5d", $time, a, b, c);

        $stop;
    end
endmodule

