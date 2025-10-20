module tb_mips1;

    logic clk;
    logic reset;
    logic [31:0] pc_out;
    logic [31:0] rom_data;

    // Instantiate the MIPS module
    mips dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .rom_data(rom_data)
    );

    // Clock generation: 10ns period
    initial begin
	clk = 0;
	forever #5 clk = ~clk;
    end
    // Simulation setup
    initial begin
        $display("Starting simulation...");

        // Apply reset
        reset = 1;
        @(posedge clk);
        reset = 0;
	$display("Reset Released...");

        // Run for enough cycles to execute all instructions
        repeat (20) @(posedge clk);

        $display("Simulation finished.");
        $stop;
    end

    // Monitor outputs
    initial begin
        $display("Time\tPC\t\tInstruction");
        $monitor("%0t\t%h\t%h", $time, pc_out, rom_data);
    end

endmodule

