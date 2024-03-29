
`include "parameters.v"
module rs
#(
    parameter RsLength = 7,
    parameter PointerLength = 2
)
(
    input wire rst,
    input wire clk,
    input wire is_empty_from_dc,
    input wire is_sl_from_dc,
    input wire is_exception_from_rob,
    input wire is_commit_from_rob,
    input wire[`OpcodeLength:`Zero] op_from_dc,
    input wire[`DataLength:`Zero] v1_from_rf,
    input wire[`DataLength:`Zero] v2_from_rf,
    input wire[`PcLength:`Zero] q1_from_rf,
    input wire[`PcLength:`Zero] q2_from_rf,
    input wire[`DataLength:`Zero] imm_from_dc,
    input wire[`DataLength:`Zero] pc_from_rf,
    input wire[`DataLength:`Zero] pc_from_dc,
    input wire[`DataLength:`Zero] commit_data_from_rob,
    input wire[`PcLength:`Zero] commit_pc_from_rob,
    output wire[`OpcodeLength:`Zero] op_to_alu,
    output wire[`DataLength:`Zero] v1_to_alu,
    output wire[`DataLength:`Zero] v2_to_alu,
    output wire[`DataLength:`Zero] imm_to_alu,
    output wire[`DataLength:`Zero] pc_to_alu,
    output wire is_ready_to_iq,
    output wire is_empty_to_alu
);
reg [`DataLength:`Zero] Value1[RsLength:`Zero];
reg [`DataLength:`Zero] Value2[RsLength:`Zero];
reg [`PcLength:`Zero] Queue1[RsLength:`Zero];
reg [`PcLength:`Zero] Queue2[RsLength:`Zero];
reg [`OpcodeLength:`Zero] Op[RsLength:`Zero];
reg is_busy[RsLength:`Zero];
reg is_complete[RsLength:`Zero];
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
reg [PointerLength:`Zero] Free;
reg [PointerLength:`Zero] Comp;
reg [PointerLength:`Zero] Issue;
reg [PointerLength:`Zero] Storage;
reg is_ready;
integer test1;
integer test2;
integer i;
always @(posedge rst) begin
    is_ready <= 0;
    is_empty <= `True;
    v1 <= 0;
    v2 <= 0;
    imm <= 0;
    op <= 0;
    pc <= 0;
    Storage <= 0;
    for(i = 0 ;i <= RsLength; ++i) begin
        Value1[i] <= 0;
        Value2[i] <= 0;
        Queue1[i] <= 0;
        Queue2[i] <= 0;
        is_complete[i] <= 0;
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
        Storage <= 0;
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
            is_complete[i] <= 0;
            Pc[i] <= 0;
            Imm[i] <= 0; 
            Op[i] <= 0;
        end
    end
    else begin
                    //先用rob的提交更新
            //再找一遍可以发射的
    
    if(is_busy[0] == `True && is_complete[0] == `True && Queue1[0] == 0 && Queue2[0] == 0) begin
        Issue = 0;
        is_empty = `False;
    end
    else if(is_busy[1] == `True && is_complete[1] == `True && Queue1[1] == 0 && Queue2[1] == 0) begin
        Issue = 1;
        is_empty = `False;
    end
    else if(is_busy[2] == `True && is_complete[2] == `True && Queue1[2] == 0 && Queue2[2] == 0) begin
        Issue = 2;
        is_empty = `False;
    end
    else if(is_busy[3] == `True && is_complete[3] == `True && Queue1[3] == 0 && Queue2[3] == 0) begin
        Issue = 3;
        is_empty = `False;
    end
    else if(is_busy[4] == `True && is_complete[4] == `True && Queue1[4] == 0 && Queue2[4] == 0) begin
        Issue = 4;
        is_empty = `False;
    end
    else if(is_busy[5] == `True && is_complete[5] == `True && Queue1[5] == 0 && Queue2[5] == 0) begin
        Issue = 5;
        is_empty = `False;
    end
    else if(is_busy[6] == `True && is_complete[6] == `True && Queue1[6] == 0 && Queue2[6] == 0) begin
        Issue = 6;
        is_empty = `False;
    end
    else if(is_busy[7] == `True && is_complete[7] == `True && Queue1[7] == 0 && Queue2[7] == 0) begin
        Issue = 7;
        is_empty = `False;
    end
    else is_empty = `True;
    if(is_empty == `False) begin
        Storage = Storage - 3'b001;
        v1 = Value1[Issue];
        v2 = Value2[Issue];
        imm = Imm[Issue];
        pc = Pc[Issue];
        op = Op[Issue];
        is_busy[Issue] = `False;
    end
    if(is_busy[0] == `False) Free = 0;
    else if(is_busy[1] == `False) Free = 1;
    else if(is_busy[2] == `False) Free = 2;
    else if(is_busy[3] == `False) Free = 3;
    else if(is_busy[4] == `False) Free = 4;
    else if(is_busy[5] == `False) Free = 5;
    else if(is_busy[6] == `False) Free = 6;
    else if(is_busy[7] == `False) Free = 7;
    if(RsLength <= Storage + 3'b011) begin
        is_ready <= `False;
    end
    else is_ready <= `True;
    if(is_empty_from_dc == `False && is_sl_from_dc == `False) begin      
            //再输入新的来自rf的值
                Pc[Free] <= pc_from_dc;
                testpc <= pc_from_dc;
                Imm[Free] <= imm_from_dc;
                Op[Free] <= op_from_dc;
                Storage <= Storage + 3'b001;
                is_busy[Free] <= `True;
                Comp <= Free;
                is_complete[Free] <= `False;
        end
    end
        if(is_busy[Comp] == `True && Pc[Comp] == pc_from_rf && is_complete[Comp] == `False) begin
            test2 <=  Comp;
            if(q1_from_rf == commit_pc_from_rob && q1_from_rf != 0)begin
                Queue1[Comp] <= 0;
                Value1[Comp] <= commit_data_from_rob;
            end 
            else begin
                Queue1[Comp] <= q1_from_rf;
                Value1[Comp] <= v1_from_rf;
            end
            if(q2_from_rf == commit_pc_from_rob && q2_from_rf != 0 )begin
                Queue2[Comp] <= 0;
                Value2[Comp] <= commit_data_from_rob;
            end 
            else begin
                Queue2[Comp] <= q2_from_rf;
                Value2[Comp] <= v2_from_rf;
            end
            is_complete[Comp] <= `True;
        end
        if(is_commit_from_rob == `True) begin
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
end
assign v1_to_alu = v1;
assign v2_to_alu = v2;
assign imm_to_alu = imm;
assign pc_to_alu = pc;
assign is_ready_to_iq = is_ready;
assign op_to_alu = op;
assign is_empty_to_alu = is_empty;
endmodule