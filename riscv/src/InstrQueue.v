`include "parameters.v"
module iq
#
(
    parameter QueueStorage = 15,
    parameter PointerStorage = 3//头指针和尾指针长�?
)
(
    input wire rst,
    input wire clk,
    input wire rdy,
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
    output wire[`PcLength:`Zero] pc_to_dc,
    output wire[`PcLength:`Zero] pc_to_ic
);

reg [PointerStorage:`Zero] head_pointer;
reg [PointerStorage:`Zero] tail_pointer;
reg [`InstrLength:`Zero] instr_queue[QueueStorage:`Zero];
reg [`PcLength:`Zero] pc_queue[QueueStorage:`Zero];
reg en_exception;
reg en_hit;
reg en_ready_rs;
reg en_ready_rob;
reg en_ready_slb;
reg en_rst;
reg en_rdy;

reg [`PcLength:`Zero] pc_dc;
reg [`PcLength:`Zero] pc_ic;//指向尾部pc, 尾部即为传给fetcher�?
reg [`InstrLength:`Zero] instr_dc;


reg is_empty_ic;
reg is_empty_dc;//给dc�?
reg is_ready;
reg is_receive;

integer i;
always @(posedge clk) begin
    if(rst == `True) begin
        head_pointer <= 0;
        tail_pointer <= 0;
        pc_ic <= 0;
        pc_dc <= 0;
        instr_dc <= 0;
        is_ready <= `True;
        is_empty_dc <= `True;
        is_receive <= `False;
        is_empty_ic <= `False;

        for(i =  0; i <= QueueStorage ; i = i+1 ) begin
            instr_queue[i] <=  0;
            pc_queue[i] <= 0;
        end 
    end
    else if(rdy == `False) begin
        
    end
    else begin
        if(is_exception_from_rob == `True) begin
            head_pointer <= 0;
            tail_pointer <= 0;
            pc_ic <= pc_from_rob;

            is_ready <= `True;
            is_empty_dc <= `True;
            is_receive <= `False;
            is_empty_ic <= `False;

        end
        else begin
            if(is_hit_from_ic == `True) begin
                //en_hit <= `False;
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
            else is_empty_ic <= `True;

            if(is_ready_from_rob == `True && is_ready_from_slb == `True && is_ready_from_rs == `True) is_ready <= `True;
            else is_ready <= `False;

            if(is_ready == `True) begin
                if(head_pointer == tail_pointer) is_empty_dc <= `True;
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
end
assign is_empty_to_dc = is_empty_dc;
assign is_empty_to_ic = is_empty_ic;
assign pc_to_ic = pc_ic;
assign pc_to_dc = pc_dc;
assign instr_to_dc = instr_dc;
endmodule