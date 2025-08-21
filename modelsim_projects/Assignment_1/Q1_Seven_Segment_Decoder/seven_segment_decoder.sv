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
