`include "parameters.v"
module ft 
#
(
    parameter FetcherLength = 31,
    parameter PointerLength = 4,
    parameter CounterLength = 4
)
(
    input rst,
    input clk,
    input wire[`UnsignedCharLength:`Zero] data_from_ram,
    input wire[`PcLength:`Zero] addr_from_slb,
    input wire[`DataLength:`Zero] data_from_slb,
    input wire is_empty_from_slb,
    input wire is_store_from_slb,
    input wire[`PcLength:`Zero] addr_from_iq,
    input wire[`DataLength:`Zero] data_from_iq,
    input wire is_empty_from_iq,
    input wire is_stall_from_iq,
    output wire is_instr_to_iq,
    output wire is_stall_to_slb,
    output wire is_stall_to_instr_queue,
    output wire is_instr_to_slb,
    output wire is_store_to_ram,
    output wire [`PcLength:`Zero] addr_to_ram,
    output wire [`UnsignedCharLength:`Zero] data_to_ram,
    output wire [`PcLength:`Zero] pc_to_slb,
    output wire [`DataLength:`Zero] data_to_slb,
    output wire [`DataLength:`Zero] data_to_iq
);
reg [`PcLength:`Zero] Addr[FetcherLength:`Zero];
reg [`DataLength:`Zero] Data[FetcherLength:`Zero];
reg [`OpcodeLength:`Zero] Op[FetcherLength:`Zero];
reg instr_status[FetcherLength:`Zero];
reg store_status[FetcherLength:`Zero];
reg [CounterLength:`Zero] cnt;
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
//下面为提交池
reg [`PcLength:`Zero] pc;
reg [`DataLength:`Zero] data;
reg is_stall;
reg is_instr;
reg is_store;
integer i;
always @(posedge rst) begin
    is_stall <= 0;
    is_instr <= 0;
    is_store <= 0;
    cnt <= 0;
    head_pointer <= 0;
    tail_pointer <= 0;
    for(i = 0 ; i < FetcherLength; ++i) begin
        Addr[i] <= 0;
        Data[i] <= 0;
        Op[i] <= 0;
        instr_status[i] <= 0;
        store_status[i] <= 0;
    end
end
endmodule