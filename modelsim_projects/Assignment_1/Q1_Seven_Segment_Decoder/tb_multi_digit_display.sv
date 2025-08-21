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
