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
    input is_empty_from_dc,
    input is_exception_from_rob,
    input is_commit_from_rob,
    input is_sl_from_dc,
    input [`PcLength:`Zero] addr_from_ic,
    input [`UnsignedCharLength:`Zero] data_from_ram,
    input [`PcLength:`Zero] pc_from_dc,
    input [`DataLength:`Zero] imm_from_dc,
    input [`OpcodeLength:`Zero] op_from_dc,
    input [`PcLength:`Zero] q1_from_rf,
    input [`PcLength:`Zero] q2_from_rf,
    input [`DataLength:`Zero] v1_from_rf,
    input [`DataLength:`Zero] v2_from_rf,
    input [`PcLength:`Zero] commit_pc_from_rob,
    input [`DataLength:`Zero] commit_data_from_rob,

    
    output is_commit_to_rob,
    output is_commit_to_ic,
    output is_ready_to_iq,
    output is_instr_to_rob,
    output is_instr_to_ic,
    output is_store_to_ram,
    output [`DataLength:`Zero] data_to_rob,
    output [`DataLength:`Zero] data_to_ic,
    output [`PcLength:`Zero] pc_to_rob,
    output [`PcLength:`Zero] addr_to_ram,
    output [`UnsignedCharLength:`Zero] data_to_ram
);
reg [`PcLength:`Zero] Pc [BufferLength:`Zero];
reg [`PcLength:`Zero] Q1 [BufferLength:`Zero];
reg [`PcLength:`Zero] Q2 [BufferLength:`Zero];
reg [`DataLength:`Zero] V1 [BufferLength:`Zero];
reg [`DataLength:`Zero] V2 [BufferLength:`Zero];
reg [`DataLength:`Zero] Imm [BufferLength:`Zero];
reg [PointerLength:`Zero] comp_pointer;
reg [PointerLength:`Zero] head_pointer;
reg [PointerLength:`Zero] tail_pointer;
reg [PointerLength:`Zero] dtail_pointer;
reg  store_status[BufferLength:`Zero];
reg instr_status[BufferLength:`Zero];
reg [CntLength:`Zero] aim_status[BufferLength:`Zero];
reg comp_status[BufferLength:`Zero];
reg [`PcLength:`Zero]pc;

reg [`UnsignedCharLength:`Zero] char;
reg [CntLength:`Zero]cnt;
reg [`PcLength:`Zero] addr; 
reg [CntLength:`Zero] aim;
reg is_finish;
reg is_instr;
reg is_start;
reg is_commit;
reg [`DataLength:`Zero] data;
reg is_store;
reg is_switch;
reg is_pass;
reg is_ready;

reg en_empty_dc;
reg en_empty_ic;
reg en_exception;
reg en_commit;
reg en_sl;
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
    en_empty_dc = is_empty_from_dc;
    en_exception = is_exception_from_rob;
    en_commit = is_commit_from_rob;
    en_sl = is_sl_from_dc;
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
            tail_pointer <= 0;
            head_pointer <= 0;
            is_finish <= `False;
            is_start <= `False;
            is_ready <= `True;
            is_switch <= `False;
        end
        else begin
            //提交
            if(is_finish == `True) begin
                addr <= 0;
                is_commit <= `True;
                is_finish <= `False;
                data <= V2[head_pointer];
                is_store <= store_status[head_pointer];
                pc <= Pc[head_pointer];
                if(instr_status[head_pointer] == `True) is_instr <= `True;
                else is_instr <= `False;
                head_pointer <= head_pointer+1;
            end
            else is_commit <= `False;

            
            if(head_pointer != tail_pointer) begin
                test3 = Q1[head_pointer];
                test2 = Q2[head_pointer];
                if(is_start == `False && Q1[head_pointer] == 0 && Q2[head_pointer] == 0 && is_finish == `False && comp_status[head_pointer] == `True) is_start <= `True;
                else if(is_start == `True) begin
                    if(is_switch == `False && is_start == `True)begin
                        is_store <= store_status[head_pointer];
                        if(store_status[head_pointer] == `False) addr <= V1[head_pointer] + {{20{Imm[head_pointer][11]}},Imm[head_pointer][11:0]};
                        else addr <= 0;
                        is_switch <= `True;
                        aim <= aim_status[head_pointer];
                        cnt <= 0;
                        char <= 0;
                        is_pass <= `False;
                        if(store_status[head_pointer] == `True) $fwrite(fp_w,"%d %d %d %d\n", clk_num ,V1[head_pointer] + {{20{Imm[head_pointer][11]}},Imm[head_pointer][11:0]} ,Pc[head_pointer],V2[head_pointer]);
                    end 
                    else if(is_start == `True) begin
                        if(is_store == `True) begin
                            if(addr == 0) addr <= V1[head_pointer] + {{20{Imm[head_pointer][11]}},Imm[head_pointer][11:0]};
                            if(addr[17:16] == 2'b11 && en_full_io == `True) begin
                                $display(addr);
                             end
                            else begin
                                if(addr != 0 && addr[17:16] != 2'b11) addr <= addr + 1;
                                cnt <= cnt + 2'b01;
                                case(cnt)
                                2'b00:char <= V2[head_pointer][7:0];
                                2'b01:char <= V2[head_pointer][15:8];
                                2'b10:char <= V2[head_pointer][23:16];
                                2'b11:char <= V2[head_pointer][31:24];
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
                                    2'b00:V2[head_pointer][7:0] <= data_from_ram;
                                    2'b01:V2[head_pointer][15:8] <= data_from_ram; 
                                    2'b10:V2[head_pointer][23:16] <= data_from_ram;
                                    2'b11:V2[head_pointer][31:24] <= data_from_ram;
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
            if(comp_status[comp_pointer] == `False) begin
                if(q1_from_rf == commit_pc_from_rob && q1_from_rf != 0 ) begin
                    V1[comp_pointer] <= commit_data_from_rob;
                    Q1[comp_pointer] <= 0;
                end
                else begin
                    V1[comp_pointer] <= v1_from_rf;
                    Q1[comp_pointer] <= q1_from_rf;
                end
                if(q2_from_rf == commit_pc_from_rob && q2_from_rf != 0 ) begin
                    V2[comp_pointer] <= commit_data_from_rob;
                    Q2[comp_pointer] <= 0;
                end
                else begin
                    test4 <= q2_from_rf;
                    V2[comp_pointer] <= v2_from_rf;
                    Q2[comp_pointer] <= q2_from_rf;
                end
                comp_status[comp_pointer] <= `True;
            end
            if(head_pointer != tail_pointer + 5'b00001 && head_pointer != tail_pointer + 5'b00010 && head_pointer != tail_pointer + 5'b00011 ) is_ready <= `True;
            else is_ready <= `False;
            if(en_empty_dc == `False && en_empty_ic == `False && en_sl == `True) begin
                dtail_pointer = tail_pointer + 5'b00001;
                    case(op_from_dc)
                        `LW:begin
                            aim_status[tail_pointer] <= 2'b00;
                            store_status[tail_pointer] <= `False;
                        end 
                        `LH:begin
                            aim_status[tail_pointer] <= 2'b10;
                            store_status[tail_pointer] <= `False;
                        end 
                        `LB:begin
                            aim_status[tail_pointer] <= 2'b01;
                            store_status[tail_pointer] <= `False;
                        end 
                        `LBU:begin
                            aim_status[tail_pointer] <= 2'b01;
                            store_status[tail_pointer] <= `False;
                        end 
                        `LHU:begin
                            aim_status[tail_pointer] <= 2'b10;
                            store_status[tail_pointer] <= `False;
                        end 
                        `SW:begin
                            aim_status[tail_pointer] <= 2'b00;
                            store_status[tail_pointer] <= `True;
                        end 
                        `SB:begin
                            aim_status[tail_pointer] <= 2'b01;
                            store_status[tail_pointer] <= `True;
                        end 
                        `SH:begin
                            aim_status[tail_pointer] <= 2'b10;
                            store_status[tail_pointer] <= `True;
                        end 
                    endcase
                    
                    comp_pointer <= tail_pointer;
                    Pc[tail_pointer] <= pc_from_dc;
                    Imm[tail_pointer] <= imm_from_dc;
                    comp_status[tail_pointer] <= `False;
                    instr_status[tail_pointer] <= `False;

                    Pc[dtail_pointer] <= addr_from_ic;
                    V1[dtail_pointer] <= addr_from_ic;
                    Q1[dtail_pointer] <= 0;
                    V2[dtail_pointer] <= 0;
                    Q2[dtail_pointer] <= 0;
                    Imm[dtail_pointer] <= 0;
                    instr_status[dtail_pointer] <= `True;
                    comp_status[dtail_pointer] <= `True;
                    aim_status[dtail_pointer] <= 2'b00;
                    store_status[dtail_pointer] <= `False;
                    tail_pointer <= tail_pointer + 5'b00010;
                end
                else if((en_empty_dc == `True && en_empty_ic == `False)||(en_empty_dc==`False && en_empty_ic == `False && en_sl == `False)) begin
                    Pc[tail_pointer] <= addr_from_ic;
                    V1[tail_pointer] <= addr_from_ic;
                    Q1[tail_pointer] <= 0;
                    V2[tail_pointer] <= 0;
                    Q2[tail_pointer] <= 0;
                    Imm[tail_pointer] <= 0;
                    instr_status[tail_pointer] <= `True;
                    comp_status[tail_pointer] <= `True;
                    aim_status[tail_pointer] <= 2'b00;
                    store_status[tail_pointer] <= `False;
                    tail_pointer <= tail_pointer + 5'b00001;
                end
                else if(en_empty_dc == `False && en_empty_ic == `True && en_sl == `True) begin
                    case(op_from_dc)
                        `LW:begin
                            aim_status[tail_pointer] <= 2'b00;
                            store_status[tail_pointer] <= `False;
                        end 
                        `LH:begin
                            aim_status[tail_pointer] <= 2'b10;
                            store_status[tail_pointer] <= `False;
                        end 
                        `LB:begin
                            aim_status[tail_pointer] <= 2'b01;
                            store_status[tail_pointer] <= `False;
                        end 
                        `LBU:begin
                            aim_status[tail_pointer] <= 2'b01;
                            store_status[tail_pointer] <= `False;
                        end 
                        `LHU:begin
                            aim_status[tail_pointer] <= 2'b10;
                            store_status[tail_pointer] <= `False;
                        end 
                        `SW:begin
                            aim_status[tail_pointer] <= 2'b00;
                            store_status[tail_pointer] <= `True;
                        end 
                        `SB:begin
                            aim_status[tail_pointer] <= 2'b01;
                            store_status[tail_pointer] <= `True;
                        end 
                        `SH:begin
                            aim_status[tail_pointer] <= 2'b10;
                            store_status[tail_pointer] <= `True;
                        end 
                    endcase
                    instr_status[tail_pointer] <= `False;
                    comp_pointer <= tail_pointer;
                    Pc[tail_pointer] <= pc_from_dc;
                    Imm[tail_pointer] <= imm_from_dc;
                    comp_status[tail_pointer] <= `False;
                    tail_pointer <= tail_pointer + 5'b00001;
                end
            //更新
            if(en_commit == `True) begin
                for(i = 0 ; i <= BufferLength ; i = i + 1 ) begin
                    if(Q1[i] == commit_pc_from_rob && Q1[i] != 0)begin
                        V1[i] <= commit_data_from_rob;
                        Q1[i] <= 0;
                    end 
                    if(Q2[i] == commit_pc_from_rob && Q2[i] != 0)begin
                        V2[i] <= commit_data_from_rob;
                        Q2[i] <= 0;
                    end 
                end
            end
        end
    end
end

assign is_commit_to_rob = is_commit;
assign is_commit_to_ic = is_commit;
assign is_ready_to_iq = is_ready;
assign is_instr_to_rob = is_instr;
assign is_instr_to_ic = is_instr;
assign data_to_rob = data;
assign data_to_ic = data;
assign is_store_to_ram = is_store;
assign pc_to_rob = pc;
assign addr_to_ram = addr;
assign data_to_ram = char;

endmodule