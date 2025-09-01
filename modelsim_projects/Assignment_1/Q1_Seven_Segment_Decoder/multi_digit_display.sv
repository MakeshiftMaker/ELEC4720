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

