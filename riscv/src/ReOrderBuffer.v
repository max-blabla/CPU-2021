`include "parameters.v"
module rob #
(
    parameter BufferLength = 7,
    parameter PointerLength = 2,
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
    input wire[`PcLength:`Zero] pc_from_reg,
    input wire[`DataLength:`Zero] data_from_alu,
    input wire[`DataLength:`Zero] pc_from_alu,
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
    output wire is_stall_to_reg,
    output wire is_exception_to_instr_queue,
    output wire is_exception_to_reg,
    output wire is_exception_to_rs,
    output wire is_exception_to_slb,
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
reg [`OpcodeLength:`Zero] op_storage[BufferLength:`Zero];
reg status_storage[BufferLength:`Zero];
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
//提交池
reg [`DataLength:`Zero] commit_data;
reg [`PcLength:`Zero] commit_pc;
reg [RdLength:`Zero] commit_rd;
reg [`OpcodeLength:`Zero] op;
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`PcLength:`Zero] q1;
reg [`PcLength:`Zero] q2;
reg is_exception;
reg is_empty;//这是指向两个运算模块的
reg is_stall;
reg is_sl;

integer i;
always @(posedge rst) begin
    is_exception <=0;
    is_empty <= 0;
    is_sl <= 0;
    is_stall <= 0;
    v1 <= 0 ;
    v2 <= 0;
    q1 <= 0;
    q2 <= 0;
    commit_data <= 0;
    commit_pc <= 0;
    commit_rd <= 0;
    tail_pointer <= 0;
    head_pointer <= 0;
    op<= 0;
    for(i = 0 ; i < BufferLength ; ++i) begin
        status_storage[i] <= 0;
        rd_storage[i] <= 0;
        pc_storage[i] <= 0;
        data_storage[i] <= 0;
        op_storage[i] <= 0;
    end
end

always @(posedge clk) begin
    //先接受来自ALU和SLB的结果更新
    //然后提交到提交池，更新empty
    //然后接受来自reg的插入申请
    //然后放到发送池，如果stall了就不更新发送池
    //若插入后满，更新stall
    //然后看情况发给rs或slb
end
endmodule