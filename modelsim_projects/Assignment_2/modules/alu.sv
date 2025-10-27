module alu #(
    parameter N = 32
)(
    input  logic [N-1:0] A,      // first operand
    input  logic [N-1:0] B,      // second operand
    input  logic [3:0]   F,      // ALU control signal
    output logic [N-1:0] Y,      // ALU result
    output logic         Zero,    // 1 if result is zero
    output logic         OV       // overflow flag for signed ops
);

    // Signed versions of operands for signed operations
    logic signed [N-1:0] As;
    logic signed [N-1:0] Bs;
    logic [N:0] sum; // for unsigned operations carry/overflow detection

    always_comb begin
        As  = $signed(A);
        Bs  = $signed(B);
        sum = '0;

        // Defaults
        Y  = '0;
        OV = 1'b0;

        case(F)
            // -------------------------------
            // ADD (signed)
            4'b0000: begin
                Y  = As + Bs;
                OV = (As[N-1] == Bs[N-1]) && (Y[N-1] != As[N-1]);
            end

            // ADDU (unsigned)
            4'b0001: begin
                sum = {1'b0, A} + {1'b0, B};
                Y   = sum[N-1:0];
                OV  = 1'b0; // ignore overflow
            end

            // SUB (signed)
            4'b0010: begin
                Y  = As - Bs;
                OV = (As[N-1] != Bs[N-1]) && (Y[N-1] != As[N-1]);
            end

            // SUBU (unsigned)
            4'b0011: begin
                sum = {1'b0, A} - {1'b0, B};
                Y   = sum[N-1:0];
                OV  = 1'b0; // ignore overflow
            end

            // Bitwise operations
            4'b0100: Y = A & B;  // AND
            4'b0101: Y = A | B;  // OR
            4'b0110: Y = A ^ B;  // XOR
            4'b0111: Y = ~(A | B); // NOR

            // Set on less than
            4'b1010: Y = (As < Bs) ? 32'd1 : 32'd0;  // SLT (signed)
            4'b1011: Y = (A < B) ? 32'd1 : 32'd0;    // SLTU (unsigned)

            default: begin
                Y  = '0;
                OV = 1'b0;
            end
        endcase
    end

    // Zero flag (for branch instructions)
    assign Zero = (Y == 0);

endmodule

