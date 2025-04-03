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

module r5p_degu_riscv_tb
  import riscv_isa_pkg::*;
  import tcb_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  // RISC-V ISA
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
//  isa_ext_t    XTEN = RV_M | RV_C | RV_Zicsr,
  isa_ext_t    XTEN = RV_M | RV_Zicsr,
  // privilige modes
  isa_priv_t   MODES = MODES_M,
  // ISA
`ifdef ENABLE_CSR
  isa_t        ISA = '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES},
`else
  isa_t        ISA = '{spec: RV32IC, priv: MODES_NONE},
`endif
  // memory size
  int unsigned MEM_SIZ = 2**22,
  // memory configuration
  string       IFN = "",     // instruction memory file name
  // testbench parameters
  bit          ABI = 1'b1    // enable ABI translation for GPIO names
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
    /* verilator lint_off INITIALDLY */
    repeat (4) @(posedge clk);
    // synchronous reset release
    rst <= 1'b0;
    repeat (10000) @(posedge clk);
    timeout <= 1'b1;
    repeat (4) @(posedge clk);
    $finish();
    /* verilator lint_on INITIALDLY */
  end

  // time counter
  always_ff @(posedge clk, posedge rst)
  if (rst) begin
    cnt <= 0;
  end else begin
    cnt <= cnt+1;
  end  

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

  localparam tcb_par_phy_t TCB_PHY_IFU = '{
    // protocol
    DLY: 1,
    // signal widths
    SLW: 8,
    ABW: XLEN,
    DBW: XLEN,
    ALW: $clog2(XLEN/8),   // $clog2(DBW/SLW) // TODO: could be 16-bit allignment
    // data packing parameters
    MOD: TCB_MEMORY,
    ORD: TCB_DESCENDING,
    // channel configuration
    CHN: TCB_COMMON_HALF_DUPLEX
  };

  localparam tcb_par_phy_t TCB_PHY_LSU = '{
    // protocol
    DLY: 1,
    // signal bus widths
    SLW: 8,
    ABW: XLEN,
    DBW: XLEN,
    ALW: $clog2(XLEN/8),   // $clog2(DBW/SLW)
    // data packing parameters
    MOD: TCB_MEMORY,
    ORD: TCB_DESCENDING,
    // channel configuration
    CHN: TCB_COMMON_HALF_DUPLEX
  };

  // system busses
  tcb_if #(TCB_PHY_IFU) tcb_ifu         (.clk (clk), .rst (rst));  // instruction fetch unit
  tcb_if #(TCB_PHY_LSU) tcb_lsu         (.clk (clk), .rst (rst));  // load/store unit
  tcb_if #(TCB_PHY_LSU) tcb_mem [2-1:0] (.clk (clk), .rst (rst));  // 2 port memory model

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

  localparam [XLEN-1:0] IFU_RST = 32'h8000_0000;
  localparam [XLEN-1:0] IFU_MSK = 32'h803f_ffff;

  r5p_degu #(
    // RISC-V ISA
    .ISA  (ISA),
    // system bus implementation details
    .IFU_RST (IFU_RST),
    .IFU_MSK (IFU_MSK)
  ) dut (
    // system signals
    .clk      (clk),
    .rst      (rst),
    // TCB system bus
    .tcb_ifu  (tcb_ifu),
    .tcb_lsu  (tcb_lsu)
  );

////////////////////////////////////////////////////////////////////////////////
// protocol checker
////////////////////////////////////////////////////////////////////////////////

//  tcb_vip_protocol_checker tcb_mon_ifu (
//    .tcb  (tcb_ifu)
//  );
//
//  tcb_vip_protocol_checker tcb_mon_lsu (
//    .tcb  (tcb_lsu)
//  );

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

  // passthrough TCB interfaces to array
  tcb_lib_passthrough tcb_pas_ifu (
    .sub  (tcb_ifu),
    .man  (tcb_mem[0])
  );
  tcb_lib_passthrough tcb_pas_lsu (
    .sub  (tcb_lsu),
    .man  (tcb_mem[1])
  );

  tcb_vip_memory #(
    .MFN  (IFN),
    .SPN  (2),
    .SIZ  (MEM_SIZ)
  ) mem (
    .tcb  (tcb_mem[1:0])
  );

  // memory initialization file is provided at runtime
  initial
  begin
    string fn;
    if ($value$plusargs("firmware=%s", fn)) begin
      $display("Loading file into memory: %s", fn);
      void'(mem.read_bin(fn));
    end else if (IFN == "") begin
      $display("ERROR: memory load file argument not found.");
      $finish;
    end
  end

////////////////////////////////////////////////////////////////////////////////
// ELF file symbols
////////////////////////////////////////////////////////////////////////////////

  // symbol addresses
  logic [32-1:0] begin_signature;
  logic [32-1:0] end_signature  ;
  logic [32-1:0] tohost         ;
  logic [32-1:0] fromhost       ;

  initial
  begin
    // get ELF symbols from plusargs
    void'($value$plusargs("begin_signature=%0h", begin_signature));
    void'($value$plusargs("end_signature=%0h"  , end_signature  ));
    void'($value$plusargs("tohost=%0h"         , tohost         ));
    void'($value$plusargs("fromhost=%0h"       , fromhost       ));
    // mask signature symbols with memory size
    begin_signature = begin_signature & (MEM_SIZ-1);
    end_signature   = end_signature   & (MEM_SIZ-1);
    // display ELF symbols
    $display("begin_signature=%08h", begin_signature);
    $display("end_signature  =%08h", end_signature  );
    $display("tohost         =%08h", tohost         );
    $display("fromhost       =%08h", fromhost       );
  end

////////////////////////////////////////////////////////////////////////////////
// controller
////////////////////////////////////////////////////////////////////////////////

  logic rvmodel_halt = 1'b0;

  always_ff @(posedge clk, posedge rst)
  if (rst) begin
    rvmodel_halt <= 1'b0;
  end else if (tcb_lsu.trn) begin
    if (tcb_lsu.req.wen) begin
      // HTIF tohost
      if (tcb_lsu.req.adr == tohost) rvmodel_halt <= tcb_lsu.req.wdt[0];
    end
  end

  // finish simulation
  always @(posedge clk)
  if (rvmodel_halt | timeout) begin
    string fn;  // file name
    if (rvmodel_halt)  $display("HALT");
    if (timeout     )  $display("TIMEOUT");
    if ($value$plusargs("signature=%s", fn)) begin
      $display("Saving signature file with data from 0x%8h to 0x%8h: %s", begin_signature, end_signature, fn);
      mem.write_hex(fn, int'(begin_signature), int'(end_signature));
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
    $display("TIME: cnt = %d", cnt);
  end

////////////////////////////////////////////////////////////////////////////////
// Verbose execution trace
////////////////////////////////////////////////////////////////////////////////

`ifdef TRACE_DEBUG

  // TODO: instead of an address width decode the ISA
  localparam int unsigned AW = 5;

  logic [XLEN-1:0] gpr_tmp [0:2**AW-1];
  logic [XLEN-1:0] gpr_dly [0:2**AW-1] = '{default: '0};

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

  // instruction fetch and load/store bus monitor
  r5p_degu_tcb_mon #(
    .ISA  (ISA),
    .ABI  (ABI)
  ) r5p_mon (
    // GPR register file array
    // hierarchical path to GPR inside RTL
    .gpr_wen  (dut.gpr.e_rd),
    .gpr_wid  (dut.gpr.a_rd),
    .gpr_wdt  (dut.gpr.d_rd),
    // TCB IFU/LSU system busses
    .tcb_ifu  (tcb_ifu),
    .tcb_lsu  (tcb_lsu)
  );

  // open log file with filename obtained through plusargs
  initial
  begin
    string fn;  // file name
    if ($value$plusargs("log=%s", fn)) begin
      r5p_mon.fd = $fopen(fn, "w");
    end
  end

`endif

////////////////////////////////////////////////////////////////////////////////
// Waveforms
////////////////////////////////////////////////////////////////////////////////

  initial begin
    $dumpfile("wave.fst");
    $dumpvars(0);
  end

endmodule: r5p_degu_riscv_tb

