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

logic [SW-1:0][8-1:0] mem [0:SZ/SW-1];

// initialization
initial
if (FN!="") begin
//  if FN[] == ".bin" begin
  void'(read_bin(FN));
end

// read binary into memory
function int read_bin (
  string fn
);
  bit [8-1:0] tmp [0:SZ-1];
  int code;  // status code
  int fd;    // file descriptor
  fd = $fopen(fn, "rb");
  code = $fread(tmp, fd);
  $fclose(fd);
  // SystemVerilog LRM 1800-2017 section 21.3.4.4
  // defines $fread as loading data in a *big endian* manner
  // a byte swap is needed to achieve the desired little endian order
  for (int unsigned a=0; a<SZ; a+=SW) begin
    for (int unsigned i=0; i<SW; i++) begin
      mem[a/SW][i] = tmp[a+i];
    end
  end
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
    $fwrite(fd, "%h\n", mem[addr/SW]);
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
      if (sel[i])  mem[int'(adr)/SW][i] <= wdt[i];
    end
  end else begin
    // read access
    for (int unsigned i=0; i<SW; i++) begin
      if (sel[i])  rdt[i] <= mem[int'(adr)/SW][i];
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
      if (sel[i])  dat[i] = mem[int'(adr)/SW][i];
      else         dat[i] = mem[int'(adr)/SW][i];
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