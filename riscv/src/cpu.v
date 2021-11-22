// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "InstrQueue.v"
`include "Fetcher.v"
`include "decoder.v"
`include "RegFile.v"
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
wire is_empty_from_iq_to_fc;
wire is_receive_from_iq_to_fc;
wire is_stall_from_fc_to_iq;
wire is_finish_from_fc_to_iq;
wire is_instr_from_fc_to_iq;
wire [`DataLength:`Zero] addr_from_iq_to_fc; 
wire [`DataLength:`Zero] instr_from_fc_to_iq;

wire [`PcLength:`Zero] pc_from_iq_to_dc;
wire [1:0] cnt_from_fc_to_fc;
wire is_empty_from_iq_to_dc;
wire [`DataLength:`Zero]instr_from_iq_to_dc;

wire is_empty_from_dc_to_rf;
wire [4:0] rd_from_dc_to_rf;
wire [`PcLength:`Zero] pc_from_dc_to_rf;
wire [4:0] rs1_from_dc_to_rf;
wire [4:0] rs2_from_dc_to_rf; 
wire [`DataLength:`Zero] imm_from_dc_to_rf;
wire [`OpcodeLength:`Zero] op_from_dc_to_rf;
reg true = `True;
reg false = `False;
rf mrf(
    .rst                      (rst_in),
    .clk                      (clk_in),
    .is_empty_from_decoder    (is_empty_from_dc_to_rf),
    .is_finish_from_rob(),
    .is_exception_from_rob(),
    .pc_from_rob(),
    .rd_from_rob(),
    .data_from_rob(),
    .rd_from_decoder          (rd_from_dc_to_rf),
    .pc_from_decoder          (pc_from_dc_to_rf),
    .rs1_from_decoder         (rs1_from_dc_to_rf),
    .rs2_from_decoder         (rs2_from_dc_to_rf),
    .imm_from_decoder         (imm_from_dc_to_rf),
    .op_from_decoder          (op_from_dc_to_rf),
    .is_empty_to_rob(),
    .imm_to_rob(),
    .pc_to_rob(),
    .v1_to_rob(),
    .v2_to_rob(),
    .q1_to_rob(),
    .q2_to_rob(),
    .op_to_rob()
);
dc mdc(
    .rst                        (rst_in),
    .is_empty_from_instr_queue  (is_empty_from_iq_to_dc),
    .pc_from_instr_queue        (pc_from_iq_to_dc),
    .instr_from_instr_queue     (instr_from_iq_to_dc),
    .is_empty_to_reg            (is_empty_from_dc_to_rf),
    .rd_to_reg                  (rd_from_dc_to_rf),
    .pc_to_reg                  (pc_from_dc_to_rf),
    .rs1_to_reg                 (rs1_from_dc_to_rf),
    .rs2_to_reg                 (rs2_from_dc_to_rf),
    .imm_to_reg                 (imm_from_dc_to_rf),
    .op_to_reg                  (op_from_dc_to_rf)
);
iq miq(
    .rst                                     ( rst_in                                      ),
    .clk                                     ( clk_in                                   ),
    .is_stall_from_rob                       ( false             ),
    .is_exception_from_rob                   (                    ),
    .is_stall_from_fc                        ( is_stall_from_fc_to_iq                         ),
    .is_finish_from_fc                       ( is_finish_from_fc_to_iq                        ),
    .is_instr_from_fc                        ( is_instr_from_fc_to_iq                         ),
    .pc_from_rob                             (                               ),
    .instr_from_fc                           ( instr_from_fc_to_iq                            ),
    .is_empty_to_dc                          ( is_empty_from_iq_to_dc     ),
    .is_empty_to_fc                          ( is_empty_from_iq_to_fc                   ),
    .instr_to_dc                             ( instr_from_iq_to_dc      ),
    .pc_to_dc                                ( pc_from_iq_to_dc           ),
    .is_receive_to_fc                        ( is_receive_from_iq_to_fc                         ),
    .pc_to_fc                                ( addr_from_iq_to_fc                                 )
);
fc mfc(
  .rst                        (rst_in),
  .clk                        (clk_in),
  .data_from_ram              (mem_din),
  .addr_from_slb (),
  .is_empty_from_slb          (true),
  .is_store_from_slb (),
  .is_empty_from_iq           (is_empty_from_iq_to_fc),
  .addr_from_iq               (addr_from_iq_to_fc),
  .is_receive_from_iq         (is_receive_from_iq_to_fc),
  .is_receive_from_slb(),
  .is_instr_to_iq             (is_instr_from_fc_to_iq),
  .is_stall_to_slb(),
  .is_stall_to_iq             (is_stall_from_fc_to_iq),
  .is_instr_to_slb(),
  .is_store_to_ram            (mem_wr),
  .is_finish_to_slb(),
  .is_finish_to_iq            (is_finish_from_fc_to_iq),
  .addr_to_ram                (mem_a),
  .data_to_ram                (mem_dout),
  .data_to_slb(),
  .data_to_iq                 (instr_from_fc_to_iq)
);
initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,cpu);
end
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