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
    input wire is_empty_from_dc,
    input wire is_finish_from_alu,
    input wire is_commit_from_fc,
    input wire is_instr_from_fc,
    input wire is_exception_from_rob,

    input wire[`DataLength:`Zero] data_from_alu,
    input wire[`DataLength:`Zero] pc_from_alu,
    input wire[`DataLength:`Zero] jpc_from_alu,
    input wire[`DataLength:`Zero] data_from_fc,
    input wire[`DataLength:`Zero] pc_from_fc,
    input wire[RdLength:`Zero] rd_from_dc,
    input wire[`PcLength:`Zero] pc_from_dc,
    input wire[`OpcodeLength:`Zero] op_from_dc,

    output wire is_ready_to_iq,
    output wire is_exception_to_instr_queue,
    output wire is_exception_to_reg,
    output wire is_exception_to_rs,
    output wire is_exception_to_fc,
    output wire is_exception_to_rob,
    output wire is_exception_to_ic,

    output wire[`PcLength:`Zero] pc_to_instr_queue,
    output wire[RdLength:`Zero] commit_rd_to_reg,
    output wire[`PcLength:`Zero] commit_pc_to_rs,
    output wire[`PcLength:`Zero] commit_pc_to_fc,
    output wire[`PcLength:`Zero] commit_pc_to_reg,
    output wire[`DataLength:`Zero] commit_data_to_rs,
    output wire[`DataLength:`Zero] commit_data_to_fc,
    output wire[`DataLength:`Zero] commit_data_to_reg,

    output wire is_commit_to_fc,
    output wire is_commit_to_rs,
    output wire is_commit_to_reg
);
reg [`DataLength:`Zero] data_storage[BufferLength:`Zero];
reg [`PcLength:`Zero] jpc_storage[BufferLength:`Zero];
reg [`PcLength:`Zero] pc_storage[BufferLength:`Zero];
reg [RdLength:`Zero] rd_storage[BufferLength:`Zero];
reg [`OpcodeLength:`Zero] op_storage[BufferLength:`Zero];


//reg [`OpcodeLength:`Zero] op_storage[BufferLength:`Zero];
//reg status_storage[BufferLength:`Zero];
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
//提交池

reg [`DataLength:`Zero] commit_data;
reg [`PcLength:`Zero] commit_jpc;
reg [`PcLength:`Zero] commit_pc;
reg [RdLength:`Zero] commit_rd;
reg finish[BufferLength:`Zero];
reg [`PcLength:`Zero] pc;


reg en_finish_alu;
reg en_commit_fc;
reg en_exception;
reg en_instr;

reg is_exception;
reg [63:0] cnt;
reg is_finish;
reg is_ready;
reg en_empty;
reg en_rst;

reg [`DataLength:`Zero] test2;
reg [`DataLength:`Zero] test3;
integer test;
reg [63:0] clk_num;
integer i;
integer fp_w;
initial begin
    fp_w = $fopen("./out.txt","w");
    clk_num = 0;
end
always @(posedge clk) begin
    clk_num = clk_num + 1;
    en_rst = rst;
    en_instr = is_instr_from_fc;
    en_finish_alu = is_finish_from_alu;
    en_commit_fc = is_commit_from_fc;
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
        for(i = 0 ; i <= BufferLength ; ++i) begin
            rd_storage[i] <= 0;
            pc_storage[i] <= 0;
            data_storage[i] <= 0;
            finish[i] <= 0;
        end
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
                    if(pc_storage[i] == pc_from_alu) begin
                        test <= i;
                        finish[i] <= `True;
                        data_storage[i] <= data_from_alu;
                        jpc_storage[i] <= jpc_from_alu;
                    end
                end
            end

            if(en_commit_fc == `True && en_instr == `False) begin
                for(i = 0 ; i <= BufferLength ; i = i + 1)begin
                    if(pc_storage[i] == pc_from_fc) begin
                        finish[i] <= `True;
                        test2 <= op_storage[i];
                        test3 <= data_from_fc;
                        case(op_storage[i])
                        `LH:data_storage[i] <= {{16{data_from_fc[15]}},data_from_fc[15:0]};
                        `LB:data_storage[i] <= {{24{data_from_fc[7]}},data_from_fc[7:0]};
                        `LW,`LBU,`LHU : data_storage[i] <= data_from_fc;
                        default: data_storage[i] <= 0;
                        endcase
                    end
                end
            end

            if(finish[head_pointer] == `True && head_pointer != tail_pointer) begin
            //  $display("%d %d",pc_storage[head_pointer],data_storage[head_pointer]);
                $fwrite(fp_w,"%d %d %d\n",pc_storage[head_pointer],rd_storage[head_pointer],data_storage[head_pointer]);
                cnt <= cnt + 1;
                if((cnt + 1)%10000 == 0) begin
                    $display(cnt);
                end
                if(cnt >= 750) $finish;
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
                op_storage[tail_pointer] <= op_from_dc;
                finish[tail_pointer] <= `False;
                tail_pointer <= tail_pointer + 4'b0001;
            end
        end
    end
end

assign is_commit_to_reg = is_finish;
assign is_commit_to_fc = is_finish;
assign is_commit_to_rs = is_finish;
assign is_ready_to_iq = is_ready;
assign is_exception_to_instr_queue = is_exception;
assign is_exception_to_reg = is_exception;
assign is_exception_to_rs = is_exception;
assign is_exception_to_fc = is_exception;
assign is_exception_to_rob = is_exception;
assign is_exception_to_ic = is_exception;
assign pc_to_instr_queue = commit_jpc;
assign commit_rd_to_reg = commit_rd;
assign commit_pc_to_rs =commit_pc;
assign commit_pc_to_fc =commit_pc;
assign commit_pc_to_reg=commit_pc;
assign commit_data_to_rs = commit_data;
assign commit_data_to_fc= commit_data;
assign commit_data_to_reg= commit_data;
endmodule