module tb_seven_segment_decoder;
    logic [3:0] D;
    logic RBI;
    logic [6:0] seg;
    logic RBO;

    seven_segment_decoder uut (
        .D(D),
        .RBI(RBI),
        .seg(seg),
        .RBO(RBO)
    );

    initial begin
        $display("Time | D | RBI | SEG | RBO");
        $monitor("%4t | %h |  %b  | %b |  %b", $time, D, RBI, seg, RBO);

        // Test all values with RBI = 1 (no blanking)
        RBI = 1;
        for (int i = 0; i < 16; i++) begin
            D = i;
            #10;
        end

        // Test RBI = 0 to blank leading zero
        D = 4'h0; RBI = 0; #10;
        D = 4'h1; RBI = 0; #10;

        $finish;
    end
endmodule

