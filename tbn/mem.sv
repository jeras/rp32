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

// asynchronous read data
//logic [SW-1:0][8-1:0] adt;

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

logic [8-1:0] mem [0:SZ-1];

// initialization
initial
if (FN!="") begin
  void'(read_bin(FN));
end

// read binary into memory
function int read_bin (
  string fn
);
  int code;  // status code
  int fd;    // file descriptor
  fd = $fopen(fn, "rb");
  code = $fread(mem, fd);
  $fclose(fd);
  return code;
endfunction: read_bin

// dump
function int write_hex (
  string fn,
  int unsigned start_addr = 0,
  int unsigned finish_addr = SZ-1
);
  int code;  // status code
  int fd;    // file descriptor
  fd = $fopen(fn, "w");
  for (int unsigned addr=start_addr; addr<finish_addr; addr+=SW) begin
    $fwrite(fd, "%h%h%h%h\n", mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]);
  end
  $fclose(fd);
  return code;
endfunction: write_hex

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
  $write("%s %s: adr=0x%h dat=0x%h sel=0b%b", DBG, wen ? "W" : "R", adr, dat, sel);
  if (TXT) $write(" txt='%s'", dat);
  if (OPC) $write(" opc='%s'", riscv_disasm(dat));
  $write("\n");
end

end
endgenerate

endmodule: mem