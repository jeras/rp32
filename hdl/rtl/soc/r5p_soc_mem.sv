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

//initial
//begin
//  if (FN != "") begin
//    $display("DEBUG: loading file %s into %m", FN);
//    $readmemh(FN, mem);
//  end
//end

////////////////////////////////////////////////////////////////////////////////
// load/store
////////////////////////////////////////////////////////////////////////////////

always @(posedge bus.clk)
if (bus.vld) begin
  if (bus.wen) begin
    // write access
    mem[bus.adr[AW-1:$clog2(BW)]] <= bus.wdt;
//  for (int unsigned b=0; b<bus.BW; b++) begin
//    if (bus.ben[b])  mem[bus.adr[AW-1:$clog2(BW)]][8*b+:8] <= bus.wdt[8*b+:8];
//  end
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