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
    input wire rdy,
    input wire is_empty_from_dc,
    input wire is_finish_from_alu,
    input wire is_commit_from_slb,
    input wire is_exception_from_rob,

    input wire[`DataLength:`Zero] data_from_alu,
    input wire[`DataLength:`Zero] pc_from_alu,
    input wire[`DataLength:`Zero] jpc_from_alu,
    input wire[`DataLength:`Zero] data_from_slb,
    input wire[`DataLength:`Zero] pc_from_slb,
    input wire[RdLength:`Zero] rd_from_dc,
    input wire[`PcLength:`Zero] pc_from_dc,

    output wire is_ready_to_iq,
    output wire is_exception_to_instr_queue,
    output wire is_exception_to_reg,
    output wire is_exception_to_rs,
    output wire is_exception_to_slb,
    output wire is_exception_to_fc,
    output wire is_exception_to_rob,
    output wire is_exception_to_ic,

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


//reg [`OpcodeLength:`Zero] op_storage[BufferLength:`Zero];
//reg status_storage[BufferLength:`Zero];
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
//提交�?

reg [`DataLength:`Zero] commit_data;
reg [`PcLength:`Zero] commit_jpc;
reg [`PcLength:`Zero] commit_pc;
reg [RdLength:`Zero] commit_rd;
reg finish[BufferLength:`Zero];
reg [`PcLength:`Zero] pc;
reg [63:0] cnt;

reg en_finish_alu;
reg en_commit_slb;
reg en_exception;

reg is_exception;
reg is_finish;
reg is_ready;
reg en_empty;
reg en_rst;
reg en_rdy;

integer i;

always @(posedge clk) begin
    en_rst = rst;
    en_rdy =rdy;
    en_finish_alu = is_finish_from_alu;
    en_commit_slb = is_commit_from_slb;
    en_exception = is_exception_from_rob;
    en_empty = is_empty_from_dc;
    if(en_rst == `True) begin
        cnt <= 0;
        is_exception <=0;
        is_ready <= `True;
        is_finish <= 0;
        pc <= 0;
        commit_data <= 0;
        commit_pc <= 0;
        commit_rd <= 0;
        commit_jpc <= 0;
        tail_pointer <= 0;
        head_pointer <= 0;
        for(i = 0 ; i <= BufferLength ; i = i+1) begin
            rd_storage[i] <= 0;
            pc_storage[i] <= 0;
            data_storage[i] <= 0;
            finish[i] <= 0;
        end
    end
    else if(en_rdy == `False) begin
        
    end
    else begin
        if(en_exception == `True) begin
             is_exception <=0;
            is_ready <= `True;
            is_finish <= 0;
            pc <= 0;
            commit_data <= 0;
            commit_pc <= 0;
            commit_rd <= 0;
            commit_jpc <= 0;
            tail_pointer <= 0;
            head_pointer <= 0;
        end
        else begin
           if(en_finish_alu == `True) begin
                for(i = 0 ; i <= BufferLength ; i = i + 1)begin
                    if(pc_storage[i] == pc_from_alu && finish[i] == `False) begin
                        finish[i] <= `True;
                        data_storage[i] <= data_from_alu;
                        jpc_storage[i] <= jpc_from_alu;
                    end
                end
            end

            if(en_commit_slb == `True) begin
                for(i = 0 ; i <= BufferLength ; i = i + 1)begin
                    if(pc_storage[i] == pc_from_slb && finish[i] == `False) begin
                        finish[i] <= `True;
                        data_storage[i] <= data_from_slb;
                    end
                end
            end

            if(finish[head_pointer] == `True && head_pointer != tail_pointer) begin
            //  $display("%d %d",pc_storage[head_pointer],data_storage[head_pointer]);
        //      $display(jpc_storage[head_pointer]);
                is_finish <= `True;
                commit_data <= data_storage[head_pointer];
                commit_pc <= pc_storage[head_pointer];
                commit_rd <= rd_storage[head_pointer];
                head_pointer <= head_pointer + 4'b0001;

                if(jpc_storage[head_pointer] != pc_storage[head_pointer] + 4) begin
                    is_exception <= `True;
                end
                else begin
                    is_exception <= `False;
                end
                commit_jpc <= jpc_storage[head_pointer];
            end
            else begin
                is_finish <= `False;
                commit_pc <= 0;
            end
            
            if(head_pointer != tail_pointer + 4'b0011 && head_pointer != tail_pointer + 4'b0010 && head_pointer != tail_pointer + 4'b0001) is_ready <= `True;
            else is_ready <= `False;
            
            if(en_empty == `False) begin
                rd_storage[tail_pointer] <= rd_from_dc;
                pc_storage[tail_pointer] <= pc_from_dc;
                jpc_storage[tail_pointer] <= pc_from_dc+4;
                finish[tail_pointer] <= `False;
                tail_pointer <= tail_pointer + 4'b0001;
            end
        end
    end
end

assign is_commit_to_reg = is_finish;
assign is_commit_to_slb = is_finish;
assign is_commit_to_rs = is_finish;
assign is_ready_to_iq = is_ready;
assign is_exception_to_instr_queue = is_exception;
assign is_exception_to_reg = is_exception;
assign is_exception_to_rs = is_exception;
assign is_exception_to_slb = is_exception;
assign is_exception_to_fc = is_exception;
assign is_exception_to_rob = is_exception;
assign is_exception_to_ic = is_exception;
assign pc_to_instr_queue = commit_jpc;
assign commit_rd_to_reg = commit_rd;
assign commit_pc_to_rs =commit_pc;
assign commit_pc_to_slb =commit_pc;
assign commit_pc_to_reg=commit_pc;
assign commit_data_to_rs = commit_data;
assign commit_data_to_slb =  commit_data;
assign commit_data_to_reg= commit_data;
endmodule