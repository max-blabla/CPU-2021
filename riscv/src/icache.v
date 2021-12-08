`include "parameters.v"

module ic #(
    parameter EntryNum = 127,
    parameter TagLength = 8,
    parameter PointerLength = 6
)(
    input clk,
    input rst,
    input [`PcLength:`Zero] pc_from_iq,
    input [`DataLength:`Zero] instr_from_fc,
    input is_finish_from_fc,
    input is_empty_from_iq,
    input is_stall_from_fc,
    input is_instr_from_fc,
    output [`PcLength:`Zero] addr_to_fc,
    output is_empty_to_fc,
    output is_hit_to_iq,
    output [`DataLength:`Zero] instr_to_iq
);
reg valid [EntryNum:`Zero];
reg [TagLength:`Zero] tag [EntryNum:`Zero];
reg [`DataLength:`Zero] cache [EntryNum:`Zero];    
reg [`PcLength:`Zero] pc;
reg [`DataLength:`Zero] instr;
reg is_empty; 
reg is_hit;
reg [PointerLength:`Zero] index;
integer i;
always @(posedge clk) 
begin
    if(is_finish_from_fc == `True && is_instr_from_fc == `True ) begin
        index[6:0] = pc[6:0];
        is_hit <= `True;
        valid[index] <= `True;
        cache[index] <= instr_from_fc;
        tag[index] <= pc[15:7];
        instr <= instr_from_fc;
    end
    if(is_hit == `True) is_hit <= `False;
    if(is_empty_from_iq == `False) begin
        index[6:0] = pc_from_iq[6:0];  
        if(tag[index] == pc_from_iq[15:7] && valid[index] == `True) begin
            instr <= cache[index];
            is_hit <= `True;
        end
        else begin
            pc <= pc_from_iq;
            is_empty<=`False;
            is_hit <= `False;
        end
    end
    else begin
        is_empty <= `True;
    end
    if(is_stall_from_fc == `False && is_empty == `False) begin
        is_empty <= `True;
    end
end
always @(posedge rst) begin
    for(i = 0 ; i <= EntryNum; i = i + 1) valid[i] <= 0;
end
assign is_hit_to_iq = is_hit;
assign instr_to_iq = instr;
assign addr_to_fc =pc;
assign is_empty_to_fc = is_empty;
endmodule 