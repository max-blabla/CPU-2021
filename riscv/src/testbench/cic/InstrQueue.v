`include "parameters.v"
module iq
#
(
    parameter QueueStorage = 15,
    parameter PointerStorage = 3//头指针和尾指针长度
)
(
    input wire rst,
    input wire clk,
    input wire is_exception_from_rob,
    input wire is_hit_from_ic,
    input wire is_ready_from_rs,
    input wire is_ready_from_slb,
    input wire is_ready_from_rob,
    input wire[`PcLength:`Zero] pc_from_rob,
    input wire[`InstrLength:`Zero] instr_from_ic,
    output wire is_empty_to_dc,
    output wire is_empty_to_ic,
    output wire[`InstrLength:`Zero] instr_to_dc,
    output wire[`PcLength:`Zero] pc_to_ic,
    output wire[`PcLength:`Zero] pc_to_fc
);

reg [PointerStorage:`Zero] head_pointer;
reg [PointerStorage:`Zero] tail_pointer;
reg [`InstrLength:`Zero] instr_queue[QueueStorage:`Zero];
reg [`PcLength:`Zero] pc_queue[QueueStorage:`Zero];
reg is_empty_ic;
reg is_empty_dc;//给dc的
reg [`PcLength:`Zero] pc_dc;
reg [`PcLength:`Zero] pc_ic;//指向尾部pc, 尾部即为传给fetcher的
reg [`InstrLength:`Zero] instr_dc;
reg [PointerStorage:`Zero]test;
reg [`PcLength:`Zero]test2;
reg [`PcLength:`Zero]lasttest;
reg is_ready;
reg is_request;
reg is_receive;
integer i;
always @(posedge rst) begin
    pc_dc <= 0;
    pc_ic <=  0;
    head_pointer <=  0;
    tail_pointer <=  0;
    is_receive <= `True;
    is_ready <= `True;
    instr_dc <= 0;
    for(i =  1; i <= QueueStorage ; ++i ) begin
        instr_queue[i] <=  0;
        pc_queue[i] <= 0;
    end
    is_empty_dc <=  `True;
    is_receive <= `False;
    is_empty_ic <= `False;
end
always @(posedge clk) begin
  

    //看是否要清空
    //若是,头尾指针置0,并且尾pc置为新来的
    //否则不变
    if(is_exception_from_rob) begin
        //这个0 是全位吗
        //是的
        head_pointer <= 0;
        tail_pointer <= 0;
        is_ready <= `True;
        pc_ic <= pc_from_rob;
        is_empty_dc <= `True;
        is_receive <= `False;
        is_empty_ic <= `False;
    end
    else begin
            if(is_hit_from_ic == `True) begin
                instr_queue[tail_pointer] <= instr_from_ic;
                pc_queue[tail_pointer] <= pc_ic;
                tail_pointer <= tail_pointer + 4'b0001; 
                is_receive <= `True;
            end
        if(head_pointer != tail_pointer + 4'b0001) begin
             if(is_receive == `True) begin
                is_receive <= `False;
                pc_ic <= pc_ic + 4;
                is_empty_ic <= `False; 
             end
             else is_empty_ic <= `True;
        end
        else begin
            is_empty_ic <= `True;
        end
    if(is_ready_from_rob == `True && is_ready_from_slb == `True && is_ready_from_rs == `True) is_ready <= `True;
    if(is_ready == `True) begin
        if(head_pointer == tail_pointer) begin
            is_empty_dc <= `True;
        end
        else begin
            is_ready <= `False;
            pc_dc <= pc_queue[head_pointer];
            instr_dc <= instr_queue[head_pointer];
            is_empty_dc <= `False;
            head_pointer <= head_pointer + 4'b0001;
        end
    end
    else is_empty_dc<=`True;
    end
end
assign is_empty_to_dc = is_empty_dc;
assign is_empty_to_ic = is_empty_ic;
assign pc_to_ic = pc_ic;
assign pc_to_dc = pc_dc;
assign instr_to_dc = instr_dc;
endmodule