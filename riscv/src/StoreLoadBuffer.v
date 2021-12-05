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
    input wire[`DataLength:`Zero] imm_from_rf,
    input wire[`DataLength:`Zero] commit_data_from_rob,
    input wire[`OpcodeLength:`Zero] op_from_rf,
    input wire is_exception_from_rob,
    input wire is_empty_from_rf,
    input wire is_ready_from_rf,
    input wire is_commit_from_rob,
    input wire is_stall_from_fc,
    input wire is_store_from_fc,
    input wire[`PcLength:`Zero] commit_pc_from_rob,
    input wire[`DataLength:`Zero] pc_from_rf,
    input wire is_sl_from_rf,
    input wire[`PcLength:`Zero] data_from_fc,
    input wire is_instr_from_fc,
    input wire is_finish_from_fc,
    output wire[`PcLength:`Zero] addr_to_fc,
    output wire[`DataLength:`Zero] data_to_fc,
    output wire is_empty_to_fc,
    output wire is_store_to_fc,
    output wire is_receive_to_fc,
    output wire is_ready_to_rf,
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
integer i;
//下面是提交池
reg [`DataLength:`Zero] addr_fc; //done
reg [`DataLength:`Zero] data_fc; //done
reg [`PcLength:`Zero] pc_fc; //done
reg [`PcLength:`Zero] pc_rob; //done
reg [`DataLength:`Zero] data_rob; //done
reg [`OpcodeLength:`Zero] op; //done
reg is_receive; //对fc
reg is_ready;//对rob
reg is_finish;//向rob发送的
reg is_empty;//向fetcher发送的
reg is_store;//向fetcher发送的
reg [CounterLength:`Zero] aim;
reg [`DataLength:`Zero] test1;
reg [`DataLength:`Zero] test2;
reg [`DataLength:`Zero] test4;
reg [`DataLength:`Zero] test5;
reg [`OpcodeLength:`Zero] test6;
reg test3;
always @(posedge rst) begin
    head_pointer <= 0;
    tail_pointer <= 0;
    addr_fc <= 0;
    data_fc <= 0;
    pc_fc <= 0;
    pc_rob <= 0;
    data_rob <= 0;
    is_finish <= 0;
    is_ready <= 0;
    is_receive <= 0;
    is_empty <= `True;
    is_store <= 0;
    op <= 0;
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
    end
end

always @(posedge clk) begin
    //先拿上个周期rob的东西更新一遍
    if(is_exception_from_rob) begin
        head_pointer <= 0;
        tail_pointer <= 0;
        addr_fc <= 0;
        data_fc <= 0;
        pc_fc <= 0;
        pc_rob <= 0;
        data_rob <= 0;
        is_finish <= 0;
        is_ready <= 0;
        is_receive <= 0;
        is_empty <= `True;
        is_store <= 0;
        op <= 0;
      //  for (i = 0 ; i <= SlbLength ; ++i ) begin
       //     Queue1[i] <= 0;
      //      Queue2[i] <= 0 ;
      //      Value1[i] <= 0 ;
      //      Value2[i] <= 0 ;
      //      Op[i] <= 0;
      //      Pc[i] <= 0;
      //      Imm[i] <= 0;
      //      finish[i] <= 0;
       //     doing[i] <= 0;
       // end
    end
    else begin
        if(is_commit_from_rob) begin
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
        //再拿fc更新一遍
        if(is_finish_from_fc == `True && is_instr_from_fc == `False && is_store_from_fc == `False) begin
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
            is_receive <= `True;
        end
        else begin
            is_receive <= `False;
        end
            //然后每个上沿发头请求给fetcher，同时看能不能发给rob，如果是S类，如果fc不阻塞且准备好，那么出发；如果是L类，则等待它发回来，我们stall住,记得is_empty，is_store
            test4 <= Queue1[head_pointer];
            test5 <= Queue2[head_pointer];
            if(Queue1[head_pointer] == 0 && Queue2[head_pointer] == 0 && head_pointer != tail_pointer) begin
                test6 <= Op[head_pointer];
                case (Op[head_pointer])
                `SB,`SW,`SH:begin
                    if(is_stall_from_fc == `False) begin
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
                        if(is_stall_from_fc == `False) begin
                            test1 <= `True;
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
                //然后看自己堵了吗，堵了的话不准进
                if(head_pointer != tail_pointer + 3'b001) is_ready <= `True;
                else is_ready <= `False;
                if(is_ready_from_rf == `True && is_sl_from_rf == `True && is_ready == `True)begin
                    if(op_from_rf == `SB || op_from_rf ==`SW || op_from_rf == `SH) finish[tail_pointer] <= `True;
                    else finish[tail_pointer] <= `False;
                    doing[tail_pointer] <= `False;
                    Op[tail_pointer] <= op_from_rf;
                    Queue1[tail_pointer] <= q1_from_rf;
                    Queue2[tail_pointer] <= q2_from_rf;
                    Value1[tail_pointer] <= v1_from_rf;
                    Value2[tail_pointer] <= v2_from_rf;
                    Pc[tail_pointer] <= pc_from_rf;
                    Imm[tail_pointer] <= imm_from_rf;
                    tail_pointer <= tail_pointer + 3'b001;
                end
    end
end
assign data_to_fc = data_fc;
assign addr_to_fc = addr_fc;
assign pc_to_rob = pc_rob;
assign data_to_rob = data_rob;
assign is_receive_to_fc = is_receive;
assign is_ready_to_rf = is_ready;
assign is_store_to_fc = is_store;
assign is_finish_to_rob = is_finish;
assign is_empty_to_fc = is_empty;
assign aim_to_fc = aim;
endmodule