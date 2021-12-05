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
    input wire[RdLength:`Zero] rd_from_reg,
    input wire is_ready_from_rf,
    output wire is_ready_to_rf,
    output wire is_exception_to_instr_queue,
    output wire is_exception_to_reg,
    output wire is_exception_to_rs,
    output wire is_exception_to_slb,
    output wire is_exception_to_fc,
    output wire is_exception_to_rob,
    output wire[`PcLength:`Zero] pc_to_instr_queue,
    output wire[RdLength:`Zero] commit_rd_to_reg,
    output wire[`PcLength:`Zero] commit_pc_to_rs,
    output wire[`PcLength:`Zero] commit_pc_to_slb,
    output wire[`PcLength:`Zero] commit_pc_to_reg,
    output wire[`DataLength:`Zero] commit_data_to_rs,
    output wire[`DataLength:`Zero] commit_data_to_slb,
    output wire[`DataLength:`Zero] commit_data_to_reg,
    output wire is_commit_to_slb,
    output wire is_commit_to_rs,
    output wire is_commit_to_reg
);
reg [`DataLength:`Zero] data_storage[BufferLength:`Zero];
reg [`PcLength:`Zero] jpc_storage[BufferLength:`Zero];
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
reg [`PcLength:`Zero] pc;
reg is_exception;
reg is_finish;
reg is_ready;
integer test;
integer i;
always @(posedge rst) begin
    is_exception <=0;
    is_ready <= 0;
    is_finish <= 0;
    pc <= 0;
    commit_data <= 0;
    commit_pc <= 0;
    commit_rd <= 0;
    commit_jpc <= 0;
    tail_pointer <= 0;
    head_pointer <= 0;
    for(i = 0 ; i <= BufferLength ; ++i) begin
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
                    test <= i;
                    finish[i] <= `True;
                    data_storage[i] <= data_from_alu;
                    jpc_storage[i] <= jpc_from_alu;
                end
            end
        end
        if(is_finish_from_slb == `True) begin
            for(i = 0 ; i <= BufferLength ; i = i + 1)begin
                if(pc_storage[i] == pc_from_slb) begin
                    finish[i] <= `True;
                    data_storage[i] <= data_from_slb;
                end
            end
        end
        //然后提交到提交池，更新empty
        if(finish[head_pointer] == `True && head_pointer != tail_pointer) begin
            $display("%d %d",pc_storage[head_pointer],data_storage[head_pointer]);
      //      $display(jpc_storage[head_pointer]);
            is_finish <= `True;
            commit_data <= data_storage[head_pointer];
            commit_pc <= pc_storage[head_pointer];
            commit_rd <= rd_storage[head_pointer];
            head_pointer <= head_pointer + 4'b0001;
            //更新跳转
            if(jpc_storage[head_pointer] != pc_storage[head_pointer] + 4) begin
                is_exception <= `True;
                commit_jpc <= jpc_storage[head_pointer];
            end
            else begin
                is_exception <= `False;
                commit_jpc <= jpc_storage[head_pointer];
            end
        end
        else begin
            is_finish <= `False;
        end
        if(head_pointer != tail_pointer + 4'b0001) is_ready <= `True;
        else is_ready <= `False;
        if(is_ready_from_rf == `True && is_ready == `True) begin
            rd_storage[tail_pointer] <= rd_from_reg;
            pc_storage[tail_pointer] <= pc_from_reg;
            jpc_storage[tail_pointer] <= pc_from_reg+4;
            finish[tail_pointer] <= `False;
            tail_pointer <= tail_pointer + 4'b0001;
        end
    end
    else begin
        is_exception <=0;
        is_ready <= 0;
        is_finish <= 0;
        pc <= 0;
        commit_data <= 0;
        commit_pc <= 0;
        commit_rd <= 0;
        commit_jpc <= 0;
        tail_pointer <= 0;
        head_pointer <= 0;
        //for(i = 0 ; i < BufferLength ; ++i) begin
        //    rd_storage[i] <= 0;
        //    pc_storage[i] <= 0;
        //    data_storage[i] <= 0;
        //    finish[i] <= 0;
        //end
    end
end
assign is_commit_to_reg = is_finish;
assign is_commit_to_slb = is_finish;
assign is_commit_to_rs = is_finish;
assign is_ready_to_rf = is_ready;
assign is_exception_to_instr_queue = is_exception;
assign is_exception_to_reg = is_exception;
assign is_exception_to_rs = is_exception;
assign is_exception_to_slb = is_exception;
assign is_exception_to_fc = is_exception;
assign is_exception_to_rob = is_exception;
assign pc_to_instr_queue = commit_jpc;
assign commit_rd_to_reg = commit_rd;
assign commit_pc_to_rs =commit_pc;
assign commit_pc_to_slb=commit_pc;
assign commit_pc_to_reg=commit_pc;
assign commit_data_to_rs = commit_data;
assign commit_data_to_slb= commit_data;
assign commit_data_to_reg= commit_data;
endmodule