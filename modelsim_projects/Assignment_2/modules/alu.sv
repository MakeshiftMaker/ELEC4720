module alu #(
    parameter N = 32
)(
    input  logic [N-1:0] A, B,
    input  logic [3:0]   F,        // function code
    output logic [N-1:0] Y,
    output logic         Cout,     // carry-out for unsigned ops
    output logic         OV        // overflow flag for signed ops
);

    // Function codes (for readability)
    localparam [3:0]
        ADD  = 4'b0000,
        ADDU = 4'b0001,
        SUB  = 4'b0010,
        SUBU = 4'b0011,
        AND  = 4'b0100,
        OR   = 4'b0101,
        XOR  = 4'b0110,
        NOR  = 4'b0111,
        SLT  = 4'b1010,
        SLTU = 4'b1011;

    // internal signals
    logic signed [N-1:0] As = $signed(A);
    logic signed [N-1:0] Bs = $signed(B);
    logic [N:0] sum; // N+1 bits for carry out

    always_comb begin
        // defaults
        Y    = '0;
        Cout = 1'b0;
        OV   = 1'b0;

        case(F)
            ADD: begin
                // signed add: OV meaningful, Cout not used
                Y  = As + Bs;
                OV = (As[N-1] == Bs[N-1]) && (Y[N-1] != As[N-1]);
                Cout = 1'b0;
            end

            ADDU: begin
                // unsigned add: Cout meaningful
                sum  = {1'b0, A} + {1'b0, B};
                Y    = sum[N-1:0];
                Cout = sum[N];
                OV   = 1'b0;
            end

            SUB: begin
                // signed subtraction
                Y  = As - Bs;
                OV = (As[N-1] != Bs[N-1]) && (Y[N-1] != As[N-1]);
                Cout = 1'b0;
            end

            SUBU: begin
                // unsigned subtraction: borrow represented in Cout
                sum  = {1'b0, A} - {1'b0, B};
                Y    = sum[N-1:0];
                Cout = sum[N];  // Cout=0 => borrow occurred
                OV   = 1'b0;
            end

            AND:  Y = A & B;
            OR:   Y = A | B;
            XOR:  Y = A ^ B;
            NOR:  Y = ~(A | B);

            SLT:  Y = (As < Bs) ? 32'd1 : 32'd0;  // signed less than
            SLTU: Y = (A < B)   ? 32'd1 : 32'd0;  // unsigned less than

            default: begin
                Y    = '0;
                Cout = 1'b0;
                OV   = 1'b0;
            end
        endcase
    end

endmodule

