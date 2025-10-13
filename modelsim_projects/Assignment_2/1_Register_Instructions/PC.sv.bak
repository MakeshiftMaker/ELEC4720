module PC #(
    parameter m = 32
)(
    input  logic        clk,
    input  logic        reset,       // reset PC to 0
    output logic [m-1:0] Ad           // current PC value
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            Ad <= '0;                 // reset to 0
        else
            Ad <= Ad + 4;             // increment by 4 every clock
    end

endmodule

