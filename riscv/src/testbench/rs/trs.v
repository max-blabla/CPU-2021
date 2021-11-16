<<<<<<< HEAD
`include"parameters.v"
`include"ReverseStation.v"
`timescale  1ns / 1ps

module tb_rs;        

// rs Parameters
parameter PERIOD    = 10;
parameter RsLength  = 7;

// rs Inputs
reg   rst_n                                  = 0 ;
reg   clk                                  = 0 ;
reg   is_empty_from_rob                    = 0 ;
reg   is_sl_from_rob                       = 0 ;
reg   is_exception_from_rob                = 0 ;
reg   is_commit_from_rob                   = 0 ;
reg   [`OpcodeLength:`Zero] op_from_rob = 0 ;
reg   [`DataLength:`Zero] v1_from_rob  = 0 ;
reg   [`DataLength:`Zero] v2_from_rob  = 0 ;
reg   [`PcLength:`Zero] q1_from_rob    = 0 ;
reg   [`PcLength:`Zero] q2_from_rob    = 0 ;
reg   [`DataLength:`Zero] imm_from_rob = 0 ;
reg   [`DataLength:`Zero] pc_from_rob  = 0 ;
reg   [`DataLength:`Zero] commit_data_from_rob = 0 ;
reg   [`PcLength:`Zero] commit_pc_from_rob = 0 ;

// rs Outputs
wire  [`OpcodeLength:`Zero] op_to_alu  ;
wire  [`DataLength:`Zero] v1_to_alu    ;
wire  [`DataLength:`Zero] v2_to_alu    ;
wire  [`DataLength:`Zero] imm_to_alu   ;
wire  [`DataLength:`Zero] pc_to_alu    ;
wire  is_stall_to_instr_queue              ;
wire  is_stall_to_rob                      ;


initial
begin
    #(PERIOD*2) rst_n  =  1;
    forever #(PERIOD/2)  clk=~clk;
end


rs #(
    .RsLength ( RsLength ))
 u_rs (
    .rst                                           ( rst_n                                            ),
    .clk                                           ( clk                                            ),
    .is_empty_from_rob                             ( is_empty_from_rob                              ),
    .is_sl_from_rob                                ( is_sl_from_rob                                 ),
    .is_exception_from_rob                         ( is_exception_from_rob                          ),
    .is_commit_from_rob                            ( is_commit_from_rob                             ),
    .op_from_rob         ( op_from_rob          ),
    .v1_from_rob           (  v1_from_rob            ),
    .v2_from_rob           (  v2_from_rob            ),
    .q1_from_rob             (  q1_from_rob              ),
    .q2_from_rob             ( q2_from_rob              ),
    .imm_from_rob          ( imm_from_rob           ),
    .pc_from_rob           ( pc_from_rob            ),
    .commit_data_from_rob  ( commit_data_from_rob   ),
    .commit_pc_from_rob      ( commit_pc_from_rob       ),

    .op_to_alu           ( op_to_alu            ),
    .v1_to_alu             ( v1_to_alu              ),
    .v2_to_alu             ( v2_to_alu              ),
    .imm_to_alu            ( imm_to_alu             ),
    .pc_to_alu             ( pc_to_alu              ),
    .is_stall_to_instr_queue                       ( is_stall_to_instr_queue                        ),
    .is_stall_to_rob                               ( is_stall_to_rob                                )
);

initial
begin
    $dumpfile("test.vcd");
    $dumpvars(0,tb_rs);
    #100;
    $finish;
end

=======
`include"parameters.v"
`include"ReverseStation.v"
`timescale  1ns / 1ps

module tb_rs;        

// rs Parameters
parameter PERIOD    = 10;
parameter RsLength  = 7;

// rs Inputs
reg   rst_n                                  = 0 ;
reg   clk                                  = 0 ;
reg   is_empty_from_rob                    = 0 ;
reg   is_sl_from_rob                       = 0 ;
reg   is_exception_from_rob                = 0 ;
reg   is_commit_from_rob                   = 0 ;
reg   [`OpcodeLength:`Zero] op_from_rob = 0 ;
reg   [`DataLength:`Zero] v1_from_rob  = 0 ;
reg   [`DataLength:`Zero] v2_from_rob  = 0 ;
reg   [`PcLength:`Zero] q1_from_rob    = 0 ;
reg   [`PcLength:`Zero] q2_from_rob    = 0 ;
reg   [`DataLength:`Zero] imm_from_rob = 0 ;
reg   [`DataLength:`Zero] pc_from_rob  = 0 ;
reg   [`DataLength:`Zero] commit_data_from_rob = 0 ;
reg   [`PcLength:`Zero] commit_pc_from_rob = 0 ;

// rs Outputs
wire  [`OpcodeLength:`Zero] op_to_alu  ;
wire  [`DataLength:`Zero] v1_to_alu    ;
wire  [`DataLength:`Zero] v2_to_alu    ;
wire  [`DataLength:`Zero] imm_to_alu   ;
wire  [`DataLength:`Zero] pc_to_alu    ;
wire  is_stall_to_instr_queue              ;
wire  is_stall_to_rob                      ;


initial
begin
    #(PERIOD*2) rst_n  =  1;
    forever #(PERIOD/2)  clk=~clk;
end


rs #(
    .RsLength ( RsLength ))
 u_rs (
    .rst                                           ( rst_n                                            ),
    .clk                                           ( clk                                            ),
    .is_empty_from_rob                             ( is_empty_from_rob                              ),
    .is_sl_from_rob                                ( is_sl_from_rob                                 ),
    .is_exception_from_rob                         ( is_exception_from_rob                          ),
    .is_commit_from_rob                            ( is_commit_from_rob                             ),
    .op_from_rob         ( op_from_rob          ),
    .v1_from_rob           (  v1_from_rob            ),
    .v2_from_rob           (  v2_from_rob            ),
    .q1_from_rob             (  q1_from_rob              ),
    .q2_from_rob             ( q2_from_rob              ),
    .imm_from_rob          ( imm_from_rob           ),
    .pc_from_rob           ( pc_from_rob            ),
    .commit_data_from_rob  ( commit_data_from_rob   ),
    .commit_pc_from_rob      ( commit_pc_from_rob       ),

    .op_to_alu           ( op_to_alu            ),
    .v1_to_alu             ( v1_to_alu              ),
    .v2_to_alu             ( v2_to_alu              ),
    .imm_to_alu            ( imm_to_alu             ),
    .pc_to_alu             ( pc_to_alu              ),
    .is_stall_to_instr_queue                       ( is_stall_to_instr_queue                        ),
    .is_stall_to_rob                               ( is_stall_to_rob                                )
);

initial
begin
    $dumpfile("test.vcd");
    $dumpvars(0,tb_rs);
    #100;
    $finish;
end

>>>>>>> f0186ad8f001956fa1504d6ecb233fb822dce3a0
endmodule