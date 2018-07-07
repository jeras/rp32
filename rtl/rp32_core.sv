module rp32_core #(
  // program bus
  int unsigned PAW = 32,  // program address width
  int unsigned PDW = 32,  // program data    width
  // data bus
  int unsigned DAW = 32,  // data    address width
  int unsigned DDW = 32   // data    data    width
)(
  // system signals
  input  logic           clk,
  input  logic           rst_n,
  // program bus (instruction fetch)
  output logic           bup_req,
  output logic [PAW-1:0] bup_adr,
  input  logic [PDW-1:0] bup_dat,
  input  logic           bup_ack,
  // data bus (load/store)
  output logic                 req, // write or read request
  output logic                 wen, // write enable
  output logic [SW-1:0]        sel, // byte select
  output logic [AW-1:0]        adr, // address
  output logic [SW-1:0][8-1:0] wdt, // write data
  input  logic [SW-1:0][8-1:0] rdt  // read data
  input  logic                 ena, // write or read enable
);

///////////////////////////////////////////////////////////////////////////////
// instruction fetch
///////////////////////////////////////////////////////////////////////////////

// request becomes active after reset
always_ff @ (posedge clk, negedge rst_n)
if (~rst_n)  bus_if_req <= 1'b0;
else         bus_if_req <= 1'b1;

// program counter
always_ff @ (posedge clk, negedge rst_n)
if (~rst_n)  bus_if_adr <= 0;
else         bus_if_adr <= bus_if_adr + 1;

endmodule rp32_core
