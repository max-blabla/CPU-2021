`include "parameters.v"
module ic #(
    parameter EntryNum = 127,
    parameter TagLength = 7,
    parameter PointerLength = 6
)(
    input clk,
    input rst,
    input rdy,
    input [`PcLength:`Zero] pc_from_iq,
    input [`DataLength:`Zero] instr_from_fc,
    input is_commit_from_fc,
    input is_empty_from_iq,
    input is_instr_from_fc,
    input is_ready_from_fc,
    input is_exception_from_rob,
    input is_empty_from_slb,
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
reg is_issue;
reg is_request;
//reg [PointerLength:`Zero] index;

//reg en_exception;
//reg en_commit;
//reg en_stall;
//reg en_instr;
//reg en_empty;
//reg en_rst;
//reg en_rdy;
integer i;
always @(posedge clk) begin
    if(rst == `True) begin
        for(i = 0 ; i <= EntryNum; i = i + 1)begin
            valid[i] <= 0;
            tag[i] <= 0;
            cache[i] <= 0;
        end 
        pc <= 0;
        instr <= 0;
        is_empty <= `True;
        is_hit <= `False;
        is_issue <= `False;
        is_request <= `False;
    end
    else if(rdy == `False) begin
        
    end
    else begin
        if(is_exception_from_rob == `True) begin
            is_hit <= `False;
            is_issue <= `False;
            is_empty <= `True;
            is_request <= `False;
        end
        else begin
            if(is_commit_from_fc == `True && is_instr_from_fc == `True && is_issue ==`True ) begin
            //    index[6:0] = pc[8:2];
                is_hit <= `True;
                valid[pc_from_iq[8:2]] <= `True;
                cache[pc_from_iq[8:2]] <= instr_from_fc;
                tag[pc_from_iq[8:2]] <= pc[16:9];
                instr <= instr_from_fc;
                is_issue <= `False;
            end
            if(is_hit == `True) is_hit <= `False;

            if(is_empty_from_iq == `False||is_request == `True) begin
             //   index[6:0] = pc_from_iq[8:2];  
                if(tag[pc_from_iq[8:2]] == pc_from_iq[16:9] && valid[pc_from_iq[8:2]] == `True) begin
                    instr <= cache[pc_from_iq[8:2]];
                    is_hit <= `True;
                    is_request <= `False;
                end
                else if(is_ready_from_fc==`True ) begin
                    pc <= pc_from_iq;
                    is_empty <= `False;
                    is_hit <= `False;
                    is_request <= `False;
                    is_issue <= `True;
                end
                else is_request <= `True;
            end
            if( is_empty == `False && is_empty_from_slb == `True ) begin
                is_empty <= `True;
            end
        end
    end
end
assign is_hit_to_iq = is_hit;
assign instr_to_iq = instr;
assign addr_to_fc =pc;
assign is_empty_to_fc = is_empty;
endmodule 