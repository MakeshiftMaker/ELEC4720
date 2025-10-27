module mips_fpga_top (
    input  logic        clk_50,       // Board system clock (e.g. 50 MHz)
    input  logic        reset_btn_n,  // Active-low reset push button
    input  logic        step_btn_n,   // Active-low single-step push button
    input  logic [9:0]  sw,           // Slide switches
    output logic [6:0]  hex0,
    output logic [6:0]  hex1,
    output logic [6:0]  hex2,
    output logic [6:0]  hex3,
    output logic [9:0]  led
);

    // Debounce buttons
    logic reset_level;
    logic step_level;

    button_debouncer #(.COUNTER_BITS(18)) reset_db (
        .clk      (clk_50),
        .btn_n    (reset_btn_n),
        .debounced(reset_level)
    );

    button_debouncer #(.COUNTER_BITS(18)) step_db (
        .clk      (clk_50),
        .btn_n    (step_btn_n),
        .debounced(step_level)
    );

    // Generate a single-cycle pulse for each debounced button press
    logic step_pulse;
    edge_pulse step_edge (
        .clk  (clk_50),
        .level(step_level),
        .pulse(step_pulse)
    );

    // Register selection switches (5 bits)
    logic [4:0] reg_sel;
    logic       pc_select;
    logic       hi_select;

    assign reg_sel   = sw[4:0];
    assign pc_select = sw[5];
    assign hi_select = sw[6];

    // Core signals
    logic [31:0] pc_value;
    logic [31:0] rom_word;
    logic [31:0] reg_value;
    logic        dbg_mem_write;
    logic        dbg_reg_write;
    logic        dbg_branch;
    logic        dbg_jump;

    // Instantiate the CPU core. Use the step pulse as the clock so each press advances one instruction.
    mips cpu_core (
        .clk           (step_pulse),
        .reset         (reset_level),
        .dbg_reg_sel   (reg_sel),
        .dbg_reg_value (reg_value),
        .pc_out        (pc_value),
        .rom_data      (rom_word),
        .dbg_mem_write (dbg_mem_write),
        .dbg_reg_write (dbg_reg_write),
        .dbg_branch    (dbg_branch),
        .dbg_jump      (dbg_jump)
    );

    // Select which 16-bit word to display
    logic [31:0] display_source;
    logic [15:0] display_word;

    assign display_source = pc_select ? pc_value : reg_value;
    assign display_word   = hi_select ? display_source[31:16] : display_source[15:0];

    // Drive seven-segment displays with hex digits (HEX0 is least significant digit)
    hex7seg h0 (.hex(display_word[3:0]),   .seg(hex0));
    hex7seg h1 (.hex(display_word[7:4]),   .seg(hex1));
    hex7seg h2 (.hex(display_word[11:8]),  .seg(hex2));
    hex7seg h3 (.hex(display_word[15:12]), .seg(hex3));

    // LEDs for quick visual feedback
    assign led[4:0] = reg_sel;
    assign led[5]   = pc_select;
    assign led[6]   = hi_select;
    assign led[7]   = dbg_mem_write;
    assign led[8]   = dbg_reg_write;
    assign led[9]   = dbg_jump;

endmodule
