`include "parameters.v"
module rf
#(
    parameter RegFileLength     =   31,
    parameter   OpcodeLength    =   6,
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
    input  wire    is_stall_from_rob,
    input  wire    [`PcLength:`Zero]       pc_from_rob,
    input  wire    [RdLength:`Zero]        rd_from_rob,
    input  wire    [`DataLength:`Zero]     data_from_rob,
    input  wire    [RdLength:`Zero]        rd_from_decoder,
    input  wire    [`PcLength:`Zero]       pc_from_decoder,
    input  wire    [Rs1Length:`Zero]       rs1_from_decoder,
    input  wire    [Rs2Length:`Zero]       rs2_from_decoder,
    input  wire    [`DataLength:`Zero]     imm_from_decoder,
    output wire    is_empty_to_rob,
    output wire    is_stall_to_instr_queue,
    output wire    [`DataLength:`Zero]     imm_to_rob,
    output wire    [`PcLength:`Zero]       pc_to_rob,
    output wire    [`DataLength:`Zero]     v1_to_rob,
    output wire    [`DataLength:`Zero]     v2_to_rob,
    output wire    [`PcLength:`Zero]       q1_to_rob,
    output wire    [`PcLength:`Zero]       q2_to_rob
);
integer i;
reg [`DataLength:`Zero] RegValue [RegFileLength:`Zero];
reg [`DataLength:`Zero] RegQueue [RegFileLength:`Zero];
reg is_empty;
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`PcLength:`Zero] q1;
reg [`PcLength:`Zero] q2;
always @(posedge rst) begin
    for(i = 0 ; i < RegFileLength ; ++i) begin
        RegValue[i] <= 0;
        RegQueue[i] <= 0;
    end
    is_empty <= 0;
    v1 <= 0;
    v2 <= 0;
    q1 <= 0;
    q2 <= 0;
end
always @(posedge clk) begin
    //先判断是否完成
//完成了的话:rob写入，再清空发空
//再rs读取
//再rd写入
    if(!is_empty_from_decoder) begin
            if(is_exception_from_rob) begin
                    RegValue[rd_from_decoder] = data_from_rob;
                    RegValue[0] = 0;
                    for(i = 0 ;i < RegFileLength ; ++i) begin
                        RegQueue[i] = 0;
                    end
                    is_empty = `True;
                end
            else begin
                if(is_finish_from_rob) begin
                    //阻塞赋值 存疑
                    //if 语句并行情况 存疑
                    RegValue[rd_from_rob] = data_from_rob;
                    RegValue[0] = 0;
                    //像这里就有问题
                    if(RegQueue[rd_from_rob] == pc_from_rob) begin
                        RegQueue[rd_from_rob] = 0;
                    end
                    if(!is_stall_from_rob) begin
                        RegQueue[rd_from_decoder] = pc_from_decoder;
                        RegQueue[0] = 0;
                        v1 = RegValue[rs1_from_decoder];
                        v2 = RegValue[rs2_from_decoder];
                        q1 = RegQueue[rs1_from_decoder];
                        q2 = RegQueue[rs2_from_decoder];
                    end
                end
                else begin
                    if(!is_stall_from_rob) begin
                        RegQueue[rd_from_decoder] = pc_from_decoder;
                        RegQueue[0] = 0;
                        v1 = RegValue[rs1_from_decoder];
                        v2 = RegValue[rs2_from_decoder];
                        q1 = RegQueue[rs1_from_decoder];
                        q2 = RegQueue[rs2_from_decoder];
                    end
                end
              
                is_empty = `False;
            end
        end
        else begin
            is_empty = `True;
        end
end
assign v1_to_rob = v1;
assign v2_to_rob = v2;
assign q1_to_rob = q1;
assign q2_to_rob = q2;
assign imm_to_rob = imm_from_decoder;
assign is_empty_to_rob = is_empty;
assign pc_to_rob = pc_from_decoder;

endmodule