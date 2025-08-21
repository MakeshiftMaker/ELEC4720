// ============================================================================
// tb_seven_segment_decoder
// ----------------------------------------------------------------------------
/*
Purpose:
  Unit-test the seven_segment_decoder:
  - Verify segment patterns for D=0..F (ACTIVE-LOW outputs).
  - Verify ripple blanking behavior w.r.t. RBI/RBO:
      * When D==0 and RBI==0 → seg must BLANK, RBO==0 (propagate request).
      * Otherwise → RBO==1 (stop blanking), seg shows decoded value.

Monitored prints:
  Time | D | RBI | SEG | RBO
  where SEG is the ACTIVE-LOW [a..g] bus (0=ON, 1=OFF).
*/
// ============================================================================

module tb_seven_segment_decoder;
    logic [3:0] D;        // test digit
    logic       RBI;      // blank request in (active-low)
    logic [6:0] seg;      // ACTIVE-LOW segments
    logic       RBO;      // blank request out (active-low)

    // DUT
    seven_segment_decoder uut (
        .D(D),
        .RBI(RBI),
        .seg(seg),
        .RBO(RBO)
    );

    // Drive stimulus
    initial begin
        $display("Time | D | RBI |    SEG    | RBO");
        $monitor("%4t | %1h |  %b  | %07b |  %b", $time, D, RBI, seg, RBO);

        // ------------------------------------------------------------
        // 1) With RBI=1 (no blank request), decoder should always show
        //    the correct glyph and RBO should be 1 (no propagation).
        // ------------------------------------------------------------
        RBI = 1;
        for (int i = 0; i < 16; i++) begin
            D = i[3:0];
            #10;
        end

        // ------------------------------------------------------------
        // 2) With RBI=0 (blank request), behavior depends on D:
        //    - If D==0: BLANK (all segments OFF) and RBO==0 (propagate).
        //    - If D!=0: SHOW digit and RBO==1 (stop propagation).
        //    Sequence below hits both cases in order.
        // ------------------------------------------------------------
        D = 4'h0; RBI = 0; #10; // expect seg blank, RBO=0
        D = 4'h1; RBI = 0; #10; // expect "1" glyph, RBO=1
        D = 4'h0; RBI = 0; #10; // back to blank case
        D = 4'hA; RBI = 0; #10; // "A", RBO=1

        // Optional: corner checks for hex letters
        D = 4'hB; RBI = 1; #10;
        D = 4'hC; RBI = 1; #10;
        D = 4'hD; RBI = 1; #10;
        D = 4'hE; RBI = 1; #10;
        D = 4'hF; RBI = 1; #10;

        $finish;
    end
endmodule


