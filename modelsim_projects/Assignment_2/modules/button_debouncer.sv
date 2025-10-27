module button_debouncer #(
    parameter integer COUNTER_BITS = 16  // number of bits in debounce counter
)(
    input  logic clk,
    input  logic btn_n,       // active-low push button
    output logic debounced    // active-high when button is pressed
);

    // Synchronise to clock domain and convert to active-high
    logic sync0, sync1;
    always_ff @(posedge clk) begin
        sync0 <= ~btn_n;
        sync1 <= sync0;
    end

    logic [COUNTER_BITS-1:0] cnt;
    logic stable_state;

    always_ff @(posedge clk) begin
        if (sync1 == stable_state) begin
            cnt <= '0;
        end else begin
            cnt <= cnt + 1'b1;
            if (&cnt) begin
                stable_state <= sync1;
                cnt <= '0;
            end
        end
    end

    assign debounced = stable_state;

endmodule
