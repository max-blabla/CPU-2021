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
    input wire is_stall_from_rs,
    input wire is_stall_from_slb,
    input wire[`InstrLength:`Zero] instr_from_fetcher,
    output wire is_empty_to_decoder,
    output wire[`InstrLength:`Zero] instr_to_decoder,
    output wire[`PcLength:`Zero] pc_to_decoder,
    
    input wire[`PcLength:`Zero] pc_from_rob,
    output wire[`PcLength:`Zero] pc_to_fetcher,
    input wire[`PcLength:`Zero] pc_from_fetcher
);
reg [PointerStorage:`Zero] head_pointer;
reg [PointerStorage:`Zero] tail_pointer;
reg [`InstrLength:`Zero] instr_queue[QueueStorage:`Zero];
reg [`PcLength:`Zero] pc_queue[QueueStorage:`Zero];
//提交池
reg [`PcLength:`Zero] pc_dc;
reg [`DataLength:`Zero] instr_dc;
reg [`PcLength:`Zero] pc_fc;//指向尾部pc, 尾部即为传给fetcher的
reg is_empty;
integer i;
always @(posedge rst) begin
    pc_dc <= 0;
    pc_fc <=  0;
    instr_dc <= 0;
    head_pointer <=  0;
    tail_pointer <=  0;
    for(i =  0 ; i < QueueStorage ; ++i ) begin
        instr_queue[i] <=  0;
        pc_queue[i] <= 0;
    end
    is_empty <=  0;
end


always @(posedge clk) begin
    //看是否要清空
    //若是,头尾指针置0,并且尾pc置为新来的
    //否则不变
    if(is_exception_from_rob) begin
        head_pointer <= 0;
        tail_pointer <= 0;
        pc_fc <= pc_from_rob;
    end
    else begin
            //先接受上个周期发的请求
    //若满,则不接收
    //否则 接收,尾+1并且pc自动+32
        if((head_pointer != tail_pointer + 1) && is_hit_from_fetcher) begin //没满//且hit到了
        //测试一下实际情况
            instr_queue[tail_pointer] <= instr_from_fetcher[`InstrLength:`Zero];
            pc_queue[tail_pointer] <= pc_from_fetcher;
            tail_pointer <= tail_pointer + 1;
            pc_fc <= pc_fc + `DataLength;
        end
    //先发送到解码器
    //若头等于尾则说明空,则发送空信息
    //以及stall情况
    //反之头进1
        if(is_stall_from_rob == `False && is_stall_from_rs == `False && is_stall_from_slb == `False ) begin
            if(head_pointer == tail_pointer) begin
                is_empty = `True;
            end
            else begin
                instr_dc <= instr_queue[head_pointer];
                pc_dc <= pc_queue[head_pointer];
                is_empty <= `False;
                head_pointer <= head_pointer + 1;
            end
        end
        else begin 
            is_empty <= `True;
        end 
    end
end

assign is_empty_to_decoder = is_empty;
assign pc_to_fetcher = pc_fc;
assign pc_to_decoder = pc_dc;
assign instr_to_decoder = instr_dc;
endmodule