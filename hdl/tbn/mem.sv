////////////////////////////////////////////////////////////////////////////////
// memory model
////////////////////////////////////////////////////////////////////////////////
// Copyright 2022 Iztok Jeras
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////////

import riscv_isa_pkg::*;
import riscv_asm_pkg::*;

module mem #(
  // 1kB by default
  string       FN = "",    // binary initialization file name
  int unsigned SZ = 2**12  // memory size in bytes
)(
  r5p_bus_if.sub bus_if,   // instruction fetch
  r5p_bus_if.sub bus_ls    // load store
);

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

// TODO: detect Xilinx Vivado simulator instead
`ifdef VERILATOR
logic [8-1:0] mem [0:SZ-1];  // 4194304
`else
logic [8-1:0] mem [0:1757700-1];
`endif

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
  bit [640-1:0] err;
  fd = $fopen(fn, "rb");
  code = $fread(mem, fd);
`ifndef VERILATOR
  if (code == 0) begin
    code = $ferror(fd, err);
    $display("DEBUG: read_bin: code = %d, err = %s", code, err);
  end else begin
    $display("DEBUG: read %dB from binary file", code);
  end
`endif
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

endmodule: mem