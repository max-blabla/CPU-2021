`include "parameters.v"

module ic #(
    parameter EntryNum = 127,
    parameter TagLength = 7,
    parameter PointerLength = 6
)(
    input clk,
    input rst,
    input [`PcLength:`Zero] pc_from_iq,
    input [`DataLength:`Zero] instr_from_fc,
    input is_commit_from_fc,
    input is_empty_from_iq,
    input is_instr_from_fc,
    input is_exception_from_rob,
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
reg [PointerLength:`Zero] index;

reg en_exception;
reg en_commit;
reg en_stall;
reg en_instr;
reg en_empty;
reg en_rst;
integer i;
integer fp_w;
initial begin
    fp_w = $fopen("./instr.txt","w");

end
always @(posedge clk) begin
    en_rst = rst;
    en_commit = is_commit_from_fc;
    en_instr = is_instr_from_fc;
    en_empty = is_empty_from_iq;
    en_exception = is_exception_from_rob;
    if(en_rst == `True) begin
        for(i = 0 ; i <= EntryNum; i = i + 1) valid[i] <= 0;
    end
    else begin
        if(en_exception == `True) begin
            is_hit <= `False;
            is_issue <= `False;
            is_empty <= `True;
        end
        else begin
            if(en_commit == `True && en_instr == `True && is_issue ==`True ) begin
                index[6:0] = pc[8:2];
                is_hit <= `True;
                valid[index] <= `True;
                cache[index] <= instr_from_fc;
                tag[index] <= pc[16:9];
                instr <= instr_from_fc;
                is_issue <= `False;
                $fwrite(fp_w,"%x ",instr_from_fc);
                $fwrite(fp_w,"%x\n",pc_from_iq);
            end
            if(is_hit == `True) is_hit <= `False;

            if(en_empty == `False) begin
                index[6:0] = pc_from_iq[8:2];  
                if(tag[index] == pc_from_iq[16:9] && valid[index] == `True) begin
                    instr <= cache[index];
                    is_hit <= `True;
                    $fwrite(fp_w,"%x ",cache[index]);
                    $fwrite(fp_w,"%x\n",pc_from_iq);
                end
                else begin
                    if(tag[index] != pc_from_iq[16:9]) begin
                //    $display("%x",tag[index]);
                //    $display("%x",pc_from_iq[16:9]);
                //    $display("%x",index);
                //    $display("%x",pc_from_iq);
                    end
                    pc <= pc_from_iq;
                    is_empty <= `False;
                    is_hit <= `False;
                    is_issue <= `True;
                end
            end
            if( is_empty == `False) begin
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