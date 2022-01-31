////////////////////////////////////////////////////////////////////////////////
// memory model
////////////////////////////////////////////////////////////////////////////////

module mem #(
  isa_t        ISA = '{RV_64I, RV_M},
  // number of interfaces
  int unsigned IN  = 1,
  // 1kB by default
  string       FN  = "",     // binary initialization file name
  int unsigned SZ  = 2**12,  // memory size in bytes
  // debug functionality
  string       DBG = ""      // module name to be printed in messages, if empty debug is disabled
)(
  r5p_bus_if.sub bus_if,   // instruction fetch
  r5p_bus_if.sub bus_ls    // load store
);

import riscv_isa_pkg::*;
import riscv_asm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

logic [8-1:0] mem [0:SZ-1];

// initialization
initial
begin
  if (FN!="") begin
    void'(read_bin(FN));
  end
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

// trivial ready
assign bus_ls.rdy = 1'b1;
//always @(posedge clk)
//  bus_ls.rdy <= bus_ls.vld;

////////////////////////////////////////////////////////////////////////////////
// write/read debug printout
////////////////////////////////////////////////////////////////////////////////

generate
if (DBG != "") begin: debug

  logic [bus_if.DW-1:0] dat_if;

  always @(posedge bus_if.clk)
  if (bus_if.vld) begin
    if (bus_if.wen) begin
      // write access
      for (int unsigned b=0; b<bus_if.BW; b++) begin
        if (bus_if.ben[b])  dat_if[8*b+:8] = bus_if.wdt[8*b+:8];
        else                dat_if[8*b+:8] = bus_if.wdt[8*b+:8];
      end
    end else begin
      // read access
      for (int unsigned b=0; b<bus_if.BW; b++) begin
        if (bus_if.ben[b])  dat_if[8*b+:8] = mem[int'(bus_if.adr)+b];
        else                dat_if[8*b+:8] = mem[int'(bus_if.adr)+b];
      end
    end
    $write("%s (IF) %s: s.adr=0x%h dat=0x%h s.ben=0b%b", DBG, bus_if.wen ? "W" : "R", bus_if.adr, dat_if, bus_if.ben);
    $write(" opc='%s'\n", disasm(ISA, dat_if, .abi (1)));
  end

  logic [bus_ls.DW-1:0] dat_ls;

  always @(posedge bus_ls.clk)
  if (bus_ls.vld) begin
    if (bus_ls.wen) begin
      // write access
      for (int unsigned b=0; b<bus_ls.BW; b++) begin
        if (bus_ls.ben[b])  dat_ls[8*b+:8] = bus_ls.wdt[8*b+:8];
        else                dat_ls[8*b+:8] = bus_ls.wdt[8*b+:8];
      end
    end else begin
      // read access
      for (int unsigned b=0; b<bus_ls.BW; b++) begin
        if (bus_ls.ben[b])  dat_ls[8*b+:8] = mem[int'(bus_ls.adr)+b];
        else                dat_ls[8*b+:8] = mem[int'(bus_ls.adr)+b];
      end
    end
    $write("%s (LS) %s: s.adr=0x%h dat=0x%h s.ben=0b%b", DBG, bus_ls.wen ? "W" : "R", bus_ls.adr, dat_ls, bus_ls.ben);
    $write(" txt='%s'\n", dat_ls);
  end

end: debug
endgenerate

endmodule: mem