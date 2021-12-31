`include "parameters.v"


module fc #(
    parameter BufferLength = 31,
    parameter PointerLength = 4,
    parameter CntLength = 1,
    parameter RdLength = 4
)
(
    input rst,
    input is_full_from_io,
    input rdy,
    input clk,
    input is_empty_from_ic,
    input is_empty_from_slb,
    input is_exception_from_rob,
    input is_store_from_slb,
    input [`PcLength:`Zero] addr_from_ic,
    input [`UnsignedCharLength:`Zero] data_from_ram,
    input [`PcLength:`Zero] addr_from_slb,
    input [`DataLength:`Zero] data_from_slb,
    input [CntLength:`Zero] aim_from_slb,

    
    output is_commit_to_slb,
    output is_commit_to_ic,
    output is_ready_to_iq,
    output is_instr_to_slb,
    output is_instr_to_ic,
    output is_store_to_ram,
    output is_store_to_slb,
    output [`DataLength:`Zero] data_to_slb,
    output [`DataLength:`Zero] data_to_ic,
    output [`PcLength:`Zero] addr_to_ram,
    output [`UnsignedCharLength:`Zero] data_to_ram
);
reg [`DataLength:`Zero]data_storage[BufferLength:`Zero];
reg [`PcLength:`Zero] addr_storage[BufferLength:`Zero];
reg valid_status[BufferLength:`Zero];
reg [PointerLength:`Zero] comp_pointer;
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
reg [PointerLength:`Zero] dtail_pointer;
reg store_status[BufferLength:`Zero];
reg instr_status[BufferLength:`Zero];
reg [CntLength:`Zero] aim_status[BufferLength:`Zero];

reg [`UnsignedCharLength:`Zero] char;
reg [CntLength:`Zero]cnt;
reg [`PcLength:`Zero] addr; 
reg [CntLength:`Zero] aim;
reg is_finish;
reg is_instr;
reg is_commit;
reg is_start;
reg [`DataLength:`Zero] data;
reg is_store;
reg is_switch;
reg is_pass;
reg is_ready;

reg en_empty_slb;
reg en_empty_ic;
reg en_exception;
reg en_rst;
reg en_rdy;
reg en_full_io;



reg [`DataLength:`Zero] test;
reg [`DataLength:`Zero] test2;
reg [`DataLength:`Zero] test3;
reg [`DataLength:`Zero] test4;

integer i;
integer fp_w;
integer clk_num;

initial begin
    fp_w = $fopen("./store.txt","w");
    clk_num = 0;
end

always@(posedge clk) begin
    clk_num = clk_num + 1;
    en_rst = rst;
    en_rdy = rdy;
    en_empty_ic = is_empty_from_ic;
    en_empty_slb = is_empty_from_slb;
    en_exception = is_exception_from_rob;
    en_full_io = is_full_from_io;
    if(en_rst == `True) begin
        tail_pointer <= 0;
        head_pointer <= 0;
        is_finish <= `False;
        is_start <= `False;
        is_ready <= `True;
        is_switch <= `False;
    end
    else if(en_rdy == `False) begin
        
    end
    else begin
        if(en_exception == `True) begin
            for(i = 0 ; i<= BufferLength;i = i + 1) begin
                if(store_status[i] == `False) valid_status[i] <= `False;
            end
        end

            //提交
            if(is_finish == `True ) begin
                if(valid_status[head_pointer] == `True) is_commit <= `True;
                else is_commit <= `False;
                addr <= 0;
                is_finish <= `False;
                data <= data_storage[head_pointer];
                is_store <= store_status[head_pointer];
                is_instr <= instr_status[head_pointer];
                head_pointer <= head_pointer+1;
            end
            if(is_commit == `True) is_commit <=`False;
            
            if(head_pointer != tail_pointer) begin
                if(is_start == `False  && is_finish == `False) is_start <= `True;
                else if(is_start == `True) begin
                    if(is_switch == `False && is_start == `True)begin
                        is_store <= store_status[head_pointer];
                        if(store_status[head_pointer] == `False) addr <= addr_storage[head_pointer];
                        else addr <= 0;
                        is_switch <= `True;
                        aim <= aim_status[head_pointer];
                        cnt <= 0;
                        char <= 0;
                        is_pass <= `False;
                   end 
                    else if(is_start == `True) begin
                        if(is_store == `True) begin
                            if(addr == 0) addr <= addr_storage[head_pointer];
                            if(addr[17:16] == 2'b11 && en_full_io == `True) begin
                                $display(addr);
                             end
                            else begin
                                if(addr != 0 && addr[17:16] != 2'b11) addr <= addr + 1;
                                cnt <= cnt + 2'b01;
                                case(cnt)
                                2'b00:char <= data_storage[head_pointer][7:0];
                                2'b01:char <= data_storage[head_pointer][15:8];
                                2'b10:char <= data_storage[head_pointer][23:16];
                                2'b11:char <= data_storage[head_pointer][31:24];
                                endcase 
                                if(aim == cnt + 2'b01)begin
                                    is_start <= `False;
                                    is_finish <= `True;
                                    is_switch <= `False;
                                end
                            end
                        end
                        else begin
                            addr <= addr + 1;
                            if(is_pass == `False) is_pass <= `True;
                            else begin
                                test = data_from_ram;
                                case(cnt)
                                    2'b00:data_storage[head_pointer][7:0] <= data_from_ram;
                                    2'b01:data_storage[head_pointer][15:8] <= data_from_ram; 
                                    2'b10:data_storage[head_pointer][23:16] <= data_from_ram;
                                    2'b11:data_storage[head_pointer][31:24] <= data_from_ram;
                                endcase 
                                if(aim == cnt + 2'b01)begin
                                    is_start <= `False;
                                    is_finish <= `True;
                                    is_switch <= `False;
                                    addr <= 0;
                                end
                                cnt <= cnt + 2'b01;
                            end
                        end
                    end
                end
            end
           
            if(head_pointer != tail_pointer + 5'b00001 && head_pointer != tail_pointer + 5'b00010 && head_pointer != tail_pointer + 5'b00011 ) is_ready <= `True;
            else is_ready <= `False;
            if(en_empty_slb == `False && en_empty_ic == `False) begin
 
                   dtail_pointer = tail_pointer + 5'b00001;
                   
                    instr_status[tail_pointer] <= `False;
                    aim_status[tail_pointer] <= aim_from_slb;
                    addr_storage[tail_pointer] <= addr_from_slb;
                    data_storage[tail_pointer] <= data_from_slb;
                    store_status[tail_pointer] <= is_store_from_slb;
                    if(en_exception == `False) valid_status[tail_pointer] <= `True;
                    else valid_status[tail_pointer] <= `False;

                    instr_status[dtail_pointer] <= `True;
                    aim_status[dtail_pointer] <= 2'b00;
                    addr_storage[dtail_pointer] <= addr_from_ic;
                    store_status[dtail_pointer] <= `False;
                    if(en_exception == `False) valid_status[dtail_pointer] <= `True;
                    else valid_status[dtail_pointer] <= `False;

                    tail_pointer <= tail_pointer + 5'b00010;
            end
            else if(en_empty_slb == `True && en_empty_ic == `False) begin
                    instr_status[tail_pointer] <= `True;
                    aim_status[tail_pointer] <= 2'b00;
                    addr_storage[tail_pointer] <= addr_from_ic;
                    store_status[tail_pointer] <= `False;
                    if(en_exception == `False) valid_status[tail_pointer] <= `True;
                    else valid_status[tail_pointer] <= `False;
                    tail_pointer <= tail_pointer + 5'b00001;

            end
            else if(en_empty_slb == `False && en_empty_ic == `True ) begin

                    instr_status[tail_pointer] <= `False;
                    aim_status[tail_pointer] <= aim_from_slb;
                    addr_storage[tail_pointer] <= addr_from_slb;
                    data_storage[tail_pointer] <= data_from_slb;
                    
                    store_status[tail_pointer] <= is_store_from_slb;
                    if(en_exception == `False) valid_status[tail_pointer] <= `True;
                    else valid_status[tail_pointer] <= `False;
                    tail_pointer <= tail_pointer + 5'b00001;
            end
            //更新
    end
end

assign is_commit_to_slb = is_commit;
assign is_commit_to_ic = is_commit;
assign is_ready_to_iq = is_ready;
assign is_instr_to_slb = is_instr;
assign is_instr_to_ic = is_instr;
assign data_to_slb = data;
assign data_to_ic = data;
assign is_store_to_ram = is_store;
assign is_store_to_slb = is_store;
assign addr_to_ram = addr;
assign data_to_ram = char;

endmodule