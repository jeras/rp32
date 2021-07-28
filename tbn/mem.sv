////////////////////////////////////////////////////////////////////////////////
// memory model
////////////////////////////////////////////////////////////////////////////////

module mem #(
  isa_t        ISA = '{RV_64I, RV_M},
  // 1kB by default
  string       FN  = "",          // binary initialization file name
  int unsigned SZ  = 2**12,       // memory size in bytes
  // debug functionality
  string       DBG = "",          // module name to be printed in messages, if empty debug is disabled
  bit          TXT = 1'b0,        // print out ASCII text
  bit          OPC = 1'b0         // print out RISC-V operation code
)(
  r5p_bus_if.sub s                // system bus subordinate port  (master device connects here)
);

import riscv_isa_pkg::*;
import riscv_asm_pkg::*;

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
  for (int unsigned addr=start_addr; addr<finish_addr; addr+=4) begin
//    if (s.DW == 32) begin
      $fwrite(fd, "%h%h%h%h\n", mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]);
//    end else begin
//      $fwrite(fd, "%h%h%h%h%h%h%h%h\n", mem[addr+7], mem[addr+6], mem[addr+5], mem[addr+4], mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]);
//    end
  end
  $fclose(fd);
  return code;
endfunction: write_hex

////////////////////////////////////////////////////////////////////////////////
// write/read access
////////////////////////////////////////////////////////////////////////////////

always @(posedge s.clk)
if (s.vld) begin
  if (s.wen) begin
    // write access
    for (int unsigned i=0; i<s.BW; i++) begin
      if (s.ben[i])  mem[int'(s.adr)+i] <= s.wdt[8*i+:8];
    end
  end else begin
    // read access
    for (int unsigned i=0; i<s.BW; i++) begin
      if (s.ben[i])  s.rdt[8*i+:8] <= mem[int'(s.adr)+i];
      else           s.rdt[8*i+:8] <= 'x;
    end
  end
end

////////////////////////////////////////////////////////////////////////////////
// bs.rdypressure
////////////////////////////////////////////////////////////////////////////////

// trivial s.rdynowledge
assign s.rdy = 1'b1;
//always @(posedge clk)
//  s.rdy <= s.vld;

////////////////////////////////////////////////////////////////////////////////
// write/read debug printout
////////////////////////////////////////////////////////////////////////////////

generate
if (DBG != "") begin

logic [s.DW-1:0] dat;

always @(posedge s.clk)
if (s.vld) begin
  if (s.wen) begin
    // write access
    for (int unsigned i=0; i<s.BW; i++) begin
      if (s.ben[i])  dat[8*i+:8] = s.wdt[8*i+:8];
      else           dat[8*i+:8] = s.wdt[8*i+:8];
    end
  end else begin
    // read access
    for (int unsigned i=0; i<s.BW; i++) begin
      if (s.ben[i])  dat[8*i+:8] = mem[int'(s.adr)+i];
      else           dat[8*i+:8] = mem[int'(s.adr)+i];
    end
  end
  $write("%s %s: s.adr=0x%h dat=0x%h s.ben=0b%b", DBG, s.wen ? "W" : "R", s.adr, dat, s.ben);
  if (TXT) $write(" txt='%s'", dat);
  if (OPC) $write(" opc='%s'", disasm(ISA, dat[32-1:0]));
  $write("\n");
end

end
endgenerate

endmodule: mem