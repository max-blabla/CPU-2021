module decoder (
    input wire[31:0] instr_input,
    input wire clk,
    output wire w
);
    reg[31:0] instr;
    reg[7:0] opcode;
    always @(posedge clk) begin
        instr[31:0] <= instr_input[31:0]; 
        opcode[7:0] <= instr_input[31:24];
       
    end
    

endmodule