////////////////////////////////////////////////////////////////////////////////
// memory inference RTL
////////////////////////////////////////////////////////////////////////////////

module r5p_soc_mem #(
  // 1kB by default
  string       FN = "",     // binary initialization file name
  int unsigned DW = 32,     // data width
  int unsigned SW = 32/8,   // byte select width
  int unsigned SZ = 2**12,  // memory size in bytes
)(
  r5p_bus_if.sub bus,   // instruction fetch
);

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

logic [8-1:0] mem [0:SZ-1];

////////////////////////////////////////////////////////////////////////////////
// instruction fetch
////////////////////////////////////////////////////////////////////////////////

always @(posedge bus_if.clk)
if (bus_if.vld) begin
  if (bus_if.wen) begin
//  // write access
//  for (int unsigned b=0; b<bus_if.BW; b++) begin
//    if (bus_if.ben[b])  mem[int'(bus_if.adr)+b] <= bus_if.wdt[8*b+:8];
//  end
  end else begin
    // read access
    for (int unsigned b=0; b<bus_if.BW; b++) begin
      if (bus_if.ben[b])  bus_if.rdt[8*b+:8] <= mem[int'(bus_if.adr)+b];
      else                bus_if.rdt[8*b+:8] <= 'x;
    end
  end
end

// trivial ready
assign bus_if.rdy = 1'b1;
//always @(posedge clk)
//  bus_if.rdy <= bus_if.vld;

////////////////////////////////////////////////////////////////////////////////
// load/store
////////////////////////////////////////////////////////////////////////////////

always @(posedge bus_ls.clk)
if (bus_ls.vld) begin
  if (bus_ls.wen) begin
    // write access
    for (int unsigned b=0; b<bus_ls.BW; b++) begin
      if (bus_ls.ben[b])  mem[int'(bus_ls.adr)+b] <= bus_ls.wdt[8*b+:8];
    end
  end else begin
    // read access
    for (int unsigned b=0; b<bus_ls.BW; b++) begin
      if (bus_ls.ben[b])  bus_ls.rdt[8*b+:8] <= mem[int'(bus_ls.adr)+b];
      else                bus_ls.rdt[8*b+:8] <= 'x;
    end
  end
end

assign bus_ls.rdy = 1'b1;

endmodule: r5p_soc_mem