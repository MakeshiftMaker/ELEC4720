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
    output logic       RegWrite,
    output logic       Jump
);

    logic [5:0] opcode_echo;
    logic       isR, isB1, isJ, isB2, isI, isF, isM;

    // Decode opcode once and reuse the category bits throughout the control logic.
    instruction_classifier opcode_decoder (
        .opcode     (opcode),
        .opcode_out (opcode_echo),
        .R          (isR),
        .B1         (isB1),
        .J          (isJ),
        .B2         (isB2),
        .I          (isI),
        .F          (isF),
        .M          (isM)
    );

    always_comb begin
        // Default values (safe state)
        MemtoReg   = 0;
        MemWrite   = 0;
        Branch     = 0;
        ALUControl = 4'b0000;
        ALUSrc     = 0;
        RegDst     = 0;
        RegWrite   = 0;
        Jump       = 0;

        if (isR) begin
            // R-type instructions take the destination from rd and use ALU result.
            RegDst     = 1;
            RegWrite   = 1;
            ALUControl = funct[3:0]; // lower 4 bits of funct select ALU op
        end
        else if (isI) begin
            // Immediate ALU instructions write back to rt and use the immediate value.
            RegWrite = 1;
            ALUSrc   = 1;
            unique case (opcode)
                6'b001000: ALUControl = 4'b0000; // addi -> signed add
                6'b001001: ALUControl = 4'b0001; // addiu -> unsigned add
                default:   ALUControl = 4'b0000; // default to signed add for unimplemented I-type
            endcase
        end
        else if (isB1 || isB2) begin
            // Branch classes use rs, rt comparison; ALU subtract checks equality.
            Branch     = 1;
            ALUControl = 4'b0010; // subtract to drive Zero flag
        end
        else if (isM) begin
            // Memory access instructions (lw, sw)
            ALUSrc   = 1;
            RegDst   = 0;
            ALUControl = 4'b0000; // base address + offset

            unique case (opcode)
                6'b100011: begin // lw
                    MemtoReg = 1;
                    MemWrite = 0;
                    RegWrite = 1;
                end

                6'b101011: begin // sw
                    MemtoReg = 0;
                    MemWrite = 1;
                    RegWrite = 0;
                end

                default: begin
                    MemtoReg = 0;
                    MemWrite = 0;
                    RegWrite = 0;
                end
            endcase
        end
        else if (isJ) begin
            Jump = 1;
        end

        // opcode_echo is driven to avoid unconnected warnings; it is otherwise unused.
    end
endmodule
