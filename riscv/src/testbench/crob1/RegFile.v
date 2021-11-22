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
    input  wire    is_finish_from_rob,
    input  wire    is_exception_from_rob,
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
    output wire    [`DataLength:`Zero]     imm_to_rob,
    output wire    [`DataLength:`Zero]     v1_to_rob,
    output wire    [`DataLength:`Zero]     v2_to_rob,
    output wire    [`PcLength:`Zero]       q1_to_rob,
    output wire    [`PcLength:`Zero]       q2_to_rob,
    output wire    [`OpcodeLength:`Zero]   op_to_rob,
    output wire    [`PcLength:`Zero]       pc_to_rob
);
integer i;
reg [`DataLength:`Zero] RegValue [RegFileLength:`Zero];
reg [`DataLength:`Zero] RegQueue [RegFileLength:`Zero];
reg is_empty;
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`PcLength:`Zero] q1;
reg [`PcLength:`Zero] q2;
reg [`OpcodeLength:`Zero] op;
reg [`PcLength:`Zero] pc;
always @(posedge rst) begin
    for(i = 0 ; i < RegFileLength ; ++i) begin
        RegValue[i] <= 0;
        RegQueue[i] <= 0;
    end
    is_empty <= `True;
    v1 <= 0;
    v2 <= 0;
    q1 <= 0;
    q2 <= 0;
    op <= 0;
    pc <= 0;
end
always @(posedge clk) begin
    //先判断是否完成
//完成了的话:rob写入，再清空发空
//再rs读取
//再rd写入
    if(is_exception_from_rob) begin
        if(rd_from_decoder != 0) begin
            RegValue[rd_from_decoder] <= data_from_rob;
        end
        for(i = 0 ;i <= RegFileLength ; ++i) begin
             RegQueue[i] <= 0;
        end
        is_empty <= `True;
        v1 <= 0;
        v2 <= 0;
        q1 <= 0;
        q2 <= 0;
        op <= 0;
        pc <= 0;
    end
    else begin
        if(is_empty_from_decoder == `False) begin
            if(is_finish_from_rob) begin
                if(RegQueue[rd_from_rob] == pc_from_rob) begin
                    RegQueue[rd_from_rob] = 0;
                end
                RegValue[rd_from_rob] = data_from_rob;
            end
            if(rd_from_decoder != 0) begin
                RegQueue[rd_from_decoder] <= pc_from_decoder;
            end
            v1 <= RegValue[rs1_from_decoder];
            v2 <= RegValue[rs2_from_decoder];
            q1 <= RegQueue[rs1_from_decoder];
            q2 <= RegQueue[rs2_from_decoder];
            pc <= pc_from_decoder;
            op <= op_from_decoder;
            is_empty <= `False;
        end
        else begin
            is_empty <= `True;
        end
    end
end
assign v1_to_rob = v1;
assign v2_to_rob = v2;
assign q1_to_rob = q1;
assign q2_to_rob = q2;
assign imm_to_rob = imm_from_decoder;
assign is_empty_to_rob = is_empty;
assign pc_to_rob = pc;
assign op_to_rob = op;
endmodule