module dataMemory #(
    parameter ADDR_WIDTH = 8  // number of word address bits -> 2^ADDR_WIDTH words
)(
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wd,
    output logic [31:0] rd
);

    localparam int WORDS = 1 << ADDR_WIDTH;

    // Simple word-addressable memory
    logic [31:0] mem [0:WORDS-1];

    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2]; // ignore byte lanes

    // Asynchronous read
    assign rd = mem[word_addr];

    // Synchronous write
    always_ff @(posedge clk) begin
        if (we) begin
            mem[word_addr] <= wd;
        end
    end

    // Initialise memory to zero
    initial begin
        for (int i = 0; i < WORDS; i++) begin
            mem[i] = 32'd0;
        end
    end

endmodule
