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
    input wire is_stall_from_rob,
    input wire is_exception_from_rob,
    input wire is_stall_from_fc,
    input wire is_finish_from_fc,
    input wire is_instr_from_fc,
    input wire addr_from_fc,
    input wire[`PcLength:`Zero] pc_from_rob,
    input wire[`InstrLength:`Zero] instr_from_fc,
    output wire is_empty_to_dc,
    output wire is_empty_to_fc,
    output wire[`InstrLength:`Zero] instr_to_dc,
    output wire[`PcLength:`Zero] pc_to_dc,
    output wire is_receive_to_fc,
    output wire[`PcLength:`Zero] pc_to_fc
//锁存与保持？
);

reg [PointerStorage:`Zero] head_pointer;
reg [PointerStorage:`Zero] tail_pointer;
reg [`InstrLength:`Zero] instr_queue[QueueStorage:`Zero];
reg [`PcLength:`Zero] pc_queue[QueueStorage:`Zero];
reg [PointerStorage:`Zero] store_pointer;
reg is_empty_fc;
reg input_instr_start;
reg is_empty_dc;//给dc的
reg [`PcLength:`Zero] pc_dc;
reg [`PcLength:`Zero] pc_fc;//指向尾部pc, 尾部即为传给fetcher的
reg [`InstrLength:`Zero] instr_dc;
reg [`PcLength:`Zero]test;
integer i;
always @(posedge rst) begin
    pc_dc <= 0;
    pc_fc <=  4096;
    head_pointer <=  0;
    tail_pointer <=  0;
    store_pointer <= 0;
    instr_dc <= 0;
    for(i =  0 ; i <= QueueStorage ; ++i ) begin
        instr_queue[i] <=  0;
        pc_queue[i] <= 0;
    end
    is_empty_dc <=  `True;
    is_empty_fc <= `False;
end
always @(posedge clk) begin
  

    //看是否要清空
    //若是,头尾指针置0,并且尾pc置为新来的
    //否则不变
    if(is_exception_from_rob) begin
        //这个0 是全位吗
        //是的
        store_pointer <= 0;
        head_pointer <= 0;
        tail_pointer <= 0;
        pc_fc <= pc_from_rob;
        pc_queue[0] <= pc_from_rob;
        is_empty_dc <= `True;
        is_empty_fc <= `False;
    end
    else begin
          //先接受上个周期发的请求
    //若满,则不接收
    //否则 接收,尾+1并且pc自动+32
        if((store_pointer != tail_pointer) ) begin //没满//且hit到了
            if(is_finish_from_fc == `True) begin
                instr_queue[tail_pointer] <= instr_from_fc;
                tail_pointer <= tail_pointer + 1; 
            end
        end
        //如果不堵住就发送
        if((head_pointer != store_pointer + 4'b0001)) begin
             if(is_stall_from_fc == `False) begin
                test <= store_pointer + 1;
                pc_fc <= pc_fc + 4;
                pc_queue[store_pointer+1] <= pc_fc+4;
                store_pointer <= store_pointer+1;
                is_empty_fc <= `False; 
             end
        end
        else begin
            is_empty_fc <= `True;
        //    head_pointer <= head_pointer + 1;
        end
            //先发送到解码器
    //若头等于尾则说明空,则发送空信息
    //以及stall情况
    //反之头进1
        if(is_stall_from_rob == `False ) begin
            if(head_pointer == tail_pointer) begin
                is_empty_dc <= `True;
            end
            else begin
                pc_dc <= pc_queue[head_pointer];
                instr_dc <= instr_queue[head_pointer];
                is_empty_dc <= `False;
                head_pointer <= head_pointer + 1;
            end
        end
        else begin 
            is_empty_dc <= `True;
        end 
    //再发送尾到fetcher，这个组合做
    end
end
assign is_empty_to_dc = is_empty_dc;
assign is_empty_to_fc = is_empty_fc;
assign pc_to_fc = pc_fc;
assign pc_to_dc = pc_dc;
assign instr_to_dc = instr_dc;
endmodule