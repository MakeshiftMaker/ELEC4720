module multi_digit_display #(
    parameter int NUM_DIGITS = 4
)(
    input  logic [NUM_DIGITS*4-1:0] number,
    output logic [NUM_DIGITS-1:0][6:0] seg
);
    logic [NUM_DIGITS-1:0] rbo;
    logic [NUM_DIGITS-1:0] rbi;

    // Most significant digit's RBI comes from outside
    assign rbi[NUM_DIGITS-1] = 1'b0; // start blanking for leading zeros

    // Chain from MSB to LSB
    for (genvar i = NUM_DIGITS-2; i >= 0; i--) begin
        assign rbi[i] = rbo[i+1];
    end

    // Instantiate digits: MSB is highest index
    for (genvar i = 0; i < NUM_DIGITS; i++) begin : digits
        seven_segment_decoder dec (
            .D   (number[i*4 +: 4]),
            .RBI (rbi[i]),
            .seg (seg[i]),
            .RBO (rbo[i])
        );
    end
endmodule

