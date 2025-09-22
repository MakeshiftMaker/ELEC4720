module alu #(
    parameter N = 32
)(
    input  logic [N-1:0] A, B,
    input  logic [3:0]   F,
    output logic [N-1:0] Y,
    output logic Cout,    // carry out
    output logic OV       // overflow flag
);

    logic signed [N-1:0] As, Bs;  
    assign As = A;
    assign Bs = B;

    always_comb begin
        // default assignments so Quartus is happy
        Y    = '0;
        Cout = 1'b0;
        OV   = 1'b0;

        case (F)
            4'b0000: begin // signed add
                {Cout, Y} = As + Bs;
                OV   = (As[N-1] == Bs[N-1]) && (Y[N-1] != As[N-1]);
            end

            4'b0001: begin // unsigned add
                {Cout, Y} = A + B;
                OV   = 1'b0;
            end

            4'b0010: begin // signed sub
                {Cout, Y} = As - Bs;
                OV   = (As[N-1] != Bs[N-1]) && (Y[N-1] != As[N-1]);
            end

            4'b0011: begin // unsigned sub
                {Cout, Y} = A - B;
                OV   = 1'b0;
            end

            4'b0100: Y = A & B;     
            4'b0101: Y = A | B;     
            4'b0110: Y = A ^ B;     
            4'b0111: Y = ~(A | B);  

            4'b1010: Y = (As < Bs) ? 1 : 0;  // signed less than
            4'b1011: Y = (A < B)   ? 1 : 0;  // unsigned less than

            default: ; // already covered by defaults at top
        endcase
    end
endmodule
