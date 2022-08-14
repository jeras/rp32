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

module tcb_mem_1p #(
  // 1kB by default
  string       FN = "",     // binary initialization file name
  int unsigned SZ = 2**12,  // memory size in bytes
  // byte enable options
  bit          CFG_BEN_RD = 1'bx
)(
  tcb_if.sub bus
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
// RTL
////////////////////////////////////////////////////////////////////////////////

always @(posedge bus.clk)
if (bus.vld) begin
  if (bus.wen) begin
    // write access
    for (int unsigned b=0; b<bus.BW; b++) begin
      if (bus.ben[b])  mem[int'(bus.adr)+b] <= bus.wdt[8*b+:8];
    end
  end else begin
    // read access
    for (int unsigned b=0; b<bus.BW; b++) begin
      if (bus.ben[b] ==? CFG_BEN_RD)  bus.rdt[8*b+:8] <= mem[int'(bus.adr)+b];
      else                            bus.rdt[8*b+:8] <= 'x;
    end
  end
end

// trivial ready
assign bus.rdy = 1'b1;
//always @(posedge clk)
//  bus.rdy <= bus.vld;

endmodule: tcb_mem_1p