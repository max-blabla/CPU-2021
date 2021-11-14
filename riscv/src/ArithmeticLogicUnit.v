`include "parameters.v"
module alu (
    input rst,
    input clk,
    input wire[`DataLength:`Zero] v1_from_rs,
    input wire[`DataLength:`Zero] v2_from_rs,
    input wire[`DataLength:`Zero] imm_from_rs,
    input wire[`DataLength:`Zero] pc_from_rs,
    output wire[`DataLength:`Zero] data_to_rob,
    output wire[`DataLength:`Zero] pc_to_rob,
    output wire is_finish_to_rob

    
);

reg [`PcLength:`Zero] pc;
reg [`DataLength:`Zero] data;
reg is_finish;

always @(posedge rst) begin
    pc <= 0;
    data <= 0;
    is_finish <= 0;
end
assign pc_to_rob = pc;
assign data_to_rob = data;
assign is_finish_to_rob = is_finish; 
endmodule