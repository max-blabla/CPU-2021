`include "parameters.v"
module slb 
#(
    parameter SlbLength = 7,
    parameter PointerLength = 2,
    parameter OpcodeLength = 5,
    parameter CounterLength = 1
)
(
    input wire rst,
    input wire clk,
    input wire[`DataLength:`Zero] v1_from_rf,
    input wire[`DataLength:`Zero] v2_from_rf,
    input wire[`PcLength:`Zero] q1_from_rf,
    input wire[`PcLength:`Zero] q2_from_rf,
    input wire[`DataLength:`Zero] imm_from_dc,

    input wire[`DataLength:`Zero] commit_data_from_rob,
    input wire[`PcLength:`Zero] commit_pc_from_rob,
    input wire[`OpcodeLength:`Zero] op_from_dc,

    input wire is_exception_from_rob,
    input wire is_commit_from_rob,
    input wire is_stall_from_fc,
    input wire is_store_from_fc,
    input wire is_empty_from_dc,
    input wire is_sl_from_dc,
    input wire is_instr_from_fc,
    input wire is_finish_from_fc,

    input wire[`DataLength:`Zero] pc_from_dc,


    input wire[`PcLength:`Zero] data_from_fc,

    output wire[`PcLength:`Zero] addr_to_fc,
    output wire[`DataLength:`Zero] data_to_fc,
    output wire is_empty_to_fc,
    output wire is_store_to_fc,
    output wire is_receive_to_fc,
    output wire is_ready_to_iq,
    output wire is_finish_to_rob,
    output wire[`DataLength:`Zero] data_to_rob,
    output wire[`DataLength:`Zero] pc_to_rob,
    output wire[CounterLength:`Zero] aim_to_fc
);
reg finish [SlbLength:`Zero];
reg doing [SlbLength : `Zero];
reg [`PcLength:`Zero] Pc[SlbLength:`Zero];
reg [OpcodeLength:`Zero] Op[SlbLength:`Zero];
reg [`PcLength:`Zero] Queue1 [SlbLength:`Zero];
reg [`PcLength:`Zero] Queue2 [SlbLength:`Zero];
reg [`DataLength:`Zero] Value1 [SlbLength:`Zero];
reg [`DataLength:`Zero] Value2 [SlbLength:`Zero];
reg [`DataLength:`Zero] Imm [SlbLength:`Zero];
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
reg [PointerLength:`Zero] comp_pointer;
integer i;
//下面是提交池
reg [`DataLength:`Zero] addr_fc; //done
reg [`DataLength:`Zero] data_fc; //done
reg [`PcLength:`Zero] pc_fc; //done
reg [`PcLength:`Zero] pc_rob; //done
reg [`DataLength:`Zero] data_rob; //done
reg [`OpcodeLength:`Zero] op; //done

reg is_ready;//对rob
reg is_finish;//向rob发送的
reg is_empty;//向fetcher发送的
reg is_store;//向fetcher发送的
reg is_complete[SlbLength:`Zero];
reg [CounterLength:`Zero] aim;

reg en_commit;
reg en_empty;
reg en_exception;
reg en_rst;
reg en_sl;
reg en_finish;
reg en_stall;
reg en_instr;
reg en_store;

reg [`DataLength:`Zero] test1;
reg [`DataLength:`Zero] test2;
reg [`DataLength:`Zero] test4;
reg [`DataLength:`Zero] test5;
reg [`OpcodeLength:`Zero] test6;
reg test3;


always @(posedge clk) begin
    en_commit = is_commit_from_rob;
    en_empty = is_empty_from_dc;
    en_exception = is_exception_from_rob;
    en_rst = rst;
    en_sl = is_sl_from_dc;
    en_finish = is_finish_from_fc;
    en_stall = is_stall_from_fc;
    en_instr = is_instr_from_fc;
    en_store = is_store_from_fc;
    if(en_rst ==`True) begin
        head_pointer <= 0;
        tail_pointer <= 0;
        addr_fc <= 0;
        data_fc <= 0;
        pc_fc <= 0;
        pc_rob <= 0;
        data_rob <= 0;
        is_finish <= 0;
        is_ready <= `True;
        is_empty <= `True;
        is_store <= 0;
        op <= 0;
        comp_pointer <= 0;
        for (i = 0 ; i <= SlbLength ; ++i ) begin
            //对于L指令 Q2 恒为 0; V2 为 读出来的值
            Queue1[i] <= 0;
            Queue2[i] <= 0 ;
            Value1[i] <= 0 ;
            Value2[i] <= 0 ;
            Op[i] <= 0;
            Pc[i] <= 0;
            Imm[i] <= 0;
            finish[i] <= 0;
            doing[i] <= 0;
            is_complete[i] <= 0;
        end
    end
    else begin
        if(is_exception_from_rob == `True) begin
            head_pointer <= 0;
            tail_pointer <= 0;
            comp_pointer <= 0;
            addr_fc <= 0;
            data_fc <= 0;
            pc_fc <= 0;
            pc_rob <= 0;
            data_rob <= 0;
            is_finish <= 0;
            is_ready <= `True;
            is_empty <= `True;
            is_store <= 0;
            op <= 0;
        end
        else begin
            //再拿fc更新一遍
            if(en_finish == `True && en_instr == `False && en_store == `False) begin
                case (Op[head_pointer]) 
                    `LHU:begin
                        Value2[head_pointer] <= data_from_fc[15:0];
                        finish[head_pointer] <= `True;
                    end
                    `LBU:begin
                        Value2[head_pointer] <= data_from_fc[7:0];
                        finish[head_pointer] <= `True;
                    end
                    `LH:begin
                        Value2[head_pointer] <= {{16{data_from_fc[15]}},data_from_fc[15:0]};
                        finish[head_pointer] <= `True;
                    end
                    `LB:begin
                        Value2[head_pointer] <= {{24{data_from_fc[7]}},data_from_fc[7:0]};
                        finish[head_pointer] <= `True;
                    end
                    `LW:begin
                        Value2[head_pointer]<= data_from_fc;
                        finish[head_pointer] <= `True;
                    end
                endcase
            end

                //然后每个上沿发头请求给fetcher，同时看能不能发给rob，如果是S类，如果fc不阻塞且准备好，那么出发；如果是L类，则等待它发回来，我们stall住,记得is_empty，is_store
            if(Queue1[head_pointer] == 0 && Queue2[head_pointer] == 0 && head_pointer != tail_pointer && is_complete[head_pointer] == `True) begin
                    case (Op[head_pointer])
                    `SB,`SW,`SH:begin
                        if(en_stall == `False) begin
                            addr_fc <= Value1[head_pointer] + {{20{Imm[head_pointer][11]}},Imm[head_pointer][11:0]};
                            data_fc <= Value2[head_pointer];
                            is_empty <= `False;
                            is_finish <= `True;
                            is_store <= `True;
                            data_rob <= 0;
                            pc_rob <= Pc[head_pointer];
                            head_pointer <= head_pointer + 3'b001;
                            case (Op[head_pointer]) 
                                `SH:  aim <= 2'b10;
                                `SB:  aim <= 2'b01;
                                `SW:  aim <= 2'b00;
                            endcase
                        end
                        else begin
                            is_empty <= `True;
                            is_finish <= `False;
                        end
                    end
                    `LHU,`LBU,`LH,`LB,`LW:begin
                        if(doing[head_pointer])begin 
                            is_empty <= `True;
                            if(finish[head_pointer]) begin
                                data_rob <= Value2[head_pointer];
                                pc_rob <= Pc[head_pointer];
                                head_pointer <= head_pointer + 3'b001;
                                is_finish <= `True;
                            end
                            else begin
                                is_finish <= `False;
                            end
                        end
                        else begin
                            if(en_stall == `False) begin
                                test2 <= Value1[head_pointer];
                                test3 <= {{20{Imm[head_pointer][11]}},Imm[head_pointer][11:0]};
                                addr_fc <= Value1[head_pointer] + {{20{Imm[head_pointer][11]}},Imm[head_pointer][11:0]};
                                is_empty <= `False;
                                is_store <= `False;
                                is_finish <= `False;
                                doing[head_pointer] <= `True;
                                case (Op[head_pointer]) 
                                    `LHU: aim <= 2'b10;
                                    `LBU: aim <= 2'b01;
                                    `LH:  aim <= 2'b10;
                                    `LB:  aim <= 2'b01;
                                    `LW:  aim <= 2'b00;
                                endcase
                            end
                            else begin
                                is_empty <= `True;
                            end
                        end
                    end
                endcase
            end
            else begin
                is_empty <= `True;
                is_finish <= `False;
            end
                if(head_pointer != tail_pointer + 3'b011 && head_pointer != tail_pointer + 3'b010 && head_pointer != tail_pointer + 3'b001) is_ready <= `True;
                else is_ready <= `False;

                if(en_empty == `False && en_sl == `True)begin
                    if(op_from_dc == `SB || op_from_dc ==`SW || op_from_dc == `SH) finish[tail_pointer] <= `True;
                    else finish[tail_pointer] <= `False;
                    doing[tail_pointer] <= `False;
                    Op[tail_pointer] <= op_from_dc;
                    Pc[tail_pointer] <= pc_from_dc;
                    Imm[tail_pointer] <= imm_from_dc;
                    is_complete[tail_pointer] <= `False;
                    tail_pointer <= tail_pointer + 3'b001;
                    comp_pointer <= tail_pointer;
                end
                if(is_complete[comp_pointer] == `False) begin
                    if(q1_from_rf == commit_pc_from_rob && q1_from_rf != 0)begin
                        Queue1[comp_pointer] <= 0;
                        Value1[comp_pointer] <= commit_data_from_rob;
                    end 
                    else begin
                        Queue1[comp_pointer] <= q1_from_rf;
                        Value1[comp_pointer] <= v1_from_rf;
                    end
                    if(q2_from_rf == commit_pc_from_rob && q2_from_rf != 0)begin
                        Queue2[comp_pointer] <= 0;
                        Value2[comp_pointer] <= commit_data_from_rob;
                    end 
                    else begin
                        Queue2[comp_pointer] <= q2_from_rf;
                        Value2[comp_pointer] <= v2_from_rf;
                    end
                    is_complete[comp_pointer] <= `True;
                end
            if(en_commit == `True) begin
                for(i = 0 ; i <= SlbLength;i = i + 1) begin
                    if(Queue1[i] != 0 && Queue1[i]  ==  commit_pc_from_rob) begin
                        Queue1[i] <= 0;
                        Value1[i] <= commit_data_from_rob;
                    end
                    if(Queue2[i] != 0 && Queue2[i]  ==  commit_pc_from_rob) begin
                        Queue2[i] <= 0;
                        Value2[i] <= commit_data_from_rob;
                    end
                end
            end
        end
    end
end
assign data_to_fc = data_fc;
assign addr_to_fc = addr_fc;
assign pc_to_rob = pc_rob;
assign data_to_rob = data_rob;
assign is_ready_to_iq = is_ready;
assign is_store_to_fc = is_store;
assign is_finish_to_rob = is_finish;
assign is_empty_to_fc = is_empty;
assign aim_to_fc = aim;
endmodule