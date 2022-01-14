`include "parameters.v"
module alu (
    input rst,
    input wire[`OpcodeLength:`Zero] op_from_rs,
    input wire is_empty_from_rs,
    input wire[`DataLength:`Zero] v1_from_rs,
    input wire[`DataLength:`Zero] v2_from_rs,
    input wire[`DataLength:`Zero] imm_from_rs,
    input wire[`PcLength:`Zero] pc_from_rs,
    output wire[`DataLength:`Zero] data_to_rob,
    output wire[`PcLength:`Zero] pc_to_rob,
    output wire is_finish_to_rob,
    output wire [`PcLength:`Zero] jpc_to_rob   
);
reg [`PcLength:`Zero] jpc;
reg [`PcLength:`Zero] pc;
reg [`DataLength:`Zero] data;
reg is_finish;
reg [`OpcodeLength:`Zero] op;
reg [`DataLength : `Zero] imm;
reg signed [`DataLength : `Zero] v1;
reg signed [`DataLength : `Zero] v2;
reg [`DataLength : `Zero] uv1;
reg [`DataLength : `Zero] uv2;
always @(*) begin
    if(rst == `True) begin
        pc = 0;
        data = 0;
        is_finish = 0;
        op = 0;
        v1 = 0;
        v2 = 0;
        uv1 = 0;
        uv2 = 0;
        imm = 0;
        jpc = 0;
    end
    else begin
        pc = pc_from_rs; 
        op = op_from_rs;
        v1 = v1_from_rs;
        v2 = v2_from_rs;
        uv1 = v1_from_rs;
        uv2 = v2_from_rs;
        imm = imm_from_rs;
        jpc = pc_from_rs + 4;
        data = 0;
        case(op)
        `LUI : data = imm << 12;
        `AUIPC : data = pc + (imm << 12);
        `JAL : begin data = pc + 4; jpc = pc + {{11{imm[20]}},imm[20:0]}; end
        `JALR : begin data = pc + 4; jpc = (v1 + {{20{imm[11]}},imm[11:0]} ) & (~1); end
        `BEQ : jpc = (v1==v2) ? pc + {{19{imm[12]}},imm[12:0]} : pc + 4;
        `BNE : jpc = (v1!=v2) ? pc + {{19{imm[12]}},imm[12:0]} : pc + 4;
        `BLT : begin
            jpc = (v1<v2) ? pc + {{19{imm[12]}},imm[12:0]} : pc + 4;
        end
        `BGE : jpc = (v1>=v2) ? pc + {{19{imm[12]}},imm[12:0]} : pc + 4;
        `BLTU : begin
            jpc = (uv1<uv2) ? pc + {{19{imm[12]}},imm[12:0]} : pc+4;
        end 
        `BGEU : jpc = (uv1>=uv2) ? pc + {{19{imm[12]}},imm[12:0]} : pc + 4;
        `ADDI : data = v1 + {{20{imm[11]}},imm[11:0]};
        `SLTI : data = (v1 < {{20{imm[11]}},imm[11:0]}) ? 1 : 0;
        `SLTIU : data = (uv1 < {{20{imm[11]}},imm[11:0]} ) ? 1 : 0;
        `XORI : data = v1 ^ ({{20{imm[11]}},imm[11:0]});
        `ORI  : data = v1 | ({{20{imm[11]}},imm[11:0]});
        `ANDI : data = v1 & ({{20{imm[11]}},imm[11:0]});
        `SLLI : data = v1 << imm[4:0];
        `SRLI : data = uv1 >> imm[4:0];
        `SRAI : data = v1 >>> imm[4:0];
        `ADD : data = v1 + v2;
        `SUB : data = v1 - v2;
        `SLL : data = v1 << v2[4:0];
        `SLT : data = (v1 < v2) ? 1 : 0;
        `SLTU : data = (uv1 < uv2) ? 1 : 0;
        `XOR : data = v1 ^ v2;
        `SRL : data = uv1 >> v2[4:0];
        `SRA : data = v1 >>> v2[4:0];
        `OR : data = v1 | v2;
        `AND : data = v1 & v2;
        endcase
        is_finish  = ~is_empty_from_rs;
    end
end
assign pc_to_rob = pc;
assign data_to_rob = data;
assign jpc_to_rob = jpc;
assign is_finish_to_rob = is_finish;
endmodule