////////////////////////////////////////////////////////////////////////////////
// RISC-V testbench for core module
// FemtoRV32 as DUT
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

module riscv_tb
  import riscv_isa_pkg::*;
#(
  // RISC-V ISA
  int unsigned XLEN = 32,    // is used to quickly switch between 32 and 64 for testing
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
  isa_ext_t    XTEN = RV_M | RV_C | RV_Zicsr,
  // privilige modes
  isa_priv_t   MODES = MODES_M,
  // ISA
`ifdef ENABLE_CSR
  isa_t        ISA = XLEN==32 ? '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES}
                   : XLEN==64 ? '{spec: '{base: RV_64I , ext: XTEN}, priv: MODES}
                              : '{spec: '{base: RV_128I, ext: XTEN}, priv: MODES},
`else
  isa_t ISA = '{spec: RV32IC, priv: MODES_NONE},
`endif
  // instruction bus
  int unsigned IAW = 22,     // instruction address width
  int unsigned IDW = 32,     // instruction data    width
  // data bus
  int unsigned DAW = 22,     // data address width
  int unsigned DDW = XLEN,   // data data    width
  int unsigned DAT = DDW/8,  // data byte en width
  // memory configuration
  string       IFN = "",     // instruction memory file name
  // testbench parameters
  bit          ABI = 1'b1    // enable ABI translation for GPR names
)();

import riscv_asm_pkg::*;

// system signals
logic clk = 1'b1;  // clock
logic rst = 1'b1;  // reset

// clock period counter
int unsigned cnt;
bit timeout = 1'b0;

////////////////////////////////////////////////////////////////////////////////
// test sequence
////////////////////////////////////////////////////////////////////////////////

// clock
always #(20ns/2) clk = ~clk;
// reset
initial
begin
  repeat (4) @(posedge clk);
  rst = 1'b0;
  repeat (10000) @(posedge clk);
  $finish();
end

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

tcb_if #(.AW (IAW), .DW (IDW)) bus_if        (.clk (clk), .rst (rst));
tcb_if #(.AW (DAW), .DW (DDW)) bus_ls        (.clk (clk), .rst (rst));
tcb_if #(.AW (DAW), .DW (DDW)) bus_mem [1:0] (.clk (clk), .rst (rst));

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

logic [31:0] mem_addr ;  // address bus
logic [31:0] mem_wdata;  // data to be written
logic  [3:0] mem_wmask;  // write mask for the 4 bytes of each word
logic [31:0] mem_rdata;  // input lines for both data and instr
logic        mem_rstrb;  // active to initiate memory read (used by IO)
logic        mem_rbusy;  // asserted if memory is busy reading value
logic        mem_wbusy;  // asserted if memory is busy writing value

FemtoRV32 #(
  .RESET_ADDR (32'h00000000),
  .ADDR_WIDTH (IAW)
) DUT (
  .clk       ( clk),
  .reset     (~rst),       // set to 0 to reset the processor
  .mem_addr  (mem_addr ),  // address bus
  .mem_wdata (mem_wdata),  // data to be written
  .mem_wmask (mem_wmask),  // write mask for the 4 bytes of each word
  .mem_rdata (mem_rdata),  // input lines for both data and instr
  .mem_rstrb (mem_rstrb),  // active to initiate memory read (used by IO)
  .mem_rbusy (mem_rbusy),  // asserted if memory is busy reading value
  .mem_wbusy (mem_wbusy)   // asserted if memory is busy writing value
);

// instruction fetch
assign bus_if.vld = 1'b0;
assign bus_if.wen = 1'b0;
assign bus_if.adr = '0;
assign bus_if.ben = '1;
assign bus_if.wdt = 'x;

// data load/store
assign bus_ls.vld =      |mem_wmask | mem_rstrb;
assign bus_ls.wen =      |mem_wmask;
assign bus_ls.adr =  IAW'(mem_addr);
assign bus_ls.ben =       mem_wmask | {4{mem_rstrb}};
assign bus_ls.wdt =       mem_wdata;

assign mem_rdata = bus_ls.rdt;
assign mem_rbusy = 1'b0;
assign mem_wbusy = 1'b0;

////////////////////////////////////////////////////////////////////////////////
// GPR change log
////////////////////////////////////////////////////////////////////////////////

localparam int unsigned AW = 5;

logic [XLEN-1:0] gpr_tmp [2**AW-1:0];
logic [XLEN-1:0] gpr_dly [2**AW-1:0] = '{default: '0};

// hierarchical path to GPR inside RTL
//assign gpr_tmp = top.riscv_tb.DUT.gpr.gen_default.gpr;
assign gpr_tmp = riscv_tb.DUT.registerFile;

always_ff @(posedge clk)
begin
  // delayed copy of all GPR
  gpr_dly <= gpr_tmp;
  // check each GPR for changes
  for (int unsigned i=0; i<32; i++) begin
    if (gpr_dly[i] != gpr_tmp[i]) begin
      $display("%t, Info   %s %8h -> %8h", $time, gpr_n(i[5-1:0], 1'b1), gpr_dly[i], gpr_tmp[i]);
    end
  end
end

// TODO: reorder printouts so they are in the same order as instructions.

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

tcb_dec #(
  .AW  (DAW),
  .DW  (DDW),
  .PN  (2),                      // port number
  .AS  ({ {2'b1x, 20'hxxxxx} ,   // 0x00_0000 ~ 0x1f_ffff - data memory
          {2'b0x, 20'hxxxxx} })  // 0x20_0000 ~ 0x2f_ffff - controller
) ls_dec (
  .s  (bus_ls      ),
  .m  (bus_mem[1:0])
);

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

mem #(
  .FN   (IFN),
  .SZ   (2**IAW)
) mem (
  .bus_if  (bus_if),
  .bus_ls  (bus_mem[0])
);

// memory initialization file is provided at runtime
initial
begin
  string fn;
  if ($value$plusargs("FILE_MEM=%s", fn)) begin
    $display("Loading file into memory: %s", fn);
    void'(mem.read_bin(fn));
  end else if (IFN == "") begin
    $display("ERROR: memory load file argument not found.");
    $finish;
  end
end

// TCB monitor
tcb_mon_riscv #(
  .NAME ("IF"),
  .ISA  (ISA),
  .ABI  (ABI)
) mon_if (
  // debug mode enable (must be active with VALID)
  .dbg_ifu (1'b1),
  .dbg_lsu (1'b1),
  .dbg_gpr (1'b0),
  // system bus
  .bus  (bus_ls)
);

////////////////////////////////////////////////////////////////////////////////
// controller
////////////////////////////////////////////////////////////////////////////////

logic [DDW-1:0] rvmodel_data_begin;
logic [DDW-1:0] rvmodel_data_end;
logic           rvmodel_halt = '0;

always_ff @(posedge clk, posedge rst)
if (rst) begin
  rvmodel_data_begin <= 'x;
  rvmodel_data_end   <= 'x;
  rvmodel_halt       <= '0;
end else if (bus_mem[1].vld & bus_mem[1].rdy) begin
  if (bus_mem[1].wen) begin
    // write access
    case (bus_mem[1].adr[5-1:0])
      5'h00:  rvmodel_data_begin <= bus_mem[1].wdt;
      5'h08:  rvmodel_data_end   <= bus_mem[1].wdt;
      5'h10:  rvmodel_halt       <= bus_mem[1].wdt[0];
      default:  ;  // do nothing
    endcase
  end
end

// controller response is immediate
assign bus_mem[1].rdy = 1'b1;

// finish simulation
always @(posedge clk)
if (rvmodel_halt | timeout) begin
  string fn;
  int tmp_begin;
  int tmp_end;
  if (rvmodel_halt)  $display("HALT");
  if (timeout     )  $display("TIMEOUT");
  if (rvmodel_data_end < 2**IAW)  tmp_end = rvmodel_data_end;
  else                            tmp_end = 2**IAW ;
  if ($value$plusargs("FILE_SIG=%s", fn)) begin
    $display("Saving signature file with data from 0x%8h to 0x%8h: %s", rvmodel_data_begin, rvmodel_data_end, fn);
  //void'(mem.write_hex("signature_debug.txt", 'h10000200, 'h1000021c));
    void'(mem.write_hex(fn, int'(rvmodel_data_begin), int'(tmp_end)));
    $display("Saving signature file done.");
  end else begin
    $display("ERROR: signature save file argument not found.");
    $finish;
  end
  $finish;
end

// at the end dump the test signature
// TODO: not working in Verilator, at least if the C code ends the simulation.
final begin
  $display("FINAL");
//void'(mem.write_hex(FILE_SIG, int'(rvmodel_data_begin), int'(rvmodel_data_end)));
  $display("TIME: cnt = %d", cnt);
end

////////////////////////////////////////////////////////////////////////////////
// Verbose execution trace
////////////////////////////////////////////////////////////////////////////////

`ifdef TRACE_DEBUG

// time counter
always_ff @(posedge clk, posedge rst)
if (rst) begin
  cnt <= 0;
end else begin
  cnt <= cnt+1;
end

// timeout
//always @(posedge clk)
//if (cnt > 5000)  timeout <= 1'b1;

`endif

endmodule: riscv_tb
