////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module rp_tb #(
  int unsigned PAW = 16,    // program address width
  int unsigned PDW = 32,    // program data    width
  int unsigned DAW = 16,    // data    address width
  int unsigned DDW = 32,    // data    data    width
  int unsigned DSW = DDW/8  // data    select  width
)(
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
);

import riscv_asm_pkg::*;

initial begin
  $display("%s %s", "test", reg_x(5'd1));
end

endmodule: rp_tb
