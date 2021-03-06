////////////////////////////////////////////////////////////////////////////////
// r5p system bus monitor
////////////////////////////////////////////////////////////////////////////////

module r5p_bus_mon #(
  int unsigned AW = 32,    // address width
  int unsigned DW = 32,    // data    width
  int unsigned BW = DW/8   // benect  width
)(
  // system signals
  input  logic          clk,  // clock
  input  logic          rst,  // reset
  // system bus
  input  logic          req,  // request
  input  logic          wen,  // write enable
  input  logic [AW-1:0] adr,  // address
  input  logic [BW-1:0] ben,  // byte enable
  input  logic [DW-1:0] wdt,  // write data
  input  logic [DW-1:0] rdt,  // read data
  input  logic          ack   // acknowledge
);

import riscv_asm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// system bus delayed by one clock period
logic          req_r;
logic          wen_r;
logic [AW-1:0] adr_r;
logic [BW-1:0] ben_r;
logic [DW-1:0] wdt_r;
logic [DW-1:0] rdt_r;
logic          ack_r;

// delayed signals
always_ff @(posedge clk, posedge rst)
if (rst) begin
  req_r <= '0;
  wen_r <= 'x;
  ben_r <= 'x;
  adr_r <= 'x;
  wdt_r <= 'x;
  rdt_r <= 'x;
  ack_r <= '0;
end else begin
  req_r <= req;
  wen_r <= wen;
  ben_r <= ben;
  adr_r <= adr;
  wdt_r <= wdt;
  rdt_r <= rdt;
  ack_r <= ack;
end

////////////////////////////////////////////////////////////////////////////////
// protocol check
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// debug
////////////////////////////////////////////////////////////////////////////////

// write access
always @(posedge clk)
if (req & ack & wen) begin
  $display("W: adr=0x%h dat=0x%h ben=0b%b, txt=%s", adr, wdt, ben, wdt, disasm(wdt));
end

// read access
always @(posedge clk)
if (req_r & ack_r & ~wen_r) begin
  $display("R: adr=0x%h dat=0x%h ben=0b%b, txt=%s", adr_r, rdt, ben_r, rdt, disasm(rdt));
end

////////////////////////////////////////////////////////////////////////////////
// statistics
////////////////////////////////////////////////////////////////////////////////

// TODO add delay counter, statistics


endmodule: r5p_bus_mon