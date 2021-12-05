
`include "parameters.v"
module rs
#(
    parameter RsLength = 7,
    parameter PointerLength = 2
)
(
    input wire rst,
    input wire clk,
    input wire is_empty_from_rf,
    input wire is_sl_from_rf,
    input wire is_exception_from_rob,
    input wire is_commit_from_rob,
    input wire is_ready_from_rf,
    input wire[`OpcodeLength:`Zero] op_from_rf,
    input wire[`DataLength:`Zero] v1_from_rf,
    input wire[`DataLength:`Zero] v2_from_rf,
    input wire[`PcLength:`Zero] q1_from_rf,
    input wire[`PcLength:`Zero] q2_from_rf,
    input wire[`DataLength:`Zero] imm_from_rf,
    input wire[`DataLength:`Zero] pc_from_rf,
    input wire[`DataLength:`Zero] commit_data_from_rob,
    input wire[`PcLength:`Zero] commit_pc_from_rob,
    output wire[`OpcodeLength:`Zero] op_to_alu,
    output wire[`DataLength:`Zero] v1_to_alu,
    output wire[`DataLength:`Zero] v2_to_alu,
    output wire[`DataLength:`Zero] imm_to_alu,
    output wire[`DataLength:`Zero] pc_to_alu,
    output wire is_ready_to_rf,
    output wire is_empty_to_alu
);
reg [`DataLength:`Zero] Value1[RsLength:`Zero];
reg [`DataLength:`Zero] Value2[RsLength:`Zero];
reg [`PcLength:`Zero] Queue1[RsLength:`Zero];
reg [`PcLength:`Zero] Queue2[RsLength:`Zero];
reg [`OpcodeLength:`Zero] Op[RsLength:`Zero];
reg is_busy[RsLength:`Zero];
reg [`DataLength:`Zero] Imm[RsLength:`Zero];
reg [`PcLength:`Zero] Pc[RsLength:`Zero];
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`DataLength:`Zero] imm;
reg [`PcLength:`Zero] pc;
reg [`OpcodeLength:`Zero] op;
reg is_empty;
reg [`PcLength:`Zero] testpc;
//integer test;
reg [`PcLength:`Zero] t1;
reg [`PcLength:`Zero] t2;
reg [`PcLength:`Zero] t3;
reg [`PcLength:`Zero] t4;
reg [`PcLength:`Zero] t5;
reg [`PcLength:`Zero] t6;
reg [`PcLength:`Zero] t7;
reg [`PcLength:`Zero] t8;
reg [`PcLength:`Zero] y1;
reg [`PcLength:`Zero] y2;
reg [`PcLength:`Zero] y3;
reg [`PcLength:`Zero] y4;
reg [`PcLength:`Zero] y5;
reg [`PcLength:`Zero] y6;
reg [`PcLength:`Zero] y7;
reg [`PcLength:`Zero] y8;
reg [PointerLength:0] Free;
reg is_ready;
integer test1;
integer i;
always @(posedge rst) begin
    is_ready <= 0;
    is_empty <= `True;
    v1 <= 0;
    v2 <= 0;
    imm <= 0;
    op <= 0;
    pc <= 0;
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
        is_ready <= 0;
        is_empty <= `True;
        v1 <= 0;
        v2 <= 0;
        imm <= 0;
        pc <= 0;
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
                    //先用rob的提交更新
    if(is_commit_from_rob == `True) begin
                t1 = Queue1[0];
                t2 = Queue1[1];
                t3 = Queue1[2];
                t4 = Queue1[3];
                t5 = Queue1[4];
                t6 = Queue1[5];
                t7 = Queue1[6];
                t8 = Queue1[7];
                y1 = Queue2[0];
                y2 = Queue2[1];
                y3 = Queue2[2];
                y4 = Queue2[3];
                y5 = Queue2[4];
                y6 = Queue2[5];
                y7 = Queue2[6];
                y8 = Queue2[7];

                for(i = 0 ; i <= RsLength ; ++i) begin
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
            //再找一遍可以发射的
    begin : loop
        is_empty = `True;
        for(i = 0 ; i <= RsLength ; ++i) begin
            if(is_busy[i] == `True && Queue1[i] == 0 && Queue2[i] == 0) begin
                test1 = i;
                v1 = Value1[i];
                v2 = Value2[i];
                imm = Imm[i];
                pc = Pc[i];
                op = Op[i];
                is_busy[i] = `False;
                is_empty = `False;
                disable loop;
            end
        end
    end
    if(is_empty_from_rf == `False) begin
        begin : loop2 
                is_ready = `False;
                for(i = 0 ; i <= RsLength ; ++i) begin
                    if(is_busy[i] == `False) begin
                        is_ready = `True;
                        Free = i;
                        disable loop2;
                    end
                end
        end
     end
    if(is_ready_from_rf == `True && is_sl_from_rf == `False) begin      
            //再输入新的来自rf的值
                Pc[Free] = pc_from_rf;
                testpc = pc_from_rf;
                Imm[Free] = imm_from_rf;
                Value1[Free] = v1_from_rf;
                Value2[Free] = v2_from_rf;
                Queue1[Free] = q1_from_rf;
                Queue2[Free] = q2_from_rf;
                Op[Free] = op_from_rf;
                is_busy[Free] = `True;
            end
        end
end
assign v1_to_alu = v1;
assign v2_to_alu = v2;
assign imm_to_alu = imm;
assign pc_to_alu = pc;
assign is_ready_to_rf = is_ready;
assign op_to_alu = op;
assign is_empty_to_alu = is_empty;
endmodule