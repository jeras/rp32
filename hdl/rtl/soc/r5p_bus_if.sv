///////////////////////////////////////////////////////////////////////////////
// R5P: system bus interface
///////////////////////////////////////////////////////////////////////////////

interface r5p_bus_if #(
  int unsigned AW = 32,    // address width
  int unsigned DW = 32,    // data    width
  int unsigned BW = DW/8   // benect  width
)(
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
);

// system bus
logic          vld;  // valid
logic          wen;  // write enable
logic [AW-1:0] adr;  // address
logic [BW-1:0] ben;  // byte enable
logic [DW-1:0] wdt;  // write data
logic [DW-1:0] rdt;  // read data
logic          rdy;  // ready

// manager
modport  man (
  // system signals
  input  clk,
  input  rst,
  // system bus
  output vld,
  output wen,
  output adr,
  output ben,
  output wdt,
  input  rdt,
  input  rdy
);

// subordinate
modport  sub (
  // system signals
  input  clk,
  input  rst,
  // system bus
  input  vld,
  input  wen,
  input  adr,
  input  ben,
  input  wdt,
  output rdt,
  output rdy
);

endinterface: r5p_bus_if