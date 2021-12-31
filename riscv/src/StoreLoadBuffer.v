`include "parameters.v"
module slb #(
    parameter BufferLength = 15,
    parameter PointerLength = 3,
    parameter CntLength  = 1
)(
    input clk,
    input rst,
    input rdy,
    input is_exception_from_rob,
    input is_empty_from_dc,
    input is_sl_from_dc,
    input is_commit_from_rob,
    input [`PcLength:`Zero] commit_pc_from_rob,
    input [`DataLength:`Zero] commit_data_from_rob,

    
    input [`PcLength:`Zero] pc_from_dc,
    input [`DataLength:`Zero] imm_from_dc,
    input [`OpcodeLength:`Zero] op_from_dc,

    input [`PcLength:`Zero] q1_from_rf,
    input [`PcLength:`Zero] q2_from_rf,
    input [`DataLength:`Zero] v1_from_rf,
    input [`DataLength:`Zero] v2_from_rf,

    input [`DataLength:`Zero] data_from_fc,
    input is_finish_from_fc,
    input is_instr_from_fc,
    input is_store_from_fc,

    output [`DataLength:`Zero] data_to_rob,
    output [`DataLength:`Zero] data_to_fc,
    output is_store_to_fc,
    output is_empty_to_fc,
    output is_commit_to_rob,
    output [`PcLength:`Zero] addr_to_fc,
    output [CntLength:`Zero] aim_to_fc,
    output is_ready_to_iq,
    output [`PcLength:`Zero] commit_pc_to_rob
);
reg en_sl;
reg en_exception;
reg en_clk;
reg en_rst;
reg en_rdy;
reg en_empty;
reg en_instr;
reg en_finish;
reg en_store;
reg en_commit;

reg [PointerLength:`Zero]head_pointer;
reg [PointerLength:`Zero]tail_pointer;
reg [PointerLength:`Zero]comp_pointer;

reg is_ready;
reg is_empty;
reg is_commit;
reg is_store;
reg is_confirm;

integer i;


reg [`PcLength:`Zero]Pc[BufferLength:`Zero];
reg [`DataLength:`Zero]Q1[BufferLength:`Zero];
reg [`PcLength:`Zero]Q2[BufferLength:`Zero];
reg [`DataLength:`Zero]V1[BufferLength:`Zero];
reg [`DataLength:`Zero]V2[BufferLength:`Zero];
reg [`DataLength:`Zero]Imm[BufferLength:`Zero];
reg [`OpcodeLength:`Zero]Op[BufferLength:`Zero];
reg store_status[BufferLength:`Zero];
reg commit_status[BufferLength:`Zero];
reg comp_status[BufferLength:`Zero];

reg [`PcLength:`Zero]commit_pc;
reg [`PcLength:`Zero]addr;
reg [`DataLength:`Zero]commit_data;
reg [`DataLength:`Zero]data;
reg [CntLength:`Zero]aim;
always @(posedge clk) begin
    en_sl = is_sl_from_dc;
    en_exception = is_exception_from_rob;
    en_rst = rst;
    en_rdy = rdy;
    en_store = is_store_from_fc;
    en_instr = is_instr_from_fc;
    en_empty = is_empty_from_dc;
    en_finish = is_finish_from_fc;
    en_commit = is_commit_from_rob;
    if(en_rst == `True) begin
        head_pointer <= 0;
        tail_pointer <= 0;
        is_confirm <= `False;
        is_ready <= `True;
        is_empty <= `True;
    end
    else if (en_rdy == `False) begin
        
    end
    else begin
        //清空
        if(en_exception == `True) begin
            head_pointer <= 0;
            tail_pointer <= 0;
            is_ready <= `True;
            is_empty <= `True;
            is_confirm <= `False;
        end
        else begin
            //输入
            if(head_pointer != tail_pointer + 3'b001 && head_pointer != tail_pointer + 3'b010 && head_pointer != tail_pointer + 3'b011) is_ready <= `True;
            else is_ready <= `False;

            if(en_empty == `False && en_sl == `True) begin
                Pc[tail_pointer] <= pc_from_dc;
                Imm[tail_pointer] <= imm_from_dc;
                comp_status[tail_pointer] <= `False;
                comp_pointer <= tail_pointer;
                Op[tail_pointer] <= op_from_dc;
                case(op_from_dc)
                `SB,`SH,`SW:store_status[tail_pointer] <= `True;
                `LH,`LBU,`LHU,`LW,`LB : store_status[tail_pointer] <= `False;
                endcase
                tail_pointer <= tail_pointer + 1;
            end
            //完成
            if(comp_status[comp_pointer] == `False && head_pointer != tail_pointer) begin
                
                if(commit_pc_from_rob == q1_from_rf && q1_from_rf != 0) begin
                    Q1[comp_pointer] <= 0;
                    V1[comp_pointer] <= commit_data_from_rob;
                end
                else begin
                    Q1[comp_pointer] <= q1_from_rf;
                    V1[comp_pointer] <= v1_from_rf;
                end
                if(commit_pc_from_rob == q2_from_rf && q2_from_rf != 0) begin
                    Q2[comp_pointer] <= 0;
                    V2[comp_pointer] <= commit_data_from_rob;
                end
                else begin
                    Q2[comp_pointer] <= q2_from_rf;
                    V2[comp_pointer] <= v2_from_rf;
                end
                comp_status[comp_pointer] <= `True;
            end
            //提交与发�?
            if(is_empty == `False) is_empty <= `True;
            if(is_commit == `True) is_commit <= `False;
            if(store_status[head_pointer] == `True && head_pointer != tail_pointer)begin
                if(Q1[head_pointer] == 0 && Q2[head_pointer] == 0 && comp_status[head_pointer] == `True) begin
                    if(is_confirm == `False) begin
                        is_commit <= `True;
                        commit_pc <= Pc[head_pointer];
                        commit_data <= V2[head_pointer];
                        is_confirm <= `True;
                    end
                    else if(is_confirm == `True && en_commit == `True && commit_pc_from_rob == Pc[head_pointer]) begin
                        is_empty <= `False;
                        is_confirm <= `False;
                        is_store <= store_status[head_pointer];
                        data <= V2[head_pointer];
                        case(Op[head_pointer])
                            `SB:aim <= 2'b01;
                            `SH:aim <= 2'b10;
                            `SW:aim <= 2'b00;
                        endcase
                        addr <= V1[head_pointer] + {{20{Imm[head_pointer][11]}},Imm[head_pointer][11:0]};
                        head_pointer <= head_pointer + 1;
                    end
                end
                
            end
            else if(store_status[head_pointer] == `False && head_pointer != tail_pointer)begin
                if(Q1[head_pointer] == 0 && Q2[head_pointer] == 0 && comp_status[head_pointer] == `True) begin
                    if(is_confirm  == `False) begin
                        is_confirm <= `True;
                        is_empty <= `False;
                        is_store <= store_status[head_pointer];
                        addr <= V1[head_pointer] + {{20{Imm[head_pointer][11]}},Imm[head_pointer][11:0]};
                        data <= 0;
                        case(Op[head_pointer])
                            `LBU,`LB:aim <= 2'b01;
                            `LHU,`LH:aim <= 2'b10;
                            `LW:aim <= 2'b00;
                        endcase
                    end
                    else if(is_confirm == `True && en_finish == `True && en_instr == `False && en_store == `False) begin
                        is_confirm <= `False;
                        is_commit <= `True;
                        case(Op[head_pointer])
                            `LB:commit_data <= {{24{data_from_fc[7]}},data_from_fc[7:0]};
                            `LH:commit_data <= {{16{data_from_fc[15]}},data_from_fc[15:0]};
                            `LW,`LBU,`LHU:commit_data <= data_from_fc;
                        endcase
                        commit_pc <= Pc[head_pointer];
                        head_pointer <= head_pointer + 1;
                    end
                end
                
            end
        end
        //更新
        if(en_commit == `True) begin
            for(i = 0; i <= BufferLength;i = i+ 1) begin
                if(Q1[i] == commit_pc_from_rob && Q1[i] !=0 ) begin
                    Q1[i] <= 0 ;
                    V1[i] <= commit_data_from_rob;
                end
                if(Q2[i] == commit_pc_from_rob && Q2[i] !=0 ) begin
                    Q2[i] <= 0 ;
                    V2[i] <= commit_data_from_rob;
                end
            end
        end
    end
end

assign data_to_rob =commit_data;
assign commit_pc_to_rob = commit_pc;
assign data_to_fc = data;
assign is_store_to_fc = is_store;
assign is_empty_to_fc = is_empty;
assign aim_to_fc = aim;
assign is_commit_to_rob = is_commit;
assign addr_to_fc = addr;
assign is_ready_to_iq = is_ready;
endmodule