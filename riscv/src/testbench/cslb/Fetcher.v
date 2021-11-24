`include "parameters.v"
module fc
#
(
    parameter FetcherLength = 31,
    parameter PointerLength = 4,
    parameter CounterLength = 1,
    parameter PointerOne = 5'b00001,
    parameter PointerTwo = 5'b00010,
    parameter PointerThree = 5'b00011
)
(
    input rst,
    input clk,
    input wire[`UnsignedCharLength:`Zero] data_from_ram,
    input wire[`PcLength:`Zero] addr_from_slb,
    input wire[`DataLength:`Zero] data_from_slb,
    input wire is_empty_from_slb,
    input wire is_store_from_slb,
    input wire is_empty_from_iq,
    input wire [`PcLength:`Zero] addr_from_iq,
    input wire is_receive_from_iq,
    input wire is_receive_from_slb,
    input wire is_exception_from_rob,
    input wire [CounterLength:`Zero] aim_from_slb,
    output wire is_instr_to_iq,
    output wire is_stall_to_slb,
    output wire is_stall_to_iq,
    output wire is_instr_to_slb,

    output wire is_store_to_ram,
    output wire is_finish_to_slb,
    output wire is_finish_to_iq,
    output wire [`PcLength:`Zero] addr_to_ram,
    output wire [`UnsignedCharLength:`Zero] data_to_ram,
  //  output wire [`PcLength:`Zero] pc_to_slb,
    output wire [`DataLength:`Zero] data_to_slb,
    output wire [`DataLength:`Zero] data_to_iq,
    output wire [`DataLength:`Zero] addr_to_iq
);
reg [`PcLength:`Zero] Addr[FetcherLength:`Zero];
reg [`DataLength:`Zero] Data[FetcherLength:`Zero];
reg instr_status[FetcherLength:`Zero];//是否是指令
reg store_status[FetcherLength:`Zero];
reg [CounterLength:`Zero] aim_status[FetcherLength:`Zero];
reg [CounterLength:`Zero] cnt;
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
//下面为提交池
reg [`DataLength:`Zero] addr;
reg [`UnsignedCharLength:`Zero] char;
reg [`DataLength:`Zero] data;
reg [`DataLength:`Zero] addr_iq;

reg is_stall;
reg is_past;
reg is_start;
reg is_instr;
reg is_store;
reg is_finish;
reg test;
reg [`DataLength:`Zero] testAddr;
reg [`UnsignedCharLength:`Zero] testchar;
integer i;
always @(posedge rst) begin
    is_stall <= 0;
    is_instr <= 0;
    is_store <= 0;
    is_finish <= 0;
    is_start <= 0;
    is_past <= 0;
    cnt <= 0;
    data <= 0;
    head_pointer <= 0;
    tail_pointer <= 0;
    for(i = 0 ; i < FetcherLength; ++i) begin
        Addr[i] <= 0;
        Data[i] <= 0;
        instr_status[i] <= 0;
        store_status[i] <= 0;
    end
end
always @(posedge clk) begin
    if(is_finish == `True) begin
        is_finish <= `False;
        is_start <= `False;
        cnt <= 0;
        head_pointer <= head_pointer + 1;
    end
    else begin
        if(is_start == `False ) begin
            if(head_pointer!=tail_pointer) begin
                is_store <= store_status[head_pointer];
                addr <= Addr[head_pointer];
                is_start <= `True;
            end
        end
        else begin
            addr <= addr + 1;
            if(is_past == `False) begin
                is_past <= `True;
            end
            else begin
                if(store_status[head_pointer] == `True) begin
                    case (cnt)
                    2'b00:char = Data[head_pointer][7:0];
                    2'b01:char = Data[head_pointer][15:8];
                    2'b10:char = Data[head_pointer][23:16];
                    2'b11:char = Data[head_pointer][31:24];
                    endcase
                end
                else begin
                    case (cnt)
                    2'b00:Data[head_pointer][7:0]= data_from_ram;
                    2'b01:Data[head_pointer][15:8]= data_from_ram; 
                    2'b10:Data[head_pointer][23:16]= data_from_ram;
                    2'b11:Data[head_pointer][31:24]= data_from_ram;
                    endcase
                end
                if(aim_status[head_pointer] == cnt+2'b01) begin
                    is_instr <= instr_status[head_pointer];
                    data <= Data[head_pointer];
                    addr_iq <= Addr[head_pointer];
                    is_finish <= `True;
                    is_past <= `False;
                end
                cnt <= cnt+1;
            end
        end
    end
    if(head_pointer != tail_pointer + 5'b00001 && head_pointer != tail_pointer + 5'b00010 && head_pointer != tail_pointer + 5'b00011) begin
        is_stall <= `False;
        if(is_empty_from_iq ==`False && is_empty_from_slb == `False) begin
            Addr[tail_pointer] <= addr_from_slb;
            Data[tail_pointer] <= data_from_slb;
            instr_status[tail_pointer] <= `False;
            store_status[tail_pointer] <= is_store_from_slb;
            aim_status[tail_pointer] <= aim_from_slb;
            Addr[tail_pointer+5'b00001] <= addr_from_iq;
            instr_status[tail_pointer+5'b00001] <= `True;
            store_status[tail_pointer+5'b00001] <= `False;
            aim_status[tail_pointer+5'b00001] <= 2'b00;
            tail_pointer <= tail_pointer + 5'b00010;
        end
        else if(is_empty_from_iq ==`True && is_empty_from_slb == `False)begin
            Addr[tail_pointer] <= addr_from_slb;
            aim_status[tail_pointer] <= aim_from_slb;
            Data[tail_pointer] <= data_from_slb;
            instr_status[tail_pointer] <= `False;
            store_status[tail_pointer] <= is_store_from_slb;
            tail_pointer <= tail_pointer + 5'b00001;      
        end
        else if(is_empty_from_iq ==`False && is_empty_from_slb == `True)begin
            testAddr <= addr_from_iq;
            aim_status[tail_pointer] <= 2'b00;
            Addr[tail_pointer] <= addr_from_iq;
            instr_status[tail_pointer] <= `True;
            store_status[tail_pointer] <= `False;
            tail_pointer <= tail_pointer + 5'b00001;      
        end
    end 
    else begin
        is_stall <= `True;
    end
end
assign is_instr_to_iq = is_instr;
assign is_instr_to_slb = is_instr;
assign is_stall_to_iq = is_stall;
assign is_stall_to_slb = is_stall;
assign is_store_to_ram = is_store;
assign is_finish_to_iq = is_finish;
assign is_finish_to_slb = is_finish;
assign addr_to_ram = addr;
assign data_to_ram = char;
assign data_to_slb = data;
assign data_to_iq = data;
assign addr_to_iq = addr_iq;
endmodule