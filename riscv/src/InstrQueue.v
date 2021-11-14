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
    input wire is_hit_from_fetcher,
    input wire[`InstrLength:`Zero] instr_from_fetcher,
  //  input wire[`PcLength:`Zero] pc_from_pc_unit,
    output wire is_empty_to_decoder,
    output wire[`InstrLength:`Zero] instr_to_decoder,
    output wire[`PcLength:`Zero] pc_to_decoder,
    
    input wire[`PcLength:`Zero] pc_from_rob,
    output wire[`PcLength:`Zero] pc_to_fetcher
//锁存与保持？
);
reg [`PcLength:`Zero] head_pc;
reg [`PcLength:`Zero] tail_pc;//指向尾部pc, 尾部即为传给fetcher的
reg [`InstrLength:`Zero] head_instr;
reg [PointerStorage:`Zero] head_pointer;
reg [PointerStorage:`Zero] tail_pointer;
reg [`InstrLength:`Zero] instr_queue[QueueStorage:`Zero];
reg is_empty;
integer i;
always @(posedge rst) begin
    head_pc <= 0;
    tail_pc <=  0;
    head_pointer <=  0;
    tail_pointer <=  0;
    for(i =  0 ; i < QueueStorage ; ++i ) begin
        instr_queue[i] <=  0;
    end
    is_empty <=  0;
end


always @(posedge clk) begin
    //先接受上个周期发的请求
    //若满,则不接收
    //否则 接收,尾+1并且pc自动+32
    if((head_pointer != tail_pointer + 1) && is_hit_from_fetcher) begin //没满//且hit到了
        instr_queue[tail_pointer] = instr_from_fetcher[`InstrLength:`Zero];
        tail_pointer = tail_pointer + 1;
        tail_pc = tail_pc + `PcLength;
    end

    //再看是否要清空
    //若是,头尾指针置0,并且尾pc置为新来的
    //否则不变
    if(is_exception_from_rob) begin
        //这个0 是全位吗
        //是的
        head_pointer = 0;
        tail_pointer = 0;
        tail_pc = pc_from_rob;
    end

    //先发送到解码器
    //若头等于尾则说明空,则发送空信息
    //以及stall情况
    //反之头进1
    if(is_stall_from_rob == `False && is_stall_from_rs != `False && is_stall_from_slb != `False ) begin
        if(head_pointer == tail_pointer) begin
            is_empty = `True;
        end
        else begin
            head_pc = head_pc + `PcLength;
            is_empty = `False;
            head_pointer = head_pointer + 1;
        end
    end
    else begin 
        is_empty = `True;
    end 
    //再发送尾到fetcher，这个组合做
end

assign is_empty_to_decoder = is_empty;
assign pc_to_fetcher = tail_pc;
assign pc_to_decoder = head_pc;
assign instr_to_decoder = head_instr;
endmodule