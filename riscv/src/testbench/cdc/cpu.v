// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "InstrQueue.v"
`include "Fetcher.v"
`include "decoder.v"
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
reg true = `True;
reg false = `False;
dc mdc(
    .rst(rst_in),
    .is_empty_from_instr_queue(is_empty_from_iq_to_dc),
    .pc_from_instr_queue(pc_from_iq_to_dc),
    .instr_from_instr_queue(instr_from_iq_to_dc),
    .is_empty_to_reg(),
    .rd_to_reg(),
    .pc_to_reg(),
    .rs1_to_reg(),
    .rs2_to_reg(),
    .imm_to_reg()
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
  .rst (rst_in),
  .clk (clk_in),
  .data_from_ram (mem_din),
  .addr_from_slb (),
  .is_empty_from_slb (true),
  .is_store_from_slb (),
  .is_empty_from_iq (is_empty_from_iq_to_fc),
  .addr_from_iq(addr_from_iq_to_fc),
  .is_receive_from_iq(is_receive_from_iq_to_fc),
  .is_receive_from_slb(),
  .is_instr_to_iq(is_instr_from_fc_to_iq),
  .is_stall_to_slb(),
  .is_stall_to_iq(is_stall_from_fc_to_iq),
  .is_instr_to_slb(),
  .is_store_to_ram(mem_wr),
  .is_finish_to_slb(),
  .is_finish_to_iq(is_finish_from_fc_to_iq),
  .addr_to_ram(mem_a),
  .data_to_ram(mem_dout),
  .data_to_slb(),
  .data_to_iq(instr_from_fc_to_iq)
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