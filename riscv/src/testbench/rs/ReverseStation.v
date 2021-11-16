`include "parameters.v"
module rs
#(
    parameter RsLength = 7
)
(
    input wire rst,
    input wire clk,
    input wire is_empty_from_rob,
    input wire is_sl_from_rob,
    input wire is_exception_from_rob,
    input wire is_commit_from_rob,
    input wire[`OpcodeLength:`Zero] op_from_rob,
    input wire[`DataLength:`Zero] v1_from_rob,
    input wire[`DataLength:`Zero] v2_from_rob,
    input wire[`PcLength:`Zero] q1_from_rob,
    input wire[`PcLength:`Zero] q2_from_rob,
    input wire[`DataLength:`Zero] imm_from_rob,
    input wire[`DataLength:`Zero] pc_from_rob,
    input wire[`DataLength:`Zero] commit_data_from_rob,
    input wire[`PcLength:`Zero] commit_pc_from_rob,
    output wire[`OpcodeLength:`Zero] op_to_alu,
    output wire[`DataLength:`Zero] v1_to_alu,
    output wire[`DataLength:`Zero] v2_to_alu,
    output wire[`DataLength:`Zero] imm_to_alu,
    output wire[`DataLength:`Zero] pc_to_alu,
    output wire is_stall_to_instr_queue,
    output wire is_stall_to_rob
);
reg [`DataLength:`Zero] Value1[RsLength:`Zero];
reg [`DataLength:`Zero] Value2[RsLength:`Zero];
reg [`PcLength:`Zero] Queue1[RsLength:`Zero];
reg [`PcLength:`Zero] Queue2[RsLength:`Zero];
reg [`OpcodeLength:`Zero] Op[RsLength:`Zero];
reg is_busy[RsLength:`Zero];
reg is_stall;
reg [`DataLength:`Zero] Imm[RsLength:`Zero];
reg [`PcLength:`Zero] Pc[RsLength:`Zero];
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`DataLength:`Zero] imm;
reg [`PcLength:`Zero] pc;
reg [`OpcodeLength:`Zero] op;
integer i;
always @(posedge rst) begin
    is_stall <= 0;
    v1 <= 0;
    v2 <= 0;
    imm <= 0;
    op <= 0;
    for(i = 0 ;i <= RsLength; ++i) begin
        Value1[i] <= 0;
        Value2[i] <= 0;
        Queue1[i] <= 0;
        Queue2[i] <= 0;
        is_busy[i] <= 0;
        Pc[i] <= 0;
        Imm[i] <= 0; 
    end
end
always @(posedge clk) begin
    //判断是否清空
    if(is_exception_from_rob) begin
        is_stall <= 0;
        v1 <= 0;
        v2 <= 0;
        imm <= 0;
        for(i = 0 ; i <= RsLength ; ++i) begin
            Value1[i] <= 0;
            Value2[i] <= 0;
            Queue1[i] <= 0;
            Queue2[i] <= 0;
            is_busy[i] <= 0;
            Pc[i] <= 0;
            Imm[i] <= 0; 
            Op[i] <= 0;
        end
    end
    else begin
        if(is_empty_from_rob == `False && is_sl_from_rob == `False) begin
            //先用rob的提交更新
            if(is_commit_from_rob) begin
                for(i = 0 ; i <= RsLength ; ++i) begin
                    if(is_busy[i] == `True && Queue1[i] == 0 && Queue2[i] == 0) begin
                        if(Queue1[i] == commit_pc_from_rob)begin
                            Queue1[i] = 0;
                            Value1[i] = commit_data_from_rob;
                        end
                        if(Queue2[i] == commit_pc_from_rob) begin
                            Queue2[i] = 0;
                            Value2[i] = commit_data_from_rob;
                        end
                    end
                end
            end
            //再找一遍可以发射的
            begin : loop
                for(i = 0 ; i <= RsLength ; ++i) begin
                    if(is_busy[i] == `True && Queue1[i] == 0 && Queue2[i] == 0) begin
                        v1 = Value1[i];
                        v2 = Value2[i];
                        imm = Imm[i];
                        pc = Pc[i];
                        op = Op[i];
                        is_busy[i] = `False;
                        disable loop;
                    end
                end
            end
            //再输入新的来自rob的值
            begin : loop2 
                is_stall = `True;
                for(i = 0 ; i <= RsLength ; ++i) begin
                    if(is_busy[i] == `False) begin
                        Pc[i] = pc_from_rob;
                        Imm[i] = imm_from_rob;
                        Value1[i] = v1_from_rob;
                        Value2[i] = v2_from_rob;
                        Queue1[i] = q1_from_rob;
                        Queue2[i] = q2_from_rob;
                        Op[i] = op_from_rob;
                        is_busy[i] = `True;
                        is_stall = `False;
                        disable loop2;
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
assign is_stall_to_instr_queue = is_stall;
assign is_stall_to_rob = is_stall;
assign op_to_alu = op;
endmodule