module rp_tb (
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
);

localparam string REG_X1 [0:7] = '{"zero", "one", "two", "three", "four", "five", "six", "seven"};

initial begin
  $display("%s", REG_X1[3'd1]);
end

endmodule: rp_tb
