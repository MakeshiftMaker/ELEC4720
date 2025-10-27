module regfile(
input logic clk, WE,
input logic [4:0] RA1, RA2, WA,
input logic [31:0] WD,
output logic [31:0] RD1, RD2,
input  logic [4:0] RA3,
output logic [31:0] RD3);
logic [31:0] rf[31:0] = '{default:32'b0};
always_ff @(posedge clk)
if (WE) rf[WA] <= WD;
assign RD1 = (RA1 != 0) ? rf[RA1] : 0;
assign RD2 = (RA2 != 0) ? rf[RA2] : 0;
assign RD3 = (RA3 != 0) ? rf[RA3] : 0;
endmodule
