`include "parameters.v"
module rs
#(
    parameter RsLength = 7,
    parameter PointerLength = 2
)
(
    input wire rst,
    input wire clk,
    input wire is_empty_from_dc,
    input wire is_sl_from_dc,
    input wire is_exception_from_rob,
    input wire is_commit_from_rob,
    input wire[`OpcodeLength:`Zero] op_from_dc,
    input wire[`DataLength:`Zero] v1_from_rf,
    input wire[`DataLength:`Zero] v2_from_rf,
    input wire[`PcLength:`Zero] q1_from_rf,
    input wire[`PcLength:`Zero] q2_from_rf,
    input wire[`DataLength:`Zero] imm_from_dc,
    input wire[`DataLength:`Zero] pc_from_rf,
    input wire[`DataLength:`Zero] pc_from_dc,
    input wire[`DataLength:`Zero] commit_data_from_rob,
    input wire[`PcLength:`Zero] commit_pc_from_rob,
    output wire[`OpcodeLength:`Zero] op_to_alu,
    output wire[`DataLength:`Zero] v1_to_alu,
    output wire[`DataLength:`Zero] v2_to_alu,
    output wire[`DataLength:`Zero] imm_to_alu,
    output wire[`DataLength:`Zero] pc_to_alu,
    output wire is_ready_to_iq,
    output wire is_empty_to_alu
);
reg [`DataLength:`Zero] Value1[RsLength:`Zero];
reg [`DataLength:`Zero] Value2[RsLength:`Zero];
reg [`PcLength:`Zero] Queue1[RsLength:`Zero];
reg [`PcLength:`Zero] Queue2[RsLength:`Zero];
reg [`OpcodeLength:`Zero] Op[RsLength:`Zero];
reg is_busy[RsLength:`Zero];
reg is_complete[RsLength:`Zero];
reg [`DataLength:`Zero] Imm[RsLength:`Zero];
reg [`PcLength:`Zero] Pc[RsLength:`Zero];
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`DataLength:`Zero] imm;
reg [`PcLength:`Zero] pc;
reg [`OpcodeLength:`Zero] op;
reg is_empty;
//integer test;
reg [PointerLength:`Zero] Free;
reg [PointerLength:`Zero] Comp;
reg [PointerLength:`Zero] Issue;
reg [PointerLength:`Zero] Storage;
reg is_ready;
reg is_issue;

reg en_empty;
reg en_sl;
reg en_exception;
reg en_commit;
reg en_rst;

integer i;

always @(posedge clk) begin
    en_rst = rst;
    en_sl = is_sl_from_dc;
    en_exception = is_exception_from_rob;
    en_commit = is_commit_from_rob;
    en_empty = is_empty_from_dc;
    if(en_rst == `True) begin
        is_ready <= `True;
        is_empty <= `True;
        is_issue <= `False;
        v1 <= 0;
        v2 <= 0;
        imm <= 0;
        op <= 0;
        pc <= 0;
        Storage <= 0;
        for(i = 0 ;i <= RsLength; i= i+1) begin
            Value1[i] <= 0;
            Value2[i] <= 0;
            Queue1[i] <= 0;
            Queue2[i] <= 0;
            is_complete[i] <= 0;
            is_busy[i] <= 0;
            Pc[i] <= 0;
            Imm[i] <= 0; 
        end
    end
    else begin
        if(en_exception == `True) begin
            is_issue <= `False;
            is_ready <= `True;
            is_empty <= `True;
            Storage <= 0;
            v1 <= 0;
            v2 <= 0;
            imm <= 0;
            pc <= 0;
            for(i = 0 ; i <= RsLength ; i = i + 1) begin
                is_busy[i] <= 0;
            end
        end
        else begin
            if(is_busy[0] == `True && is_complete[0] == `True && Queue1[0] == 0 && Queue2[0] == 0) begin
                Issue <= 0;
                is_issue  <= `True;
            end
            else if(is_busy[1] == `True && is_complete[1] == `True && Queue1[1] == 0 && Queue2[1] == 0) begin
                Issue <= 1;
                is_issue  <= `True;
            end
            else if(is_busy[2] == `True && is_complete[2] == `True && Queue1[2] == 0 && Queue2[2] == 0) begin
                Issue <= 2;
                is_issue  <= `True;
            end
            else if(is_busy[3] == `True && is_complete[3] == `True && Queue1[3] == 0 && Queue2[3] == 0) begin
                Issue <= 3;
                is_issue  <= `True;
            end
            else if(is_busy[4] == `True && is_complete[4] == `True && Queue1[4] == 0 && Queue2[4] == 0) begin
                Issue <= 4;
                is_issue  <= `True;
            end
            else if(is_busy[5] == `True && is_complete[5] == `True && Queue1[5] == 0 && Queue2[5] == 0) begin
                Issue <= 5;
                is_issue  <= `True;
            end
            else if(is_busy[6] == `True && is_complete[6] == `True && Queue1[6] == 0 && Queue2[6] == 0) begin
                Issue <= 6;
                is_issue  <= `True;
            end
            else if(is_busy[7] == `True && is_complete[7] == `True && Queue1[7] == 0 && Queue2[7] == 0) begin
                Issue <= 7;
                is_issue  <= `True;
            end
            else is_issue  <= `False;
        if(is_issue == `True) begin
            v1 <= Value1[Issue];
            v2 <= Value2[Issue];
            imm <= Imm[Issue];
            pc <= Pc[Issue];
            op <= Op[Issue];
            is_busy[Issue] <= `False;
            is_empty <= `False;
        end
        if(is_empty <= `False) is_empty <= `True;

        if(is_busy[0] == `False)begin
            is_ready <= `True;
            Free <= 0;
        end
        else if(is_busy[1] == `False)begin
            is_ready <= `True;
            Free <= 1;
        end
        else if(is_busy[2] == `False)begin
            is_ready <= `True;
            Free <= 2;
        end
        else if(is_busy[3] == `False)begin
            is_ready <= `True;
            Free <= 3;
        end
        else if(is_busy[4] == `False)begin
            is_ready <= `True;
            Free <= 4;
        end
        else if(is_busy[5] == `False)begin
            is_ready <= `True;
            Free <= 5;
        end
        else if(is_busy[6] == `False)begin
            is_ready <= `False;
            Free <= 6;
        end
        else if(is_busy[7] == `False)begin
            is_ready <= `False;
            Free <= 7;
        end

        if(en_empty == `False && en_sl == `False) begin      
                Pc[Free] <= pc_from_dc;
                Imm[Free] <= imm_from_dc;
                Op[Free] <= op_from_dc;
                is_busy[Free] <= `True;
                Comp <= Free;
                is_complete[Free] <= `False;
            end
        end
        if(is_busy[Comp] == `True && Pc[Comp] == pc_from_rf && is_complete[Comp] == `False) begin
            if(q1_from_rf == commit_pc_from_rob && q1_from_rf != 0)begin
                Queue1[Comp] <= 0;
                Value1[Comp] <= commit_data_from_rob;
            end 
            else begin
                Queue1[Comp] <= q1_from_rf;
                Value1[Comp] <= v1_from_rf;
            end
            if(q2_from_rf == commit_pc_from_rob && q2_from_rf != 0 )begin
                Queue2[Comp] <= 0;
                Value2[Comp] <= commit_data_from_rob;
            end 
            else begin
                Queue2[Comp] <= q2_from_rf;
                Value2[Comp] <= v2_from_rf;
            end
            is_complete[Comp] <= `True;
        end
        if(en_commit == `True) begin
            for(i = 0 ; i <= RsLength ; i = i+1) begin
                if(is_busy[i] == `True) begin
                    if(Queue1[i] != 0 && Queue1[i] == commit_pc_from_rob)begin
                        Queue1[i] <= 0;
                        Value1[i] <= commit_data_from_rob;
                    end
                    if(Queue2[i] != 0 && Queue2[i] == commit_pc_from_rob) begin
                        Queue2[i] <= 0;
                        Value2[i] <= commit_data_from_rob;
                    end
                end
            end
        end
    end
end
assign v1_to_alu = v1;
assign v2_to_alu = v2;
assign imm_to_alu = imm;
assign pc_to_alu = pc;
assign is_ready_to_iq = is_ready;
assign op_to_alu = op;
assign is_empty_to_alu = is_empty;
endmodule