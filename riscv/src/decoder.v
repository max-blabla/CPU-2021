`include "parameters.v"
module dc
#
(
    parameter   OpcodeLength    =   6,
    parameter   Rs1Length       =   4,
    parameter   Rs2Length       =   4,
    parameter   RdLength        =   4
)
(
    input   wire    rst,
    input   wire    is_empty_from_instr_queue,
    input   wire    [`PcLength:`Zero]       pc_from_instr_queue,
    input   wire    [`InstrLength:`Zero]    instr_from_instr_queue,


    output  wire    is_empty_to_reg,
    output  wire    [RdLength:`Zero]        rd_to_reg,
    output  wire    [`PcLength:`Zero]       pc_to_reg,
    output  wire    [Rs1Length:`Zero]       rs1_to_reg,
    output  wire    [Rs2Length:`Zero]       rs2_to_reg,
    output  wire    [`DataLength:`Zero]       imm_to_reg
);
reg     [RdLength:`Zero]    rd;
reg     [`PcLength:`Zero]   pc;
reg     [Rs1Length:`Zero]   rs1;
reg     [Rs2Length:`Zero]   rs2;
reg     [`DataLength:`Zero]   imm;

always @(posedge rst)begin
    pc  <= 0;
    rs1 <= 0; 
    rs2 <= 0;
    rd  <= 0;
    imm <= 0;
end

always @(instr_from_instr_queue) begin

end

assign  pc_to_reg   =   pc;
assign  rs1_to_reg  =   rs1;
assign  rs2_to_reg  =   rs2;
assign  rd_to_reg   =   rd;
assign  imm_to_reg  =   imm;
assign  is_empty_from_to_reg    =  is_empty_from_instr_queue;
endmodule