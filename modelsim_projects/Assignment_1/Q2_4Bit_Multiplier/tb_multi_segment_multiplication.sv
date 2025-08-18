module tb_mult4_display;

    logic [3:0] a, b;
    logic [6:0] seg_a, seg_b;
    logic [13:0] seg_c;

    mult4_display dut (
        .a(a),
        .b(b),
        .seg_a(seg_a),
        .seg_b(seg_b),
        .seg_c(seg_c)
    );

    initial begin
        a = 4'd3; b = 4'd5; #5;
        $display("a=%d, b=%d, seg_a=%b, seg_b=%b, seg_c=%b", a, b, seg_a, seg_b, seg_c);

        a = 4'd7; b = 4'd8; #5;
        $display("a=%d, b=%d, seg_a=%b, seg_b=%b, seg_c=%b", a, b, seg_a, seg_b, seg_c);

        a = 4'd0; b = 4'd15; #5;
        $display("a=%d, b=%d, seg_a=%b, seg_b=%b, seg_c=%b", a, b, seg_a, seg_b, seg_c);

        a = 4'd15; b = 4'd15; #5;
        $display("a=%d, b=%d, seg_a=%b, seg_b=%b, seg_c=%b", a, b, seg_a, seg_b, seg_c);

        $finish;
    end

endmodule

