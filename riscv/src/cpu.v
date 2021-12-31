// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "parameters.v"
module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
wire is_empty_from_iq_to_ic;
wire [`DataLength:`Zero] pc_from_iq_to_ic; 

wire is_stall_from_fc_to_ic;
wire is_commit_from_fc_to_ic;
wire is_instr_from_fc_to_ic;
wire [`DataLength:`Zero] instr_from_fc_to_ic;

wire is_empty_from_ic_to_fc;
wire [`PcLength:`Zero] addr_from_ic_to_fc;

wire is_hit_from_ic_to_iq;
wire [`DataLength:`Zero] instr_from_ic_to_iq;

wire [`PcLength:`Zero] pc_from_iq_to_dc;
wire is_empty_from_iq_to_dc;
wire [`DataLength:`Zero]instr_from_iq_to_dc;

wire is_empty_from_dc_to_rf;
wire [4:0] rd_from_dc_to_rf;
wire [`PcLength:`Zero] pc_from_dc_to_rf;
wire [4:0] rs1_from_dc_to_rf;
wire [4:0] rs2_from_dc_to_rf; 
wire [`DataLength:`Zero] imm_from_dc_to_rf;
wire [`OpcodeLength:`Zero] op_from_dc_to_rf;

wire is_ready_from_dc_to_iq;

wire is_empty_from_dc_to_rob;
wire [`PcLength:`Zero] pc_from_dc_to_rob;
wire [`OpcodeLength:`Zero] op_from_dc_to_rob;
wire [4:0] rd_from_dc_to_rob;

wire is_exception_from_rob_to_iq;
wire [`PcLength:`Zero] jpc_from_rob_to_iq;

wire is_empty_from_dc_to_rs;
wire is_sl_from_dc_to_rs;
wire [`OpcodeLength:`Zero] op_from_dc_to_rs;
wire [`DataLength:`Zero] imm_from_dc_to_rs;
wire [`PcLength:`Zero] pc_from_dc_to_rs;

wire [`PcLength:`Zero] q1_from_rf_to_rs;
wire [`PcLength:`Zero] q2_from_rf_to_rs;
wire [`DataLength:`Zero] v1_from_rf_to_rs;
wire [`DataLength:`Zero] v2_from_rf_to_rs;
wire [`PcLength:`Zero] pc_from_rf_to_rs;


wire [`PcLength:`Zero] commit_pc_from_rob_to_rs;
wire [`DataLength:`Zero] commit_data_from_rob_to_rs;
wire is_commit_from_rob_to_rs;
wire is_exception_from_rob_to_rs;

wire [`OpcodeLength:`Zero] op_from_rs_to_alu;
wire [`DataLength:`Zero] v1_from_rs_to_alu;
wire [`DataLength:`Zero] v2_from_rs_to_alu;
wire [`DataLength:`Zero] imm_from_rs_to_alu;
wire [`PcLength:`Zero] pc_from_rs_to_alu;
wire is_empty_from_rs_to_alu;

wire [`DataLength:`Zero] data_from_alu_to_rob;
wire [`PcLength:`Zero] pc_from_alu_to_rob;
wire [`PcLength:`Zero] jpc_from_alu_to_rob;
wire is_empty_from_alu_to_rob;

wire [`PcLength:`Zero] q1_from_rf_to_fc;
wire [`PcLength:`Zero] q2_from_rf_to_fc;
wire [`DataLength:`Zero] v1_from_rf_to_fc;
wire [`DataLength:`Zero] v2_from_rf_to_fc;

wire [`DataLength:`Zero] imm_from_dc_to_fc;
wire [`OpcodeLength:`Zero] op_from_dc_to_fc;
wire [`PcLength:`Zero] pc_from_dc_to_fc;
wire is_empty_from_dc_to_fc;
wire is_sl_from_dc_to_fc;

wire [`PcLength:`Zero] commit_pc_from_rob_to_fc;
wire [`DataLength:`Zero] commit_data_from_rob_to_fc;
wire is_commit_from_rob_to_fc;
wire is_exception_from_rob_to_fc;

wire is_exception_from_rob_to_rob;

wire [`PcLength:`Zero] commit_pc_from_rob_to_rf;
wire [`DataLength:`Zero] commit_data_from_rob_to_rf;
wire is_commit_from_rob_to_rf;
wire [4:0] commit_rd_from_rob_to_rf;
wire is_exception_from_rob_to_rf;
 

wire [`DataLength:`Zero] data_from_fc_to_rob;
wire [`PcLength:`Zero] pc_from_fc_to_rob;
wire is_commit_from_fc_to_rob;
wire is_instr_from_fc_to_rob;

wire is_ready_from_fc_to_iq;
wire is_ready_from_rob_to_iq;
wire is_ready_from_rs_to_iq;


wire v1_from_dc_to_rs;
wire v2_from_dc_to_rs;
wire q1_from_dc_to_rs;
wire q2_from_dc_to_rs;
wire v1_from_dc_to_fc;
wire v2_from_dc_to_fc;
wire q1_from_dc_to_fc;
wire q2_from_dc_to_fc;

wire is_empty_from_dc_to_reg;

wire is_exception_from_rob_to_ic;

wire is_exception_from_rob_to_slb;

wire is_sl_from_dc_to_slb;
wire is_empty_from_dc_to_slb;
wire [`PcLength:`Zero] commit_pc_from_rob_to_slb;
wire [`DataLength:`Zero] commit_data_from_rob_to_slb;
wire [`PcLength:`Zero] pc_from_dc_to_slb;
wire [`DataLength:`Zero] imm_from_dc_to_slb;
wire [`OpcodeLength:`Zero] op_from_dc_to_slb;
wire [`DataLength:`Zero] v1_from_rf_to_slb;
wire [`DataLength:`Zero] v2_from_rf_to_slb;
wire [`PcLength:`Zero] q1_from_rf_to_slb;
wire [`PcLength:`Zero] q2_from_rf_to_slb;
wire [`DataLength:`Zero] data_from_fc_to_slb;
wire is_finish_from_fc_to_slb;
wire is_instr_from_fc_to_slb;

wire [`DataLength:`Zero] data_from_slb_to_rob;
wire [`PcLength:`Zero] commit_pc_from_slb_to_rob;
wire [`DataLength:`Zero] data_from_slb_to_fc;
wire is_store_from_slb_to_fc;
wire is_empty_from_slb_to_fc;
wire is_commit_from_slb_to_rob;
wire [`PcLength:`Zero]addr_from_slb_to_fc;
wire [1:0] aim_from_slb_to_fc;

wire is_ready_from_slb_to_iq;

wire is_commit_from_rob_to_slb;
wire is_store_from_fc_to_slb;

slb mslb(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .is_exception_from_rob(is_exception_from_rob_to_slb),
  .is_empty_from_dc(is_empty_from_dc_to_slb),
  .is_sl_from_dc(is_sl_from_dc_to_slb),
  .is_commit_from_rob(is_commit_from_rob_to_slb),
  .commit_pc_from_rob(commit_pc_from_rob_to_slb),
  .commit_data_from_rob(commit_data_from_rob_to_slb),

    
  .pc_from_dc(pc_from_dc_to_slb),
  .imm_from_dc(imm_from_dc_to_slb),
  .op_from_dc(op_from_dc_to_slb),

  .q1_from_rf(q1_from_rf_to_slb),
  .q2_from_rf(q2_from_rf_to_slb),
  .v1_from_rf(v1_from_rf_to_slb),
  .v2_from_rf(v2_from_rf_to_slb),

  .data_from_fc(data_from_fc_to_slb),
  .is_finish_from_fc(is_finish_from_fc_to_slb),
  .is_instr_from_fc(is_instr_from_fc_to_slb),
  .is_store_from_fc(is_store_from_fc_to_slb),

  .data_to_rob(data_from_slb_to_rob),
  .data_to_fc(data_from_slb_to_fc),
  .is_store_to_fc(is_store_from_slb_to_fc),
  .is_empty_to_fc(is_empty_from_slb_to_fc),
  .is_commit_to_rob(is_commit_from_slb_to_rob),
  .addr_to_fc(addr_from_slb_to_fc),
  .is_ready_to_iq(is_ready_from_slb_to_iq),
  .commit_pc_to_rob(commit_pc_from_slb_to_rob),
  .aim_to_fc(aim_from_slb_to_fc)
);

alu malu(
    .rst                    (rst_in),
    .clk                    (clk_in),
    .op_from_rs             (op_from_rs_to_alu),
    .v1_from_rs             (v1_from_rs_to_alu),
    .v2_from_rs             (v2_from_rs_to_alu),
    .imm_from_rs            (imm_from_rs_to_alu),
    .pc_from_rs             (pc_from_rs_to_alu),
    .is_empty_from_rs       (is_empty_from_rs_to_alu),
    .data_to_rob            (data_from_alu_to_rob),
    .pc_to_rob              (pc_from_alu_to_rob),
    .is_finish_to_rob       (is_finish_from_alu_to_rob),
    .jpc_to_rob             (jpc_from_alu_to_rob)   
);

rs mrs(
    .rst                      (rst_in),
    .clk                      (clk_in),
    .rdy                      (rdy_in),
    .is_empty_from_dc        (is_empty_from_dc_to_rs),
    .is_sl_from_dc           (is_sl_from_dc_to_rs),
    .is_exception_from_rob    (is_exception_from_rob_to_rs),
    .is_commit_from_rob       (is_commit_from_rob_to_rs),
    .op_from_dc              (op_from_dc_to_rs),
    .v1_from_rf              (v1_from_rf_to_rs),
    .v2_from_rf              (v2_from_rf_to_rs),
    .q1_from_rf              (q1_from_rf_to_rs),
    .q2_from_rf              (q2_from_rf_to_rs),
    .pc_from_rf               (pc_from_rf_to_rs),
    .imm_from_dc              (imm_from_dc_to_rs),
    .pc_from_dc              (pc_from_dc_to_rs),
    .commit_data_from_rob     (commit_data_from_rob_to_rs),
    .commit_pc_from_rob       (commit_pc_from_rob_to_rs),
    .op_to_alu                (op_from_rs_to_alu),
    .v1_to_alu                (v1_from_rs_to_alu),
    .v2_to_alu                (v2_from_rs_to_alu),
    .imm_to_alu               (imm_from_rs_to_alu),
    .pc_to_alu                (pc_from_rs_to_alu),
    .is_ready_to_iq           (is_ready_from_rs_to_iq),
    .is_empty_to_alu          (is_empty_from_rs_to_alu)
);
rob mrob(
    .clk                                (clk_in),
    .rst                                (rst_in),
    .rdy                                (rdy_in),
    .is_empty_from_dc                   (is_empty_from_dc_to_rob),
    .is_finish_from_alu                 (is_finish_from_alu_to_rob),
    .is_commit_from_slb                 (is_commit_from_slb_to_rob),
    .is_ready_to_iq                     (is_ready_from_rob_to_iq),
    .is_exception_from_rob              (is_exception_from_rob_to_rob),

    .data_from_alu                      (data_from_alu_to_rob),
    .pc_from_alu                        (pc_from_alu_to_rob),
    .jpc_from_alu                       (jpc_from_alu_to_rob),
    .data_from_slb                      (data_from_slb_to_rob),
    .pc_from_slb                       (commit_pc_from_slb_to_rob),
    .pc_from_dc                        (pc_from_dc_to_rob),
    .rd_from_dc                        (rd_from_dc_to_rob),
    .is_exception_to_instr_queue        (is_exception_from_rob_to_iq),
    .is_exception_to_reg                (is_exception_from_rob_to_rf),
    .is_exception_to_rs                 (is_exception_from_rob_to_rs),
    .is_exception_to_slb                (is_exception_from_rob_to_slb),
    .is_exception_to_rob                (is_exception_from_rob_to_rob),
    .is_exception_to_fc                 (is_exception_from_rob_to_fc),
    .is_exception_to_ic                 (is_exception_from_rob_to_ic),
    .pc_to_instr_queue                  (jpc_from_rob_to_iq),
    .commit_rd_to_reg                   (commit_rd_from_rob_to_rf),
    .commit_pc_to_rs                    (commit_pc_from_rob_to_rs),
    .commit_pc_to_slb                   (commit_pc_from_rob_to_slb),
    .commit_pc_to_reg                   (commit_pc_from_rob_to_rf),
    .commit_data_to_rs                  (commit_data_from_rob_to_rs),
    .commit_data_to_slb                 (commit_data_from_rob_to_slb),
    .commit_data_to_reg                 (commit_data_from_rob_to_rf),
    .is_commit_to_reg                   (is_commit_from_rob_to_rf),
    .is_commit_to_rs                    (is_commit_from_rob_to_rs),
    .is_commit_to_slb                   (is_commit_from_rob_to_slb)
);
rf mrf(
    .rst(rst_in),
    .clk(clk_in),
    .rdy(rdy_in),
    .is_empty_from_decoder(is_empty_from_dc_to_rf),
    .is_commit_from_rob(is_commit_from_rob_to_rf),
    .is_exception_from_rob(is_exception_from_rob_to_rf),

    .pc_from_rob(commit_pc_from_rob_to_rf),
    .rd_from_rob(commit_rd_from_rob_to_rf),
    .data_from_rob(commit_data_from_rob_to_rf),
    .rd_from_decoder(rd_from_dc_to_rf),
    .pc_from_decoder(pc_from_dc_to_rf),
    .rs1_from_decoder(rs1_from_dc_to_rf),
    .rs2_from_decoder(rs2_from_dc_to_rf),
    
    .v1_to_rs(v1_from_rf_to_rs),
    .v2_to_rs(v2_from_rf_to_rs),
    .q1_to_rs(q1_from_rf_to_rs),
    .q2_to_rs(q2_from_rf_to_rs),
    .v1_to_slb(v1_from_rf_to_slb),
    .v2_to_slb(v2_from_rf_to_slb),
    .q1_to_slb(q1_from_rf_to_slb),
    .q2_to_slb(q2_from_rf_to_slb),
    .pc_to_rs(pc_from_rf_to_rs)
);
dc mdc(
    .rst                        (rst_in),
    .is_empty_from_instr_queue  (is_empty_from_iq_to_dc),
    .pc_from_instr_queue        (pc_from_iq_to_dc),
    .instr_from_instr_queue     (instr_from_iq_to_dc),
    .is_empty_to_reg            (is_empty_from_dc_to_rf),    
    .is_empty_to_rob            (is_empty_from_dc_to_rob),
    .is_empty_to_rs             (is_empty_from_dc_to_rs),
    .is_empty_to_slb            (is_empty_from_dc_to_slb),
    .is_sl_to_slb               (is_sl_from_dc_to_slb),
    .is_sl_to_rs                (is_sl_from_dc_to_rs),
    .rd_to_reg                  (rd_from_dc_to_rf),
    .pc_to_reg                  (pc_from_dc_to_rf),
    .rs1_to_reg                 (rs1_from_dc_to_rf),
    .rs2_to_reg                 (rs2_from_dc_to_rf),
    .imm_to_slb                 (imm_from_dc_to_slb),
    .op_to_slb                  (op_from_dc_to_slb),
    .pc_to_slb                  (pc_from_dc_to_slb),
    .rd_to_rob                  (rd_from_dc_to_rob),
    .pc_to_rob                  (pc_from_dc_to_rob),
    .op_to_rob                  (op_from_dc_to_rob),
    .imm_to_rs                  (imm_from_dc_to_rs),
    .op_to_rs                   (op_from_dc_to_rs),
    .pc_to_rs                   (pc_from_dc_to_rs)
);
iq miq(
    .rst                                     ( rst_in                                      ),
    .clk                                     ( clk_in                                   ),
    .rdy                                      (rdy_in),
    .is_exception_from_rob                   ( is_exception_from_rob_to_iq ),
    .is_hit_from_ic                          ( is_hit_from_ic_to_iq                         ),
    .is_ready_from_rob                       (is_ready_from_rob_to_iq),
    .is_ready_from_rs                        (is_ready_from_rs_to_iq),
    .is_ready_from_slb                       (is_ready_from_slb_to_iq),
    .pc_from_rob                             ( jpc_from_rob_to_iq  ),
    .instr_from_ic                           ( instr_from_ic_to_iq                            ),
    .is_empty_to_dc                          ( is_empty_from_iq_to_dc     ),
    .is_empty_to_ic                          ( is_empty_from_iq_to_ic                   ),
    .instr_to_dc                             ( instr_from_iq_to_dc      ),
    .pc_to_dc                                ( pc_from_iq_to_dc           ),
    .pc_to_ic                                ( pc_from_iq_to_ic                                 )
);
ic mic(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .pc_from_iq(pc_from_iq_to_ic),
  .instr_from_fc(instr_from_fc_to_ic),
  .is_commit_from_fc(is_commit_from_fc_to_ic),
  .is_empty_from_iq(is_empty_from_iq_to_ic),
  .is_instr_from_fc(is_instr_from_fc_to_ic),
  .addr_to_fc(addr_from_ic_to_fc),
  .is_empty_to_fc(is_empty_from_ic_to_fc),
  .is_hit_to_iq(is_hit_from_ic_to_iq),
  .instr_to_iq(instr_from_ic_to_iq),
  .is_exception_from_rob(is_exception_from_rob_to_ic)
);

fc mfc(
  .rst(rst_in),
  .is_full_from_io(io_buffer_full),
  .rdy(rdy_in),
  .clk(clk_in),
  .is_empty_from_ic(is_empty_from_ic_to_fc),
  .is_empty_from_slb(is_empty_from_slb_to_fc),
  .is_exception_from_rob(is_exception_from_rob_to_fc),
  .is_store_from_slb(is_store_from_slb_to_fc),
  .addr_from_ic(addr_from_ic_to_fc),
  .data_from_ram(mem_din),
  .addr_from_slb(addr_from_slb_to_fc),
  .data_from_slb(data_from_slb_to_fc),
  .aim_from_slb(aim_from_slb_to_fc),

  .is_commit_to_slb(is_finish_from_fc_to_slb),
  .is_commit_to_ic(is_commit_from_fc_to_ic),
  .is_ready_to_iq(is_ready_from_fc_to_iq),
  .is_instr_to_slb(is_instr_from_fc_to_slb),
  .is_instr_to_ic(is_instr_from_fc_to_ic),
  .is_store_to_ram(mem_wr),
  .is_store_to_slb(is_store_from_fc_to_slb),
  .data_to_slb(data_from_fc_to_slb),
  .data_to_ic(instr_from_fc_to_ic),
  .addr_to_ram(mem_a),
  .data_to_ram(mem_dout)
);



always @(posedge clk_in)
  begin  

    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end

endmodule