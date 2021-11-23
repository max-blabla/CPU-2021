`include "parameters.v"
module rob #
(
    parameter BufferLength = 16,
    parameter PointerLength = 3,
    parameter RdLength = 4
)
(
    input wire clk,
    input wire rst,
    input wire is_empty_from_reg,
    input wire is_finish_from_alu,
    input wire is_finish_from_slb,
    input wire is_stall_from_slb,
    input wire is_stall_from_rs,
    input wire is_exception_from_rob,
    input wire[`PcLength:`Zero] pc_from_reg,
    input wire[`DataLength:`Zero] data_from_alu,
    input wire[`DataLength:`Zero] pc_from_alu,
    input wire[`DataLength:`Zero] jpc_from_alu,
    input wire[`DataLength:`Zero] data_from_slb,
    input wire[`DataLength:`Zero] pc_from_slb,
    input wire[`OpcodeLength:`Zero] op_from_reg,
    input wire[`DataLength:`Zero] v1_from_reg,
    input wire[`DataLength:`Zero] v2_from_reg,
    input wire[`DataLength:`Zero] q1_from_reg,
    input wire[`DataLength:`Zero] q2_from_reg,
    input wire[`DataLength:`Zero] imm_from_reg,
    input wire[RdLength:`Zero] rd_from_reg,
    output wire is_finish_to_reg,
    output wire is_stall_to_instr_queue,
    output wire is_exception_to_instr_queue,
    output wire is_exception_to_reg,
    output wire is_exception_to_rs,
    output wire is_exception_to_slb,
    output wire is_exception_to_fc,
    output wire is_empty_to_rs,
    output wire is_empty_to_slb,
    output wire is_sl_to_rs,
    output wire is_sl_to_slb,
    output wire[`PcLength:`Zero] pc_to_instr_queue,
    output wire[`DataLength:`Zero] pc_to_rs,
    output wire[`DataLength:`Zero] pc_to_slb,
    output wire[RdLength:`Zero] commit_rd_to_reg,
    output wire[`PcLength:`Zero] commit_pc_to_rs,
    output wire[`PcLength:`Zero] commit_pc_to_slb,
    output wire[`PcLength:`Zero] commit_pc_to_reg,
    output wire[`DataLength:`Zero] v1_to_rs,
    output wire[`DataLength:`Zero] v2_to_rs,
    output wire[`PcLength:`Zero] q1_to_rs,
    output wire[`PcLength:`Zero] q2_to_rs,
    output wire[`DataLength:`Zero] imm_to_rs,
    output wire[`OpcodeLength:`Zero] op_to_rs,
    output wire[`DataLength:`Zero] v1_to_slb,
    output wire[`DataLength:`Zero] v2_to_slb,
    output wire[`PcLength:`Zero] q1_to_slb,
    output wire[`PcLength:`Zero] q2_to_slb,
    output wire[`DataLength:`Zero] imm_to_slb,
    output wire[`OpcodeLength:`Zero] op_to_slb,
    output wire[`DataLength:`Zero] commit_data_to_rs,
    output wire[`DataLength:`Zero] commit_data_to_slb,
    output wire[`DataLength:`Zero] commit_data_to_reg
);
reg [`DataLength:`Zero] data_storage[BufferLength:`Zero];
reg [`PcLength:`Zero] pc_storage[BufferLength:`Zero];
reg [RdLength:`Zero] rd_storage[BufferLength:`Zero];
reg finish[BufferLength:`Zero];
//reg [`OpcodeLength:`Zero] op_storage[BufferLength:`Zero];
//reg status_storage[BufferLength:`Zero];
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
//提交池
reg [`DataLength:`Zero] commit_data;
reg [`PcLength:`Zero] commit_pc;
reg [`PcLength:`Zero] commit_jpc;
reg [RdLength:`Zero] commit_rd;
reg [`OpcodeLength:`Zero] op;
reg [`DataLength:`Zero] imm;
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`PcLength:`Zero] pc;
reg [`PcLength:`Zero] q1;
reg [`PcLength:`Zero] q2;
reg is_exception;
reg is_finish;
reg is_empty;//这是指向两个运算模块的
reg is_stall;
reg is_sl;

integer i;
always @(posedge rst) begin
    is_exception <=0;
    is_empty <= 0;
    is_sl <= 0;
    is_stall <= 0;
    is_finish <= 0;
    v1 <= 0 ;
    v2 <= 0;
    q1 <= 0;
    q2 <= 0;
    op  <= 0;
    pc <= 0;
    imm <= 0;
    commit_data <= 0;
    commit_pc <= 0;
    commit_rd <= 0;
    commit_jpc <= 0;
    tail_pointer <= 0;
    head_pointer <= 0;
    for(i = 0 ; i < BufferLength ; ++i) begin
        rd_storage[i] <= 0;
        pc_storage[i] <= 0;
        data_storage[i] <= 0;
        finish[i] <= 0;
    end
end
always @(posedge clk) begin
    //先接受来自ALU和SLB的结果更新
    if(is_exception_from_rob == `False) begin
        if(is_finish_from_alu == `True) begin
            for(i = 0 ; i <= BufferLength ; i = i + 1)begin
                if(pc_storage[i] == pc_from_alu) begin
                    finish[i] <= `True;
                    data_storage[i] <= data_from_alu;
                end
            end
        end
        if(is_finish_from_slb == `True) begin
            for(i = 0 ; i <= BufferLength ; i = i + 1)begin
                if(pc_storage[i] == pc_from_alu) begin
                    finish[i] <= `True;
                    data_storage[i] <= data_from_slb;
                end
            end
        end
        //然后提交到提交池，更新empty
        if(finish[head_pointer] == `True) begin
            is_finish <= finish[head_pointer];
            commit_data <= data_storage[head_pointer];
            commit_pc <= pc_storage[head_pointer];
            commit_rd <= rd_storage[head_pointer];
            head_pointer <= head_pointer + 4'b0001;
            //更新跳转
            if(jpc_from_alu != pc_from_alu + 4) begin
                is_exception <= `True;
                commit_jpc <= jpc_from_alu;
            end
            else begin
                is_exception <= `False;
                commit_jpc <= jpc_from_alu;
            end
        end
        else begin
            is_finish <= finish[head_pointer];
        end
        if(is_empty_from_reg == `False) begin
            //然后接受来自reg的插入申请
            //然后放到发送池，如果stall了就不更新发送池
            //然后看情况发给rs或slb
            if(head_pointer != tail_pointer + 4'b0001)begin
                is_empty <= `False;
                is_stall <= `False;
                imm <= imm_from_reg;
                q1 <= q1_from_reg;
                q2 <= q2_from_reg;
                v1 <= v1_from_reg;
                v2 <= v2_from_reg;
                op <= op_from_reg;
                pc <= pc_from_reg;
                rd_storage[tail_pointer] <= rd_from_reg;
                pc_storage[tail_pointer] <= pc_from_reg;
                case(op_from_reg) 
                `SB,`SW,`SH,`LH,`LW,`LB,`LBU,`LHU:begin
                    is_sl <= `True;
                end
                default:begin
                    is_sl <= `False;
                end
                endcase
                tail_pointer <= tail_pointer + 4'b0001;
            end
            else begin
                is_empty <= `True;
                is_stall <= `True;
            end
        end
        else begin
            is_empty <= `True;
            is_stall <= `False;
        end
    end
    else begin
        is_exception <=0;
        is_empty <= 0;
        is_sl <= 0;
        is_stall <= 0;
        is_finish <= 0;
        v1 <= 0 ;
        v2 <= 0;
        q1 <= 0;
        q2 <= 0;
        op  <= 0;
        pc <= 0;
        imm <= 0;
        commit_data <= 0;
        commit_pc <= 0;
        commit_rd <= 0;
        commit_jpc <= 0;
        tail_pointer <= 0;
        head_pointer <= 0;
        for(i = 0 ; i < BufferLength ; ++i) begin
            rd_storage[i] <= 0;
            pc_storage[i] <= 0;
            data_storage[i] <= 0;
            finish[i] <= 0;
        end
    end
end
assign is_finish_to_reg = is_finish;
assign is_stall_to_instr_queue = is_stall;
assign is_exception_to_instr_queue = is_exception;
assign is_exception_to_reg = is_exception;
assign is_exception_to_rs = is_exception;
assign is_exception_to_slb = is_exception;
assign is_empty_to_rs = is_empty;
assign is_empty_to_slb = is_empty;
assign is_sl_to_rs = is_sl;
assign is_sl_to_slb = is_sl;
assign pc_to_instr_queue = commit_jpc;
assign pc_to_rs = pc;
assign pc_to_slb = pc;
assign commit_rd_to_reg = commit_rd;
assign commit_pc_to_rs =commit_pc;
assign commit_pc_to_slb=commit_pc;
assign commit_pc_to_reg=commit_pc;
assign v1_to_rs = v1;
assign v2_to_rs = v2;
assign q1_to_rs = q1;
assign q2_to_rs = q2;
assign imm_to_rs= imm;
assign op_to_rs = op;
assign v1_to_slb= v1;
assign v2_to_slb= v2;
assign q1_to_slb= q1;
assign q2_to_slb= q2;
assign imm_to_slb= imm;
assign op_to_slb= op;
assign commit_data_to_rs = commit_data;
assign commit_data_to_slb= commit_data;
assign commit_data_to_reg= commit_data;
endmodule