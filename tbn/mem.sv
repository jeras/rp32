////////////////////////////////////////////////////////////////////////////////
// memory model
////////////////////////////////////////////////////////////////////////////////

module mem #(
  // 1kB by default
  string       FN = "",          // binary initialization file name
  int unsigned DW = 32,          // data    width
  int unsigned SW = DW/8,        // select  width
  int unsigned SZ = 2**12,       // memory size in bytes
  int unsigned AW = $clog2(SZ),  // address width
  // debug functionality
  string       DBG = "",         // module name to be printed in messages, if empty debug is disabled
  bit          TXT = 1'b0,       // print out ASCII text
  bit          OPC = 1'b0        // print out RISC-V operation code
)(
  input  logic                 clk,  // clock
  input  logic                 req,  // write or read request
  input  logic                 wen,  // write enable
  input  logic [SW-1:0]        sel,  // byte select
  input  logic [AW-1:0]        adr,  // address
  input  logic [SW-1:0][8-1:0] wdt,  // write data
  output logic [SW-1:0][8-1:0] rdt,  // read data
  output logic                 ack   // write or read acknowledge
);

import riscv_asm_pkg::*;

// word address width
localparam int unsigned WW = $clog2(SW);

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

logic [8-1:0] mem [0:SZ-1];

// initialization
initial
if (FN!="") begin
  int code;  // status code
  int fd;    // file descriptor
  fd = $fopen(FN, "rb");
  code = $fread(mem, fd);
  $fclose(fd);
end

////////////////////////////////////////////////////////////////////////////////
// write/read access
////////////////////////////////////////////////////////////////////////////////

always @(posedge clk)
if (req) begin
  if (wen) begin
    // write access
    for (int unsigned i=0; i<SW; i++) begin
      if (sel[i])  mem[int'(adr)+i] <= wdt[i];
    end
  end else begin
    // read access
    for (int unsigned i=0; i<SW; i++) begin
      if (sel[i])  rdt[i] <= mem[int'(adr)+i];
      else         rdt[i] <= 'x;
    end
  end
end

////////////////////////////////////////////////////////////////////////////////
// backpressure
////////////////////////////////////////////////////////////////////////////////

// trivial acknowledge
assign ack = 1'b1;
//always @(posedge clk)
//  ack <= req;

////////////////////////////////////////////////////////////////////////////////
// write/read debug printout
////////////////////////////////////////////////////////////////////////////////

generate
if (DBG != "") begin

logic [SW-1:0][8-1:0] dat;

always @(posedge clk)
if (req) begin
  if (wen) begin
    // write access
    for (int unsigned i=0; i<SW; i++) begin
      if (sel[i])  dat[i] = wdt[i];
      else         dat[i] = wdt[i];
    end
  end else begin
    // read access
    for (int unsigned i=0; i<SW; i++) begin
      if (sel[i])  dat[i] = mem[int'(adr)+i];
      else         dat[i] = mem[int'(adr)+i];
    end
  end
  $write("%s %s: adr=0x%08h dat=0x0%h sel=0b%0b", DBG, wen ? "W" : "R", adr, dat, sel);
  if (TXT) $write(" txt='%s'", dat);
  if (OPC) $write(" opc='%s'", riscv_disasm(dat));
  $write("\n");
end

end
endgenerate

endmodule: mem