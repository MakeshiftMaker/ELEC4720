//==================================================
// MIPS Control Unit (combinational logic)
// Supports: R-type, addi, addiu
//==================================================
module ControlUnit(
    input  logic [5:0] opcode,    // bits [31:26] of instruction
    input  logic [5:0] funct,     // bits [5:0] of instruction
    output logic       MemtoReg,
    output logic       MemWrite,
    output logic       Branch,
    output logic [3:0] ALUControl, // ALU operation selector
    output logic       ALUSrc,
    output logic       RegDst,
    output logic       RegWrite
);

    always_comb begin
        // Default values (safe state)
        MemtoReg  = 0;
        MemWrite  = 0;
        Branch    = 0;
        ALUControl = 4'b0000;
        ALUSrc    = 0;
        RegDst    = 0;
        RegWrite  = 0;

        case (opcode)
            6'b000000: begin // R-type
                MemtoReg  = 0;
                MemWrite  = 0;
                Branch    = 0;
                ALUSrc    = 0;
                RegDst    = 1;
                RegWrite  = 1;
                ALUControl = funct[3:0]; // lower 4 bits of funct select ALU op
            end

            6'b001000: begin // addi
                MemtoReg  = 0;
                MemWrite  = 0;
                Branch    = 0;
                ALUSrc    = 1;
                RegDst    = 0;
                RegWrite  = 1;
                ALUControl = 4'b0000; // add
            end

            6'b001001: begin // addiu
                MemtoReg  = 0;
                MemWrite  = 0;
                Branch    = 0;
                ALUSrc    = 1;
                RegDst    = 0;
                RegWrite  = 1;
                ALUControl = 4'b0001; // addu
            end

            default: begin
                // no-op for unsupported instructions
                MemtoReg  = 0;
                MemWrite  = 0;
                Branch    = 0;
                ALUSrc    = 0;
                RegDst    = 0;
                RegWrite  = 0;
                ALUControl = 4'b0000;
            end
        endcase
    end
endmodule
