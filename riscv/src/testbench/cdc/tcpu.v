`timescale  1ns / 1ps
`include"cpu.v"
module tb_cpu;       

// cpu Parameters
parameter PERIOD  = 10;


// cpu Inputs
reg   clk_in                               = 0 ;
reg   rst_in                               = 0 ;
reg   rdy_in                               = 0 ;
reg   [ 7:0]  mem_din                      = 0 ;
reg   io_buffer_full                       = 0 ;

// cpu Outputs
wire  [ 7:0]  mem_dout                     ;
wire  [31:0]  mem_a                        ;
wire  mem_wr                               ;
wire  [31:0]  dbgreg_dout                  ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end

cpu  u_cpu (
    .clk_in                  ( clk_in                 ),
    .rst_in                  ( rst_in                 ),
    .rdy_in                  ( rdy_in                 ),
    .mem_din                 ( mem_din         [ 7:0] ),
    .io_buffer_full          ( io_buffer_full         ),

    .mem_dout                ( mem_dout        [ 7:0] ),
    .mem_a                   ( mem_a           [31:0] ),
    .mem_wr                  ( mem_wr                 ),
    .dbgreg_dout             ( dbgreg_dout     [31:0] )
);

initial
begin

    $finish;
end

endmodule