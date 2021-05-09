// Testbench
module test #(
  parameter XW = 32
);

  logic                 [XW-1:0] m32a;
  logic                 [XW-1:0] m32b;
  logic   signed        [XW-1:0] r32s;
  
  initial begin
    $display("multiplier input signals:");
    m32a = 32'hffffdfff;
    m32b = -32'd1;
    $display("  signed: m32a = 0x%h = %d, m32b = 0x%h = %d",   $signed(m32a),   $signed(m32a),   $signed(m32b),   $signed(m32b));
    $display("unsigned: m32a = 0x%h = %d, m32b = 0x%h = %d", $unsigned(m32a), $unsigned(m32a), $unsigned(m32b), $unsigned(m32b));

    r32s = $signed(m32a) / $signed(m32b);

    $display("  signed: r32s = 0x%h = %d",   $signed(r32s), $signed(r32s));
    $finish();
  end

endmodule
