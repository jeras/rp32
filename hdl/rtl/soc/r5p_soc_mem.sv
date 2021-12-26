////////////////////////////////////////////////////////////////////////////////
// memory inference RTL
////////////////////////////////////////////////////////////////////////////////

module r5p_soc_mem #(
  // 1kB by default
  string       FN = "",    // binary initialization file name
  int unsigned AW = 12,    // memory size in bytes
  int unsigned DW = 32,    // data width
  int unsigned BW = 32/8   // byte enable width
)(
  r5p_bus_if.sub bus      // instruction fetch
);

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

logic [DW-1:0] mem [0:(2**AW)/BW-1];

initial
begin
  if (FN != "") begin
    $display("DEBUG: loading file %s into %m", FN);
    $readmemh(FN, mem);
  end
end
//initial
//begin
//  mem[0] = 32'h00004e37;
//  mem[1] = 32'h01234eb7;
//  mem[2] = 32'h567e8e93;
//  mem[3] = 32'hfff00f13;
//  mem[4] = 32'h01de2023;
//  mem[5] = 32'h01ee2423;
//  mem[6] = 32'h010e2f83;
//end

////////////////////////////////////////////////////////////////////////////////
// load/store
////////////////////////////////////////////////////////////////////////////////

always @(posedge bus.clk)
if (bus.vld) begin
  if (bus.wen) begin
    // write access
    for (int unsigned b=0; b<bus.BW; b++) begin
      if (bus.ben[b])  mem[bus.adr[AW-1:$clog2(BW)]][8*b+:8] <= bus.wdt[8*b+:8];
    end
  end else begin
    // read access
    bus.rdt <= mem[bus.adr[AW-1:$clog2(BW)]];
//  for (int unsigned b=0; b<bus.BW; b++) begin
//    if (bus.ben[b])  bus.rdt[8*b+:8] <= mem[bus.adr[AW-1:$clog2(BW)]][8*b+:8];
//    else             bus.rdt[8*b+:8] <= 'x;
//  end
  end
end

assign bus.rdy = 1'b1;

endmodule: r5p_soc_mem