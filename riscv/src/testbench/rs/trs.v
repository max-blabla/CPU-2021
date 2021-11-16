`include "parameters.v"
`timescale  1ns / 1ps

module tb_rs;        

// rs Parameters
parameter PERIOD    = 10;
parameter RsLength  = 7;

// rs Inputs
reg   rst_n                                  = 0 ;
reg   clk                                  = 0 ;
reg   is_empty_from_rob                    = 0 ;
reg   is_sl_from_rob                       = 0 ;
reg   is_exception_from_rob                = 0 ;
reg   is_commit_from_rob                   = 0 ;
reg   [`OpcodeLength:`Zero] op_from_rob = 0 ;
reg   [`DataLength:`Zero] v1_from_rob  = 0 ;
reg   [`DataLength:`Zero] v2_from_rob  = 0 ;
reg   [`PcLength:`Zero] q1_from_rob    = 0 ;
reg   [`PcLength:`Zero] q2_from_rob    = 0 ;
reg   [`DataLength:`Zero] imm_from_rob = 0 ;
reg   [`DataLength:`Zero] pc_from_rob  = 0 ;
reg   [`DataLength:`Zero] commit_data_from_rob = 0 ;
reg   [`PcLength:`Zero] commit_pc_from_rob = 0 ;

// rs Outputs
wire  [`OpcodeLength:`Zero] op_to_alu  ;
wire  [`DataLength:`Zero] v1_to_alu    ;
wire  [`DataLength:`Zero] v2_to_alu    ;
wire  [`DataLength:`Zero] imm_to_alu   ;
wire  [`DataLength:`Zero] pc_to_alu    ;
wire  is_stall_to_instr_queue              ;
wire  is_stall_to_rob                      ;


initial
begin
    #(PERIOD*2) rst_n  =  1;
    forever begin
        #(PERIOD/2)  clk=~clk;
        if(clk) begin 
          //  is_empty_from_rob = 1;
         //   pc_from_rob = pc_from_rob + 4;
          //  op_from_rob = op_from_rob + 1;
        end
    end
end



rs #(
    .RsLength ( RsLength ))
 u_rs (
    .rst                                           ( rst_n                                          ),
    .clk                                           ( clk                                            ),
    .is_empty_from_rob                             ( is_empty_from_rob                              ),
    .is_sl_from_rob                                ( is_sl_from_rob                                 ),
    .is_exception_from_rob                         ( is_exception_from_rob                          ),
    .is_commit_from_rob                            ( is_commit_from_rob                             ),
    .op_from_rob         ( op_from_rob          ),
    .v1_from_rob           (v1_from_rob            ),
    .v2_from_rob           ( v2_from_rob            ),
    .q1_from_rob             ( q1_from_rob              ),
    .q2_from_rob             ( q2_from_rob              ),
    .imm_from_rob          ( imm_from_rob           ),
    .pc_from_rob           ( pc_from_rob            ),
    .commit_data_from_rob  ( commit_data_from_rob   ),
    .commit_pc_from_rob      ( commit_pc_from_rob       ),

    .op_to_alu           (  op_to_alu            ),
    .v1_to_alu             ( v1_to_alu              ),
    .v2_to_alu             ( v2_to_alu              ),
    .imm_to_alu            ( imm_to_alu             ),
    .pc_to_alu             ( pc_to_alu              ),
    .is_stall_to_instr_queue                       ( is_stall_to_instr_queue                        ),
    .is_stall_to_rob                               ( is_stall_to_rob                                )
);

initial
begin
    $dumpfile("test.vcd");
    $dumpvars(0,tb_rs);
    #100
    $finish;
end

endmodule
module rs
#(
    parameter RsLength = 7
)
(
    input wire rst,
    input wire clk,
    input wire is_empty_from_rob,
    input wire is_sl_from_rob,
    input wire is_exception_from_rob,
    input wire is_commit_from_rob,
    input wire[`OpcodeLength:`Zero] op_from_rob,
    input wire[`DataLength:`Zero] v1_from_rob,
    input wire[`DataLength:`Zero] v2_from_rob,
    input wire[`PcLength:`Zero] q1_from_rob,
    input wire[`PcLength:`Zero] q2_from_rob,
    input wire[`DataLength:`Zero] imm_from_rob,
    input wire[`DataLength:`Zero] pc_from_rob,
    input wire[`DataLength:`Zero] commit_data_from_rob,
    input wire[`PcLength:`Zero] commit_pc_from_rob,
    output wire[`OpcodeLength:`Zero] op_to_alu,
    output wire[`DataLength:`Zero] v1_to_alu,
    output wire[`DataLength:`Zero] v2_to_alu,
    output wire[`DataLength:`Zero] imm_to_alu,
    output wire[`DataLength:`Zero] pc_to_alu,
    output wire is_stall_to_instr_queue,
    output wire is_stall_to_rob
);
reg [`DataLength:`Zero] Value1[RsLength:`Zero];
reg [`DataLength:`Zero] Value2[RsLength:`Zero];
reg [`PcLength:`Zero] Queue1[RsLength:`Zero];
reg [`PcLength:`Zero] Queue2[RsLength:`Zero];
reg [`OpcodeLength:`Zero] Op[RsLength:`Zero];
reg is_busy[RsLength:`Zero];
reg [`DataLength:`Zero] Imm[RsLength:`Zero];
reg [`PcLength:`Zero] Pc[RsLength:`Zero];


reg iis_commit;
reg iis_sl;
reg iis_exception;
reg iis_empty;
reg [`DataLength:`Zero] iv1;
reg [`DataLength:`Zero] iv2;
reg [`PcLength:`Zero] iq1;
reg [`PcLength:`Zero] iq2;
reg [`OpcodeLength:`Zero] iop;
reg [`DataLength:`Zero] iimm;
reg [`PcLength:`Zero] ipc;
reg [`DataLength:`Zero] icommit_data;
reg [`PcLength:`Zero] icommit_pc;

reg is_stall;
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`DataLength:`Zero] imm;
reg [`PcLength:`Zero] pc;
reg [`OpcodeLength:`Zero] op;
integer i;
always @(posedge rst) begin
    is_stall <= 0;
    v1 <= 0;
    v2 <= 0;
    imm <= 0;
    op <= 0;
    iis_exception <= 0;
    iv1 <= 0;
    iv2 <= 0;
    iq1 <= 0;
    iq2 <= 0;
    iis_commit <= 0;
    iis_sl <= 0;
    iis_empty <= 0;
    iop <= 0;
    iimm <= 0;
    ipc <= 0;
    icommit_data <= 0;
    icommit_pc <= 0;
    for(i = 0 ;i <= RsLength; ++i) begin
        Value1[i] <= 0;
        Value2[i] <= 0;
        Queue1[i] <= 0;
        Queue2[i] <= 0;
        is_busy[i] <= 0;
        Pc[i] <= 0;
        Imm[i] <= 0; 
    end
end
always @(posedge clk) begin
    is_stall <= 0;
    v1 <= 0;
    v2 <= 0;
    imm <= 0;
    op <= 0;
    iis_exception <= is_exception_from_rob;
    iv1 <= v1_from_rob;
    iv2 <= v2_from_rob;
    iq1 <= q1_from_rob;
    iq2 <= q2_from_rob;
    iis_commit <= is_commit_from_rob;
    iis_sl <= is_sl_from_rob;
    iis_empty <= is_empty_from_rob;
    iop <= op_from_rob;
    iimm <= imm_from_rob;
    ipc <= pc_from_rob;
    icommit_data <= commit_data_from_rob;
    icommit_pc <= commit_pc_from_rob;
end
always @(*) begin
        //判断是否清空
        $display(ipc);
        if(iis_exception) begin
            is_stall = 0;
            v1 = 0;
            v2 = 0;
            imm = 0;
            for(i = 0 ; i <= RsLength ; ++i) begin
                Value1[i] = 0;
                Value2[i] = 0;
                Queue1[i] = 0;
                Queue2[i] = 0;
                is_busy[i] = 0;
                Pc[i] = 0;
                Imm[i] = 0; 
                Op[i] = 0;
            end
        end
        else begin
            if(iis_empty == `False && iis_sl == `False) begin
                //先用rob的提交更新
                if(iis_commit) begin
                    for(i = 0 ; i <= RsLength ; ++i) begin
                        if(is_busy[i] == `True && Queue1[i] == 0 && Queue2[i] == 0) begin
                            if(Queue1[i] == icommit_pc)begin
                                Queue1[i] = 0;
                                Value1[i] = icommit_data;
                            end
                            if(Queue2[i] == icommit_pc) begin
                                Queue2[i] = 0;
                                Value2[i] = icommit_data;
                            end
                        end
                    end
                end
                //再找一遍可以发射的
                begin : loop1
                    for(i = 0 ; i <= RsLength ; ++i) begin
                        if(is_busy[i] == `True && Queue1[i] == 0 && Queue2[i] == 0) begin
                            v1 = Value1[i];
                            v2 = Value2[i];
                            imm = Imm[i];
                            pc = Pc[i];
                            op = Op[i];
                           // is_busy[i] = `False;
                            disable loop1;
                        end
                    end
                end
                //再输入新的来自rob的值
                //这里也有问题
                is_stall = `True;
                begin:loop2
                    for(i = 0 ; i <= RsLength ; ++i) begin
                        if(is_busy[i] == `False) begin
                            $display(i);
                            Pc[i] = ipc;
                            Imm[i] = iimm;
                            Value1[i] = iv1;
                            Value2[i] = iv2;
                            Queue1[i] = iq1;
                            Queue2[i] = iq2;
                            Op[i] = iop;
                            is_busy[i] = `True;
                            is_stall = `False;
                            disable loop2;
                        end
                    end
                end
                $display(is_stall);
            end
        end
end
assign v1_to_alu = v1;
assign v2_to_alu = v2;
assign imm_to_alu = imm;
assign pc_to_alu = pc;
assign is_stall_to_instr_queue = is_stall;
assign is_stall_to_rob = is_stall;
assign op_to_alu = op;
endmodule