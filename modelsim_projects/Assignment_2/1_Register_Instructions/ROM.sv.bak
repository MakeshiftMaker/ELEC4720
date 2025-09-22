module ROM #(parameter m=7,p=4) (
input logic [m-1:0] Ad,
output logic [p-1:0] Dout
);
logic [p-1:0] mem[2**m-1:0];
assign Dout = mem[Ad];
//Load the program in memory
// The machine code stored
// in text file program.dat
// written in Hex format
initial begin
$readmemh("program.dat",mem); //$readmemb for binary
end
endmodule