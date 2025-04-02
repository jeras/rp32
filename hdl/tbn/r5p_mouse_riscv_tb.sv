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

module r5p_mouse_riscv_tb
  import riscv_isa_pkg::*;
  import tcb_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  localparam int unsigned ILEN = 32,
  // RISC-V ISA
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

  localparam tcb_par_phy_t TCB_PHY = '{
    // protocol
    DLY: 1,
    // signal widths
    SLW: 8,
    ABW: XLEN,
    DBW: XLEN,
    ALW: $clog2(XLEN/8),   // $clog2(DBW/SLW)
    // data packing parameters
    MOD: TCB_RISC_V,
    ORD: TCB_DESCENDING,
    // channel configuration
    CHN: TCB_COMMON_HALF_DUPLEX
  };

  // system busses
  tcb_if #(TCB_PHY) tcb [0:0] (.clk (clk), .rst (rst));

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

  localparam [XLEN-1:0] IFU_RST = 32'h8000_0000;
  localparam [XLEN-1:0] IFU_MSK = 32'h803f_ffff;
  localparam [XLEN-1:0] GPR_ADR = 32'h801f_ff80;

  r5p_mouse #(
    .IFU_RST (IFU_RST),
    .IFU_MSK (IFU_MSK),
    .GPR_ADR (GPR_ADR)
  ) dut (
    // system signals
    .clk     (clk),
    .rst     (rst),
    // TCB system bus (shared by instruction/load/store)
    .tcb_vld ( tcb[0].vld ),
    .tcb_wen ( tcb[0].req.wen ),
    .tcb_adr ( tcb[0].req.adr ),
    .tcb_fn3 ({tcb[0].req.uns,
               tcb[0].req.siz}),
    .tcb_wdt ( tcb[0].req.wdt ),
    .tcb_rdt ( tcb[0].rsp.rdt ),
    .tcb_err ( tcb[0].rsp.sts.err ),
    .tcb_rdy ( tcb[0].rdy )
  );

////////////////////////////////////////////////////////////////////////////////
// protocol checker
////////////////////////////////////////////////////////////////////////////////

  tcb_vip_protocol_checker tcb_mon (
    .tcb  (tcb[0])
  );

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

  tcb_vip_memory #(
    .MFN  (IFN),
    .SPN  (1),
    .SIZ  (MEM_SIZ)
  ) mem (
    .tcb  (tcb[0:0])
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
  end else if (tcb[0].trn) begin
    if (tcb[0].req.wen) begin
      // HTIF tohost
      if (tcb[0].req.adr == tohost) rvmodel_halt <= tcb[0].req.wdt[0];
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
  logic [XLEN-1:0] gpr [0:32-1];

  // copy GPR array from system memory
  // TODO: apply proper streaming operator
  assign gpr = {>> XLEN {mem.mem[GPR_ADR & (MEM_SIZ-1) +: 4*8]}};

  // system bus monitor
  r5p_mouse_tcb_mon #(
    .ISA  (ISA),
    .ABI  (ABI)
  ) r5p_mon (
    // instruction execution phase
    .pha  (dut.ctl_pha),
    // TCB system bus
    .tcb  (tcb[0])
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

endmodule: r5p_mouse_riscv_tb

