`include "parameters.v"
module dc
#
(
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
    output  wire    is_empty_to_rob,
    output  wire    is_empty_to_rs,
    output  wire    is_empty_to_fc,
    output  wire    is_sl_to_fc,
    output  wire    is_sl_to_rs,
    output  wire    [RdLength:`Zero]        rd_to_reg,
    output  wire    [`PcLength:`Zero]       pc_to_reg,
    output  wire    [Rs1Length:`Zero]       rs1_to_reg,
    output  wire    [Rs2Length:`Zero]       rs2_to_reg,
    output  wire    [`DataLength:`Zero]     imm_to_fc,
    output  wire    [`OpcodeLength:`Zero]   op_to_fc,
    output  wire    [`PcLength:`Zero]       pc_to_fc,
    output  wire    [RdLength:`Zero]        rd_to_rob,
    output  wire    [`PcLength:`Zero]       pc_to_rob,
    output  wire    [`OpcodeLength:`Zero]   op_to_rob,
    output  wire    [`DataLength:`Zero]     imm_to_rs,
    output  wire    [`OpcodeLength:`Zero]   op_to_rs,
    output  wire    [`PcLength:`Zero]       pc_to_rs
);
reg     [RdLength:`Zero]    rd;
reg     [`PcLength:`Zero]   pc;
reg     [Rs1Length:`Zero]   rs1;
reg     [Rs2Length:`Zero]   rs2;
reg     is_sl;
reg     [`OpcodeLength:`Zero]  op;
reg     [`DataLength:`Zero]   imm;
reg     [`DataLength:`Zero]   instr;

always @(*) begin
    if(rst == `False) begin
        instr = instr_from_instr_queue;
        rs1 = instr[19:15];
        rs2 = 0;
        imm = 0;
        pc = pc_from_instr_queue;
        rd = instr[11:7];
        case (instr[6:0])
        7'b0110111 : begin
            is_sl = `False;
            op = `LUI;
            imm = instr[31:12]; 
            rs1 = 0;
        end
        7'b0010111 : begin
            is_sl = `False;
            op = `AUIPC;
            imm = instr[31:12];
            rs1 = 0;
        end
        7'b1101111 : begin
            is_sl = `False;
            op = `JAL;
            rs1 = 0;
            imm[20] = instr[31];imm[10:1] = instr[30:21];imm[11]=instr[20];imm[19:12]=instr[19:12];
        end
        7'b1100111 : begin
            is_sl = `False;
            op = `JALR;
            imm[11:0] = instr[31:20];
        end
        7'b1100011 : begin
        is_sl = `False;
        rd  = 0;
        rs2 = instr[24:20];
        imm[12] = instr[31];imm[10:5]=instr[30:25];imm[4:1]=instr[11:8];imm[11]=instr[7];
        //  $display(rs2);
        //  $display(rs1);
        //  $display(rd);
        case (instr[14:12])
        3'b000: op = `BEQ;
        3'b001: op = `BNE;
        3'b100: op = `BLT;
        3'b101: op = `BGE;
        3'b110: op = `BLTU;
        3'b111: op = `BGEU;
        endcase
        end
        7'b0000011 : begin
            is_sl = `True;
            imm[11:0] = instr[31:20];
            case(instr[14:12])
            3'b000: op = `LB;
            3'b001: op = `LH;
            3'b010: op = `LW;
            3'b100: op = `LBU;
            3'b101: op = `LHU;
            endcase
        end
        7'b0100011 : begin
            is_sl = `True;
            rd = 0;
            rs2 = instr[24:20];
            imm[4:0] = instr[11:7];imm[11:5] = instr[31:25];
            case(instr[14:12])
            3'b000: op = `SB;
            3'b001: op = `SH;
            3'b010: op = `SW;
            endcase
        end
        7'b0010011 : begin
            is_sl = `False;
            imm[11:0] = instr[31:20];
            case(instr[14:12])
            3'b000: op = `ADDI;
            3'b010: op = `SLTI;
            3'b011: op = `SLTIU;
            3'b100: op = `XORI;
            3'b110: op = `ORI;
            3'b001: op = `SLLI;
            3'b111: op = `ANDI;
            3'b101: begin
                op = instr[30] ? `SRAI: `SRLI;
                imm[11:5] = 7'b0000000;
            end
            endcase
        end
        7'b0110011 : begin
            is_sl = `False;
            rs2 = instr[24:20];
            case(instr[14:12])
            3'b000 : op = instr[30] ? `SUB : `ADD;
            3'b001 : op = `SLL;
            3'b010 : op = `SLT;
            3'b011 : op = `SLTU;
            3'b100 : op = `XOR;
            3'b101 : op = instr[30] ? `SRA : `SRL;
            3'b110 : op = `OR;
            3'b111 : op = `AND;
            endcase
        end
        default:;
        endcase
    end
    else begin
        is_sl <= `False;
        pc  <= 0;
        rs1 <= 0; 
        rs2 <= 0;
        rd  <= 0;
        imm <= 0;
        instr <= 0;
        op <= 0;
    end
end

assign  pc_to_reg   =   pc;
assign  rs1_to_reg  =   rs1;
assign  rs2_to_reg  =   rs2;
assign  rd_to_reg   =   rd;
assign  is_empty_to_reg  =  is_empty_from_instr_queue;
assign  is_empty_to_rob = is_empty_from_instr_queue;
assign  is_empty_to_rs = is_empty_from_instr_queue;
assign  is_empty_to_fc = is_empty_from_instr_queue;
assign  is_sl_to_rs = is_sl;
assign  is_sl_to_fc = is_sl;
assign  pc_to_rob = pc;
assign  rd_to_rob = rd;
assign  op_to_rob = op;
assign  pc_to_fc = pc;
assign  op_to_fc = op;
assign  imm_to_fc = imm;
assign  pc_to_rs = pc;
assign  op_to_rs = op;
assign  imm_to_rs = imm;
endmodule