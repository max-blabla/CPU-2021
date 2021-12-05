`include "parameters.v"
module rf
#(
    parameter RegFileLength     =   31,
    parameter   Rs1Length       =   4,
    parameter   Rs2Length       =   4,
    parameter   RdLength        =   4
)
(
    input  wire    rst,
    input  wire    clk,
    input  wire    is_empty_from_decoder,
    input  wire    is_commit_from_rob,
    input  wire    is_exception_from_rob,
    input  wire    is_ready_from_rob,
    input  wire    is_ready_from_slb,
    input  wire    is_ready_from_rs,
    input  wire    [`PcLength:`Zero]       pc_from_rob,
    input  wire    [RdLength:`Zero]        rd_from_rob,
    input  wire    [`DataLength:`Zero]     data_from_rob,
    input  wire    [RdLength:`Zero]        rd_from_decoder,
    input  wire    [`PcLength:`Zero]       pc_from_decoder,
    input  wire    [Rs1Length:`Zero]       rs1_from_decoder,
    input  wire    [Rs2Length:`Zero]       rs2_from_decoder,
    input  wire    [`DataLength:`Zero]     imm_from_decoder,
    input  wire    [`OpcodeLength:`Zero]   op_from_decoder,
    output wire    is_empty_to_rob,
    output wire    [RdLength:`Zero]        rd_to_rob,
    output wire    [`PcLength:`Zero]       pc_to_rob,
    output wire[`DataLength:`Zero] v1_to_rs,
    output wire[`DataLength:`Zero] v2_to_rs,
    output wire[`PcLength:`Zero] q1_to_rs,
    output wire[`PcLength:`Zero] q2_to_rs,
    output wire[`DataLength:`Zero] imm_to_rs,
    output wire[`OpcodeLength:`Zero] op_to_rs,
    output wire[`DataLength:`Zero] v1_to_slb,
    output wire[`DataLength:`Zero] v2_to_slb,
    output wire[`PcLength:`Zero] q1_to_slb,
    output wire[`PcLength:`Zero] q2_to_slb,
    output wire[`DataLength:`Zero] imm_to_slb,
    output wire[`OpcodeLength:`Zero] op_to_slb,
    output wire[`DataLength:`Zero] pc_to_rs,
    output wire[`DataLength:`Zero] pc_to_slb,
    output wire is_empty_to_rs,
    output wire is_empty_to_slb,
    output wire is_sl_to_rs,
    output wire is_sl_to_slb,
    output wire is_ready_to_iq,
    output wire is_ready_to_slb,
    output wire is_ready_to_rs,
    output wire is_ready_to_rob
);
integer i;
reg [`DataLength:`Zero] RegValue [RegFileLength:`Zero];
reg [`DataLength:`Zero] RegQueue [RegFileLength:`Zero];
reg is_empty;//to 3
reg is_ready;// to 1
reg is_ready_iq;
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`DataLength:`Zero] imm;
reg [Rs1Length:`Zero] rs1;
reg [Rs2Length:`Zero] rs2;
reg [`PcLength:`Zero] q1;
reg [`PcLength:`Zero] q2;
reg [`OpcodeLength:`Zero] op;
reg [`PcLength:`Zero] pc;
reg [RdLength:`Zero] rd;
reg [`PcLength:`Zero] test1;
reg is_sl;
reg is_issue;
always @(posedge rst) begin
    for(i = 0 ; i <= RegFileLength ; i = i + 1) begin
        RegValue[i] <= 0;
        RegQueue[i] <= 0;
    end
    is_empty <= `True;
    is_issue <= `False;
    is_ready_iq <= `False;
    is_ready <= `False;
    v1 <= 0;
    v2 <= 0;
    q1 <= 0;
    q2 <= 0;
    op <= 0;
    pc <= 0;
    rd <= 0;
end
always @(posedge clk) begin
    //先判断是否完成
//完成了的话:rob写入，再清空发空
//再rs读取
//再rd写入
    if(is_exception_from_rob) begin
        if(rd_from_rob != 0) begin
            RegValue[rd_from_rob] <= data_from_rob;
        end
        for(i = 0 ;i <= RegFileLength ; i = i + 1) begin
             RegQueue[i] <= 0;
        end
        is_empty <= `True;
         is_ready_iq <= `False;
         is_ready <= `False;
             is_issue <= `False;
        v1 <= 0;
        v2 <= 0;
        q1 <= 0;
        q2 <= 0;
        op <= 0;
        rd <= 0;
        pc <= 0;
        rs1 <= 0;
        rs2 <= 0;
    end
    else begin
        test1 = RegQueue[1];
        if(is_commit_from_rob) begin
            if(pc_from_rob == 8) begin
           //     $display("%s:%d","Answer",RegValue[rd_from_rob]);
            end

            if(RegQueue[rd_from_rob] == pc_from_rob) begin
                RegQueue[rd_from_rob] = 0;
            end
            RegValue[rd_from_rob] = data_from_rob;
        end
        if(is_ready_from_rob == `True && is_ready_from_rs == `True && is_ready_from_slb == `True && is_empty == `False) begin
            is_ready_iq <= `True;
            is_ready <= `True;
            is_empty <= `True;
            v1 <= RegValue[rs1];
            v2 <= RegValue[rs2];
            q1 <= RegQueue[rs1];
            q2 <= RegQueue[rs2];
        end
        if(is_ready == `True)begin 
            is_ready <= `False;
            is_ready_iq <= `False;
        end
        if(is_empty_from_decoder == `False) begin
            if(rd_from_decoder != 0) begin
                RegQueue[rd_from_decoder] <= pc_from_decoder;
            end
            imm <= imm_from_decoder;
            rd <= rd_from_decoder;
            pc <= pc_from_decoder;
            op <= op_from_decoder;
            rs1 <= rs1_from_decoder;
            rs2 <= rs2_from_decoder;
            is_empty <= `False;
            is_ready_iq <= `False;
            case(op_from_decoder) 
                `SB,`SW,`SH,`LH,`LW,`LB,`LBU,`LHU:begin
                    is_sl <= `True;
                end
            default:begin
                    is_sl <= `False;
                end
            endcase
        end
    end
end
assign is_empty_to_rob = is_empty;
assign is_ready_to_iq = is_ready_iq;
assign is_ready_to_rob = is_ready;
assign is_ready_to_rs = is_ready;
assign is_ready_to_slb = is_ready;
assign pc_to_rob = pc;
assign rd_to_rob = rd;
assign v1_to_rs = v1;
assign v2_to_rs = v2;
assign q1_to_rs = q1;
assign q2_to_rs = q2;
assign imm_to_rs= imm;
assign op_to_rs = op;
assign v1_to_slb= v1;
assign v2_to_slb= v2;
assign q1_to_slb= q1;
assign q2_to_slb= q2;
assign imm_to_slb= imm;
assign op_to_slb= op;
assign pc_to_rs = pc;
assign pc_to_slb = pc;
assign is_empty_to_rs = is_empty;
assign is_empty_to_slb = is_empty;
assign is_sl_to_rs = is_sl;
assign is_sl_to_slb = is_sl;
endmodule