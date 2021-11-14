`include "parameters.v"
module slb 
#(
    parameter SlbLength = 7,
    parameter PointerLength = 2
)
(
    input wire rst,
    input wire clk,
    input wire[`DataLength:`Zero] v1_from_rob,
    input wire[`DataLength:`Zero] v2_from_rob,
    input wire[`PcLength:`Zero] q1_from_rob,
    input wire[`PcLength:`Zero] q2_from_rob,
    input wire[`DataLength:`Zero] imm_from_rob,
    input wire[`DataLength:`Zero] commit_data_from_rob,
    input wire is_exception_from_rob,
    input wire is_empty_from_rob,
    input wire[`PcLength:`Zero] commit_pc_from_rob,
    input wire[`DataLength:`Zero] pc_from_rob,
    input wire is_sl_from_rob,
    input wire[`PcLength:`Zero] data_from_fetcher,
    input wire is_instr_from_fetcher,
    output wire[`PcLength:`Zero] addr_to_fetcher,
    output wire[`DataLength:`Zero] data_to_fetcher,
    output wire is_empty_to_fetcher,
    output wire is_store_to_fetcher,
    output wire is_stall_to_rob,
    output wire is_finish_to_rob,
    output wire[`DataLength:`Zero] data_to_rob,
    output wire[`DataLength:`Zero] pc_to_rob
);
reg [`PcLength:`Zero] Addr [SlbLength:`Zero];
reg [`DataLength:`Zero] Data [SlbLength:`Zero];
reg [`PcLength:`Zero] Queue1 [SlbLength:`Zero];
reg [`PcLength:`Zero] Queue2 [SlbLength:`Zero];
reg [`DataLength:`Zero] Value1 [SlbLength:`Zero];
reg [`DataLength:`Zero] Value2 [SlbLength:`Zero];
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
integer i;
//下面是提交池
reg [`PcLength:`Zero] addr_fetch;
reg [`DataLength:`Zero] data_fetch;
reg [`PcLength:`Zero] pc_rob;
reg [`DataLength:`Zero] data_rob;
reg is_stall;
reg is_finish;
reg is_empty;//向fetcher发送的
reg is_store;
always @(posedge rst) begin
    head_pointer <= 0;
    tail_pointer <= 0;
    addr_fetch <= 0;
    data_fetch <= 0;
    pc_rob <= 0;
    data_rob <= 0;
    is_stall <= 0;
    is_finish <= 0;
    is_empty <= 0;
    is_store <= 0;
    for (i = 0 ; i < SlbLength ; ++i ) begin
        Addr[i] <= 0;
        Data[i] <= 0;
        Queue1[i] <= 0;
        Queue2[i] <= 0 ;
        Value1[i] <= 0 ;
        Value2[i] <= 0 ;
    end
end
endmodule