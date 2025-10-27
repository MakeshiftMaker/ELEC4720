module edge_pulse (
    input  logic clk,
    input  logic level,   // synchronous, active-high
    output logic pulse
);
    logic prev;
    always_ff @(posedge clk) begin
        prev  <= level;
        pulse <= level & ~prev;
    end
endmodule
