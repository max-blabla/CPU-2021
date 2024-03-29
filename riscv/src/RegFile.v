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
    input  wire    rdy,
    input  wire    is_empty_from_decoder,
    input  wire    is_commit_from_rob,
    input  wire    is_exception_from_rob,
    input  wire    [`PcLength:`Zero]       pc_from_rob,
    input  wire    [RdLength:`Zero]        rd_from_rob,
    input  wire    [`DataLength:`Zero]     data_from_rob,
    input  wire    [RdLength:`Zero]        rd_from_decoder,
    input  wire    [`PcLength:`Zero]       pc_from_decoder,
    input  wire    [Rs1Length:`Zero]       rs1_from_decoder,
    input  wire    [Rs2Length:`Zero]       rs2_from_decoder,

    output wire[`DataLength:`Zero] v1_to_rs,
    output wire[`DataLength:`Zero] v2_to_rs,
    output wire[`PcLength:`Zero] q1_to_rs,
    output wire[`PcLength:`Zero] q2_to_rs,
    output wire[`DataLength:`Zero] v1_to_slb,
    output wire[`DataLength:`Zero] v2_to_slb,
    output wire[`PcLength:`Zero] q1_to_slb,
    output wire[`PcLength:`Zero] q2_to_slb,
    output wire[`DataLength:`Zero] pc_to_rs
);
integer i;
reg [`DataLength:`Zero] RegValue [RegFileLength:`Zero];
reg [`DataLength:`Zero] RegQueue [RegFileLength:`Zero];
reg [`DataLength:`Zero] v1;
reg [`DataLength:`Zero] v2;
reg [`PcLength:`Zero] q1;
reg [`PcLength:`Zero] q2;
reg [`PcLength:`Zero] pc;
reg [RdLength:`Zero] rd;
//reg en_empty;
//reg en_commit;
//reg en_exception;
//reg en_rst;
//reg en_rdy;

always @(posedge clk) begin

    if(rst == `True) begin
        for(i = 0 ; i <= RegFileLength ; i = i + 1) begin
            RegValue[i] <= 0;
            RegQueue[i] <= 0;
        end
        v1 <= 0;
        v2 <= 0;
        q1 <= 0;
        q2 <= 0;
        pc <= 0;
        rd <= 0;
    end
    else if(rdy == `False) begin
        
    end
    else begin
        if(is_exception_from_rob == `True) begin
            if(rd_from_rob != 0 && is_commit_from_rob == `True) begin
                RegValue[rd_from_rob] <= data_from_rob;
            end
            for(i = 0 ;i <= RegFileLength ; i = i + 1) begin
                RegQueue[i] <= 0;
            end
            v1 <= 0;
            v2 <= 0;
            q1 <= 0;
            q2 <= 0;
            rd <= 0;
            pc <= 0;
        end
        else begin
            if(is_commit_from_rob == `True) begin
                if(RegQueue[rd_from_rob] == pc_from_rob && rd_from_rob != 0 )
                if((is_empty_from_decoder == `True && rd_from_decoder == rd_from_rob)||rd_from_decoder != rd_from_rob)
                 RegQueue[rd_from_rob] <= 0;
                if(rd_from_rob != 0) RegValue[rd_from_rob] = data_from_rob;
            end
            if(is_empty_from_decoder == `False) begin
                if(rd_from_decoder != 0) begin
                    RegQueue[rd_from_decoder] <= pc_from_decoder;
                end
                rd <= rd_from_decoder;
                pc <= pc_from_decoder;
                v1 <= RegValue[rs1_from_decoder];
                v2 <= RegValue[rs2_from_decoder];
                if(is_commit_from_rob == `True && RegQueue[rs1_from_decoder] == pc_from_rob ) q1 <= 0;
                else q1 <= RegQueue[rs1_from_decoder];
                if(is_commit_from_rob == `True && RegQueue[rs2_from_decoder] == pc_from_rob ) q2 <= 0;
                else q2 <= RegQueue[rs2_from_decoder];
               // q2 <= RegQueue[rs2_from_decoder];
            end
        end
    end
end

assign pc_to_rob = pc;
assign rd_to_rob = rd;
assign v1_to_rs = v1;
assign v2_to_rs = v2;
assign q1_to_rs = q1;
assign q2_to_rs = q2;
assign v1_to_slb= v1;
assign v2_to_slb= v2;
assign q1_to_slb= q1;
assign q2_to_slb= q2;
assign pc_to_rs = pc;
endmodule