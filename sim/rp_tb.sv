module rp_tb (
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
);

localparam string REG_X [0:31] = '{"zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0/fp", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
                                   "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};

function string reg_x (logic [5-1:0] r, bit abi=1'b0);
  reg_x = abi ? REG_X[r] : $sformatf("x%0d", r);
endfunction: reg_x

function string dis32 (logic [32-1:0] op);
casez (op)
32'b0000_0000_0000_0000_0000_0000_0001_0011: dis32 = $sformatf("nop");
32'b0000_0000_0000_0000_0100_0000_0011_0011: dis32 = $sformatf("-"); // 32'h00004033 - machine generated bubble
32'b????_????_????_????_?000_????_?110_0111: dis32 = $sformatf("jalr  %s, 0x%03x (%s)", reg_x(op[5-1:0]), op[16-1:0], reg_x(op[5-1:0]));
default: dis32 = "illegal";
endcase
endfunction: dis32

always @(posedge clk)
begin
  for (int unsigned i=0; i<32; i++)
    $display("REG_X: %s", reg_x(i[5-1:0]));
  $display("OP: %s", dis32(32'h00000000));
  $finish();
end

endmodule: rp_tb
