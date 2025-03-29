////////////////////////////////////////////////////////////////////////////////
// RISC-V testbench for core module
// R5P Mouse as DUT
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
  import tcb_pkg::*;
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
    repeat (20000) @(posedge clk);
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

  localparam tcb_par_phy_t TCB_PAR_PHY = '{
    // protocol
    DLY: 1,
    // signal widths
    SLW: 8,
    ABW: 32,
    DBW: 32,
    ALW: 2,   // $clog2(DBW/SLW)
    // data packing parameters
    MOD: TCB_MEMORY,
    ORD: TCB_DESCENDING,
    // channel configuration
    CHN: TCB_COMMON_HALF_DUPLEX
  };

  tcb_if #(.PHY (TCB_PAR_PHY)) bus [0:0] (.clk (clk), .rst (rst));

  // internal state signals
  logic dbg_ifu;  // indicator of instruction fetch
  logic dbg_lsu;  // indicator of load/store
  logic dbg_gpr;  // indicator of GPR access

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

  r5p_mouse #(
    .SYS_RST (32'h8000_0000),
    .SYS_MSK (32'h803f_ffff),
    .SYS_GPR (32'h801f_ff80)
  ) cpu (
    // system signals
    .clk     (clk),
    .rst     (rst),
    // TCL system bus (shared by instruction/load/store)
    .bus_vld (bus[0].vld),
    .bus_wen (bus[0].req.wen),
    .bus_adr (bus[0].req.adr),
    .bus_ben (bus[0].req.ben),
    .bus_wdt (bus[0].req.wdt),
    .bus_rdt (bus[0].rsp.rdt),
    .bus_err (bus[0].rsp.sts.err),
    .bus_rdy (bus[0].rdy)
  );

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

  tcb_vip_memory #(
    .SPN   (1),
    .SIZ   (MEM_SIZ)
  ) mem (
    .tcb  (bus[0:0])
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
    void'($value$plusargs("begin_signature=%0h", begin_signature));
    void'($value$plusargs("end_signature=%0h"  , end_signature  ));
    void'($value$plusargs("tohost=%0h"         , tohost         ));
    void'($value$plusargs("fromhost=%0h"       , fromhost       ));
    $display("begin_signature=%08h", begin_signature);
    $display("end_signature  =%08h", end_signature  );
    $display("tohost         =%08h", tohost         );
    $display("fromhost       =%08h", fromhost       );
  end

////////////////////////////////////////////////////////////////////////////////
// controller
////////////////////////////////////////////////////////////////////////////////

  logic            rvmodel_halt = '0;

  always_ff @(posedge clk, posedge rst)
  if (rst) begin
    rvmodel_halt       <= '0;
  end else if (bus[0].trn) begin
    if (bus[0].req.wen) begin
      // write access
      case (bus[0].req.adr)
        32'h0020_0010:  rvmodel_halt       <= bus[0].req.wdt[0];
        default:  ;  // do nothing
      endcase
    end
  end

  // finish simulation
  always @(posedge clk)
  if (rvmodel_halt | timeout) begin
    string fn;
    if (rvmodel_halt)  $display("HALT");
    if (timeout     )  $display("TIMEOUT");
    if ($value$plusargs("signature=%s", fn)) begin
      $display("Saving signature file with data from 0x%8h to 0x%8h: %s", begin_signature, end_signature, fn);
      void'(mem.write_hex(fn, int'(begin_signature), int'(end_signature)));
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
    $display("TIME: cnt = %d", cnt);
  end

////////////////////////////////////////////////////////////////////////////////
// Verbose execution trace
////////////////////////////////////////////////////////////////////////////////

`ifdef TRACE_DEBUG

  // GPR array
  logic [32-1:0] gpr [0:32-1];

  // copy GPR array from system memory
  //assign gpr = mem.mem[mem.SZ-32:mem.SZ-1];

  // system bus monitor
  r5p_mouse_tcb_mon #(
    .NAME ("TCB"),
    .ISA  (ISA),
    .ABI  (ABI)
  ) mon_tcb (
  // instruction execution phase
    .pha  (cpu.ctl_pha),
    // system bus
    .bus  (bus[0])
  );

`endif

////////////////////////////////////////////////////////////////////////////////
// Waveforms
////////////////////////////////////////////////////////////////////////////////

  initial begin
    $dumpfile("wave.fst");
    $dumpvars(0);
  end

endmodule: riscv_tb
