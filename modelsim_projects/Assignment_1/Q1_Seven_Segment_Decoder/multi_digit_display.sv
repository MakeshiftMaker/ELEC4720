module multi_digit_display #(
    parameter int NUM_DIGITS = 4
)(
    input  logic [NUM_DIGITS*4-1:0] number,
    output logic [NUM_DIGITS-1:0][6:0] seg
);
    logic [NUM_DIGITS-1:0] rbo; // ripple blanking output
    logic [NUM_DIGITS-1:0] rbi; // ripple blanking input

    // Most significant digit's RBI comes from outside
    assign rbi[NUM_DIGITS-1] = 1'b0;

    // propagate RBI from MSB to LSB
    genvar i;
    generate
        for (i = 0; i < NUM_DIGITS-1; i = i + 1) begin : rbi_chain
            assign rbi[NUM_DIGITS-2-i] = rbo[NUM_DIGITS-1-i];
        end
    endgenerate

    // Instantiate digits: MSB is highest index
    generate
        for (i = 0; i < NUM_DIGITS; i = i + 1) begin : digits
            seven_segment_decoder dec (
                .D   (number[i*4 +: 4]),
                .RBI (rbi[i]),
                .seg (seg[i]),
                .RBO (rbo[i])
            );
        end
    endgenerate
endmodule

