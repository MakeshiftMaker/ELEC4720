module PC #(
    parameter m = 32
)(
    input  logic              clk,
    input  logic              reset,     // reset PC to 0
    input  logic [m-1:0]      PC_in,     // next PC (from mux or adder)
    output logic [m-1:0]      PC_out     // current PC value
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            PC_out <= '0;               // reset to address 0
        else
            PC_out <= PC_in;            // load next PC each cycle
    end

endmodule

