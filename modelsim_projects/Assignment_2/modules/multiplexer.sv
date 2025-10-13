// Generic N-input multiplexer
module multiplexer #(
    parameter N = 2,                     // number of inputs
    parameter WIDTH = 1                  // bit-width of each input
)(
    input  logic [WIDTH-1:0] input_bits [N-1:0],  // N inputs of WIDTH bits each
    input  logic [$clog2(N)-1:0] selection,       // select signal
    output logic [WIDTH-1:0] selected_output      // selected output
);

    always_comb begin
        selected_output = input_bits[selection];
    end

endmodule
