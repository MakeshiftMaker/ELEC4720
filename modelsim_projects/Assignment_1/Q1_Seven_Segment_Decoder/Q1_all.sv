// File: multi_digit_display.sv
// ============================================================================
// multi_digit_display
// ----------------------------------------------------------------------------
// Purpose:
//   Drive N hexadecimal digits on 7-segment displays using one decoder per digit,
//   with proper "ripple blanking" so that leading zeros are suppressed.
//
// Interface:
//   - NUM_DIGITS : number of hex digits to display (default 4).
//   - number     : packed bus of NUM_DIGITS nibbles; number[3:0] is the least-
//                  significant digit (LSD), number[NUM*4-1:NUM*4-4] is the most-
//                  significant digit (MSD).
//   - seg        : per-digit 7-segment outputs [a..g]. Each seg[i] is a 7-bit
//                  vector for one digit. (Polarity depends on your decoder.)
// 
// Notes:
//   - This module assumes the child module `seven_segment_decoder` exposes
//     the 9368-style Ripple Blanking In/Out (RBI/RBO) interface. Asserting RBI
//     on a digit will blank that digit *if and only if* its input nibble is zero;
//     the decoder then passes a "blank" request downstream via RBO.
//   - We seed RBI=0 (asserted) into the MSD so that a run of leading zeros blanks
//     from the left, but a non-zero MSD stops the blanking chain.
//   - Digit indexing: i = 0 is the **least** significant digit; i = NUM_DIGITS-1
//     is the **most** significant digit. The ripple chain flows from MSD → LSD.
// ============================================================================

module multi_digit_display #(
    parameter int NUM_DIGITS = 4
)(
    input  logic [NUM_DIGITS*4-1:0]     number,   // Packed hex digits: {MSD ... LSD}
    output logic [NUM_DIGITS-1:0][6:0]  seg       // Per-digit 7-seg outputs [a..g]
);

    // Per-digit ripple blanking nets:
    //   rbi[i] feeds the RBI pin of digit i,
    //   rbo[i] is returned from the RBO pin of digit i.
    logic [NUM_DIGITS-1:0] rbo; // ripple blanking OUT  (from decoder)
    logic [NUM_DIGITS-1:0] rbi; // ripple blanking IN   (to decoder)

    // ------------------------------------------------------------------------
    // Seed the blanking chain:
    //   - Assert RBI on the most-significant digit so that leading zeros may be
    //     blanked starting from the left.
    //   - If MSD is non-zero, its decoder de-asserts RBO, stopping the chain.
    //   - If MSD is zero, its decoder asserts RBO, passing the blank request on.
    // ------------------------------------------------------------------------
    assign rbi[NUM_DIGITS-1] = 1'b0;  // 0 = "blank request present" (active level depends on decoder)

    // ------------------------------------------------------------------------
    // Propagate RBI from MSB to LSB:
    //   For NUM_DIGITS = 4, this builds:
    //     rbi[2] = rbo[3];
    //     rbi[1] = rbo[2];
    //     rbi[0] = rbo[1];
    //   meaning digit i receives RBI from digit (i+1).
    // ------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < NUM_DIGITS-1; i = i + 1) begin : rbi_chain
            // Map: rbi[MSD-1-i] = rbo[MSD-i]
            assign rbi[NUM_DIGITS-2-i] = rbo[NUM_DIGITS-1-i];
        end
    endgenerate

    // ------------------------------------------------------------------------
    // Instantiate one decoder per digit.
    //   - number[i*4 +: 4] selects nibble i (SystemVerilog "indexed part-select"):
    //       i=0 → bits [3:0]   (LSD)
    //       i=1 → bits [7:4]
    //       ...
    //       i=NUM_DIGITS-1 → [NUM*4-1 : NUM*4-4] (MSD)
    //   - rbi[i]/rbo[i] connect the blanking chain as documented above.
    //
    //   seg[i] is the 7-segment bus for digit i. If your physical board expects
    //   a different ordering (e.g., common anode with active-low), that mapping
    //   should be handled inside seven_segment_decoder.
    // ------------------------------------------------------------------------
    generate
        for (i = 0; i < NUM_DIGITS; i = i + 1) begin : digits
            seven_segment_decoder dec (
                .D   ( number[i*4 +: 4] ), // 4-bit hex nibble for this digit
                .RBI ( rbi[i] ),           // ripple blanking in  (from more-significant digit)
                .seg ( seg[i] ),           // 7-segment outputs [a..g] for this digit
                .RBO ( rbo[i] )            // ripple blanking out (to less-significant digit)
            );
        end
    endgenerate

endmodule


// File: Q1_all.sv

// File: seven_segment_decoder.sv
// ============================================================================
// seven_segment_decoder
// ----------------------------------------------------------------------------
// Purpose:
//   Decode a 4-bit hexadecimal nibble (D) into 7-segment drive signals (a..g)
//   with support for 9368-style Ripple Blanking In/Out (RBI/RBO).
//
// Display model:
//   - seg[6:0] corresponds to segments {a,b,c,d,e,f,g}.
//   - ACTIVE-LOW outputs: 0 = LED ON, 1 = LED OFF.
//   - Truth table patterns inside the case assume active-HIGH segment patterns,
//     then the module inverts (~) to produce active-LOW outputs.
//
// Ripple blanking semantics (9368-style):
//   - RBI is an input "blank request" that propagates from the more-significant
//     digit (MSD) towards the less-significant digit (LSD).
//   - When RBI is asserted (active-low; i.e., RBI==0) AND D==0, this digit
//     should BLANK (all segments OFF) and assert RBO to continue the blanking
//     downstream to the next less-significant digit.
//   - If D != 0, this digit must SHOW the value and deassert RBO to stop blanking.
//   - If RBI==1 (no blank request), the digit behaves normally and RBO deasserts.
//
// Notes:
//   - This module does not implement the 9368's "LE" latch; it is purely combinational.
//   - Ensure this module’s ACTIVE-LOW polarity matches your board wiring.
//
// ============================================================================

module seven_segment_decoder (
    input  logic [3:0] D,        // 4-bit input hex digit (0..F)
    input  logic       RBI,      // Ripple Blanking IN (active-low): 0=request to blank zeros
    output logic [6:0] seg,      // 7-seg outputs [a..g], ACTIVE-LOW (0=ON)
    output logic       RBO       // Ripple Blanking OUT (active-low): 0=propagate blank request
);
    logic zero; // true when D == 0

    always_comb begin
        // --------------------------------------------------------------------
        // Default: all segments OFF (since active-low, OFF = 1)
        // --------------------------------------------------------------------
        seg  = ~7'b0000000;
        zero = (D == 4'd0);

        // --------------------------------------------------------------------
        // Decode: active-HIGH patterns for hexadecimal 0..F,
        // then invert (~) once to get active-LOW drive signals.
        //
        // Pattern key (active-HIGH): bit order is {a,b,c,d,e,f,g}
        // '1' = segment lit (prior to inversion), '0' = segment dark.
        // After inversion, lit segments become 0 (active-low).
        // --------------------------------------------------------------------
        unique case (D)
            4'h0: seg = ~7'b1111110; // 0 => a,b,c,d,e,f ON; g OFF
            4'h1: seg = ~7'b0110000; // 1 => b,c ON
            4'h2: seg = ~7'b1101101; // 2
            4'h3: seg = ~7'b1111001; // 3
            4'h4: seg = ~7'b0110011; // 4
            4'h5: seg = ~7'b1011011; // 5
            4'h6: seg = ~7'b1011111; // 6
            4'h7: seg = ~7'b1110000; // 7
            4'h8: seg = ~7'b1111111; // 8
            4'h9: seg = ~7'b1111011; // 9
            4'hA: seg = ~7'b1110111; // A
            4'hB: seg = ~7'b0011111; // b (lowercase-style)
            4'hC: seg = ~7'b1001110; // C
            4'hD: seg = ~7'b0111101; // d (lowercase-style)
            4'hE: seg = ~7'b1001111; // E
            4'hF: seg = ~7'b1000111; // F
            // No default: all 16 cases covered
        endcase

        // --------------------------------------------------------------------
        // Ripple blanking: If this digit is zero AND a blank request is present
        // (RBI == 0), we BLANK this digit (all segments OFF) and assert RBO=0
        // to propagate the blanking downstream. Otherwise, RBO=1 (no request).
        // --------------------------------------------------------------------
        if (zero && !RBI) begin
            seg = ~7'b0000000;       // blank: all OFF (active-low => 1's)
            RBO = 1'b0;              // propagate blank request (active-low)
        end else begin
            RBO = 1'b1;              // stop blanking chain
        end
    end
endmodule

// File: tb_multi_digit_display.sv
// ============================================================================
// tb_multi_digit_display
// ----------------------------------------------------------------------------
// Purpose:
//   Simple sweep testbench for multi_digit_display. It drives a packed hex
//   number bus and watches the per-digit 7-segment outputs and the blanking
//   interaction between digits.
//
// Strategy:
//   - Parameterize NUM_DIGITS (default 4).
//   - Iterate 'number' through all values in range [0 .. 2^(4*NUM_DIGITS)-1].
//   - $monitor prints time, the input number, and seg[] per digit.
//   - This exercise is good for sanity on indexing (nibble extraction) and
//     on RBI/RBO chaining correctness across digits.
//
// Notes:
//   - seg is ACTIVE-LOW from the DUT. Values shown are raw [a..g] bitfields.
//   - The DUT relies on seven_segment_decoder implementing 9368-style blanking.
// ============================================================================

module tb_multi_digit_display;

    // Parameters
    localparam int NUM_DIGITS = 4; // try other sizes if desired

    // Signals
    logic [NUM_DIGITS*4-1:0]    number; // Packed hex digits (LSD at [3:0])
    logic [NUM_DIGITS-1:0][6:0] seg;    // Per-digit [a..g] (ACTIVE-LOW)

    // DUT (Device Under Test)
    multi_digit_display #(.NUM_DIGITS(NUM_DIGITS)) uut (
        .number(number),
        .seg(seg)
    );

    // Test sequence
    initial begin
        $display("Time | Number | Segments (per digit, index 0 = LSD)");
        $monitor("%4t | 0x%0h | %p", $time, number, seg);

        // Sweep ALL values: exercises blanking from 0000..000F up to FFFF.
        // Increase #delay if waveforms look cramped.
        for (int val = 0; val < (1 << (NUM_DIGITS*4)); val++) begin
            number = val;
            #10;
        end

        $finish;
    end

endmodule

// File: tb_seven_segment_decoder.sv
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



