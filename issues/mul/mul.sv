// Testbench
module test #(
  parameter XW = 32
);

  logic                 [XW-1:0] m32a;
  logic                 [XW-1:0] m32b;
  logic   signed [2-1:0][XW-1:0] r64ws;
  logic   signed        [64-1:0] r64ds;
  logic unsigned [2-1:0][XW-1:0] r64wu;
  logic unsigned        [64-1:0] r64du;
  
  logic                 [12-1:0] m12a;
  logic                 [12-1:0] m12b;
  logic   signed [2-1:0][12-1:0] r24ws;
  logic   signed        [24-1:0] r24ds;
  logic unsigned [2-1:0][12-1:0] r24wu;
  logic unsigned        [24-1:0] r24du;

  initial begin
    $display("multiplier input signals:");
    m32a = -32'h20000001;
    m32b = -32'h20000001;
    $display("  signed: m32a = 0x%h = %d, m32b = 0x%h = %d",   $signed(m32a),   $signed(m32a),   $signed(m32b),   $signed(m32b));
    $display("unsigned: m32a = 0x%h = %d, m32b = 0x%h = %d", $unsigned(m32a), $unsigned(m32a), $unsigned(m32b), $unsigned(m32b));

    $display("");
    $display("signed multiplication:");
    r64ws = $signed(m32a) * $signed(m32b);
    r64ds = $signed(m32a) * $signed(m32b);
    $display("r64ws = 0x%h = %d", $signed(r64ws), $signed(r64ws));
    $display("r64ds = 0x%h = %d", $signed(r64ds), $signed(r64ds));

    $display("");
    $display("unsigned multiplication:");
    r64wu = $unsigned(m32a) * $unsigned(m32b);
    r64du = $unsigned(m32a) * $unsigned(m32b);
    $display("r64wu = 0x%h = %d", $unsigned(r64wu), $unsigned(r64wu));
    $display("r64du = 0x%h = %d", $unsigned(r64du), $unsigned(r64du));

    $display("");
    $display("signed/unsigned multiplication:");
    r64ws = $signed(m32a) * $unsigned(m32b);
    r64ds = $signed(m32a) * $unsigned(m32b);
    $display("r64ws = 0x%h = %d", $signed(r64ws), $signed(r64ws));
    $display("r64ds = 0x%h = %d", $signed(r64ds), $signed(r64ds));

    $display("");
    $display("multiplier inputsized decimal literals:");
    $display("a = 0x%h = %d, b = 0x%h = %d", -32'sd536870913, -32'sd536870913, 32'd3758096383, 32'd3758096383);
    /* verilator lint_off WIDTH */
    r64ws = -32'sd536870913 * 32'd3758096383;
    r64ds = -32'sd536870913 * 32'd3758096383;
    /* verilator lint_on WIDTH */
    $display("r64ws = 0x%h = %d", $signed(r64ws), $signed(r64ws));
    $display("r64ds = 0x%h = %d", $signed(r64ds), $signed(r64ds));

    $display("");
    $display("multiplier input sized hex literals:");
    $display("a = 0x%h = %d, b = 0x%h = %d", -32'sh20000001, -32'sh20000001, 32'hdfffffff, 32'hdfffffff);
    /* verilator lint_off WIDTH */
    r64ws = -32'sh20000001 * 32'hdfffffff;
    r64ds = -32'sh20000001 * 32'hdfffffff;
    /* verilator lint_on WIDTH */
    $display("r64ws = 0x%h = %d", $signed(r64ws), $signed(r64ws));
    $display("r64ds = 0x%h = %d", $signed(r64ds), $signed(r64ds));


    $display("");
    $display("");
    $display("multiplier input signals:");
    m12a = -12'h201;
    m12b = -12'h201;
    $display("  signed: m12a = 0x%h = %d, m12b = 0x%h = %d",   $signed(m12a),   $signed(m12a),   $signed(m12b),   $signed(m12b));
    $display("unsigned: m12a = 0x%h = %d, m12b = 0x%h = %d", $unsigned(m12a), $unsigned(m12a), $unsigned(m12b), $unsigned(m12b));

    $display("");
    $display("signed multiplication:");
    r24ws = $signed(m12a) * $signed(m12b);
    r24ds = $signed(m12a) * $signed(m12b);
    $display("r24ws = 0x%h = %d", $signed(r24ws), $signed(r24ws));
    $display("r24ds = 0x%h = %d", $signed(r24ds), $signed(r24ds));

    $display("");
    $display("unsigned multiplication:");
    r24wu = $unsigned(m12a) * $unsigned(m12b);
    r24du = $unsigned(m12a) * $unsigned(m12b);
    $display("r24wu = 0x%h = %d", $unsigned(r24wu), $unsigned(r24wu));
    $display("r24du = 0x%h = %d", $unsigned(r24du), $unsigned(r24du));

    $display("");
    $display("signed/unsigned multiplication:");
    r24ws = $signed(m12a) * $unsigned(m12b);
    r24ds = $signed(m12a) * $unsigned(m12b);
    $display("r24ws = 0x%h = %d", $signed(r24ws), $signed(r24ws));
    $display("r24ds = 0x%h = %d", $signed(r24ds), $signed(r24ds));

    $display("");
    $display("multiplier inputsized decimal literals:");
    $display("a = 0x%h = %d, b = 0x%h = %d", -12'sd513, -12'sd513, 12'd3583, 12'd3583);
    /* verilator lint_off WIDTH */
    r24ws = -12'sd513 * 12'd3583;
    r24ds = -12'sd513 * 12'd3583;
    /* verilator lint_on WIDTH */
    $display("r24ws = 0x%h = %d", $signed(r24ws), $signed(r24ws));
    $display("r24ds = 0x%h = %d", $signed(r24ds), $signed(r24ds));

    $display("");
    $display("multiplier input sized hex literals:");
    $display("a = 0x%h = %d, b = 0x%h = %d", -12'sh201, -12'sh201, 12'hdff, 12'hdff);
    /* verilator lint_off WIDTH */
    r24ws = -12'sh201 * 12'hdff;
    r24ds = -12'sh201 * 12'hdff;
    /* verilator lint_on WIDTH */
    $display("r24ws = 0x%h = %d", $signed(r24ws), $signed(r24ws));
    $display("r24ds = 0x%h = %d", $signed(r24ds), $signed(r24ds));

    $finish();
  end

endmodule
