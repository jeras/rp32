////////////////////////////////////////////////////////////////////////////////
// RISC-V testbench for core module
// R5P Degu as DUT
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
  isa_t        ISA = '{spec: RV32IC, priv: MODES_NONE},
`endif
  // instruction bus
  int unsigned IAW = 22,     // instruction address width
  int unsigned IDW = 32,     // instruction data    width
  // data bus
  int unsigned DAW = 22,     // data address width
  int unsigned DDW = XLEN,   // data data    width
  int unsigned DBW = DDW/8,  // data byte en width
  // memory configuration
  string       IFN = "",     // instruction memory file name
  // testbench parameters
  bit          ABI = 1'b1    // enable ABI translation for GPIO names
)();

import tcb_pkg::*;
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

localparam tcb_par_phy_t PHY_IFU = '{
  // protocol
  DLY: 1,
  // signal bus widths
  SLW: TCB_PAR_PHY_DEF.SLW,
  ABW: IAW,
  DBW: IDW,
  ALW: $clog2(IDW/TCB_PAR_PHY_DEF.SLW),
  // size/mode/order parameters
  SIZ: TCB_PAR_PHY_DEF.SIZ,
  MOD: TCB_PAR_PHY_DEF.MOD,
  ORD: TCB_PAR_PHY_DEF.ORD,
  // channel configuration
  CHN: TCB_PAR_PHY_DEF.CHN
};

localparam tcb_par_phy_t PHY_LSU = '{
  // protocol
  DLY: 1,
  // signal bus widths
  SLW: TCB_PAR_PHY_DEF.SLW,
  ABW: DAW,
  DBW: DDW,
  ALW: $clog2(DDW/TCB_PAR_PHY_DEF.SLW),
  // size/mode/order parameters
  SIZ: TCB_PAR_PHY_DEF.SIZ,
  MOD: TCB_PAR_PHY_DEF.MOD,
  ORD: TCB_PAR_PHY_DEF.ORD,
  // channel configuration
  CHN: TCB_PAR_PHY_DEF.CHN
};

// system busses
tcb_if #(PHY_IFU) tcb_ifu         (.clk (clk), .rst (rst));  // instruction fetch unit
tcb_if #(PHY_LSU) tcb_lsu         (.clk (clk), .rst (rst));  // load/store unit
tcb_if #(PHY_LSU) tcb_dmx [2-1:0] (.clk (clk), .rst (rst));  // demultiplexer
tcb_if #(PHY_LSU) tcb_mem [2-1:0] (.clk (clk), .rst (rst));

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

r5p_degu #(
  // RISC-V ISA
  .XLEN (XLEN),
  .ISA  (ISA)
) DUT (
  // system signals
  .clk  (clk),
  .rst  (rst),
  // system bus
  .ifb  (tcb_ifu),
  .lsb  (tcb_lsu)
);

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

logic [2-1:0] tcb_lsu_sel;

// decoding memory/controller
tcb_lib_decoder #(
  .PHY (PHY_LSU),
  .SPN (2),
  .DAM ({{2'b1x, 20'hxxxxx},   // 0x20_0000 ~ 0x2f_ffff - controller
         {2'b0x, 20'hxxxxx}})  // 0x00_0000 ~ 0x1f_ffff - data memory
) tcb_lsu_dec (
  .tcb  (tcb_lsu    ),
  .sel  (tcb_lsu_sel)
);

// demultiplexing memory/controller
tcb_lib_demultiplexer #(
  .MPN (2)
) tcb_lsu_demux (
  // control
  .sel  (tcb_lsu_sel),
  // TCB interfaces
  .sub  (tcb_lsu),
  .man  (tcb_dmx)
);

// passthrough TCB interfaces to array
tcb_lib_passthrough tcb_pas_ifu (
  .sub  (tcb_ifu),
  .man  (tcb_mem[0])
);
tcb_lib_passthrough tcb_pas_lsu (
  .sub  (tcb_dmx[0]),
  .man  (tcb_mem[1])
);

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

tcb_vip_mem #(
  .FN   (IFN),
  .SIZ  (2**IAW)
) mem (
  .tcb  (tcb_mem[0:0])
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
end else if (bus_mem[1].trn) begin
  if (bus_mem[1].req.wen) begin
    // write access
    case (bus_mem[1].req.adr[5-1:0])
      5'h00:  rvmodel_data_begin <= bus_mem[1].req.wdt;
      5'h08:  rvmodel_data_end   <= bus_mem[1].req.wdt;
      5'h10:  rvmodel_halt       <= bus_mem[1].req.wdt[0];
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
// TODO: add another clock cycle to avoid cutting off delayed printout from TCB monitor
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

localparam int unsigned AW = 5;

logic [XLEN-1:0] gpr_tmp [0:2**AW-1];
logic [XLEN-1:0] gpr_dly [0:2**AW-1] = '{default: '0};

// hierarchical path to GPR inside RTL
//assign gpr_tmp = top.riscv_tb.DUT.gpr.gen_default.gpr;
assign gpr_tmp = riscv_tb.DUT.gpr.gen_default.gpr;

// GPR change log
always_ff @(posedge clk)
begin
  // delayed copy of all GPR
  gpr_dly <= gpr_tmp;
  // check each GPR for changes
  for (int unsigned i=0; i<32; i++) begin
    if (gpr_dly[i] != gpr_tmp[i]) begin
      $display("%t, Info   %8h <= %s <= %8h", $time, gpr_dly[i], gpr_n(i[5-1:0], 1'b1), gpr_tmp[i]);
    end
  end
end

// instruction fetch monitor
tcb_mon_riscv #(
  .NAME ("IFU"),
  .DLY_IFU (1),
  .ISA  (ISA),
  .ABI  (ABI)
) mon_if (
  // debug mode enable (must be active with VALID)
  .dbg_ifu (1'b1),
  .dbg_lsu (1'b0),
  .dbg_gpr (1'b0),
  // system bus
  .bus  (bus_if)
);

// load/store monitor
tcb_mon_riscv #(
  .NAME ("LSU"),
  .DLY_LSU (0),
  .ISA  (ISA),
  .ABI  (ABI)
) mon_ls (
  // debug mode enable (must be active with VALID)
  .dbg_ifu (1'b0),
  .dbg_lsu (1'b1),
  .dbg_gpr (1'b0),
  // system bus
  .bus  (bus_ls)
);

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
