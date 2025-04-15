////////////////////////////////////////////////////////////////////////////////
// R5P Mouse RISC-V conformance testbench
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
  parameter  isa_ext_t    XTEN = '0,
  // privilige modes
  parameter  isa_priv_t   MODES = MODES_M,
  // ISA
`ifdef ENABLE_CSR
  parameter  isa_t        ISA = '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES},
`else
  parameter  isa_t        ISA = '{spec: RV32IC, priv: MODES_NONE},
`endif
  parameter  logic [XLEN-1:0] IFU_RST = 32'h8000_0000,
  parameter  logic [XLEN-1:0] IFU_MSK = 32'h803f_ffff,
  parameter  logic [XLEN-1:0] GPR_ADR = 32'h801f_ff80,
  // memory size
  parameter  int unsigned MEM_SIZ = 2**22,
  // memory configuration
  parameter  string       IFN = "",     // instruction memory file name
  // testbench parameters
  parameter  bit          ABI = 1'b1    // enable ABI translation for GPIO names
)();

import riscv_asm_pkg::*;

  // system signals
  logic clk = 1'b1;  // clock
  logic rst = 1'b1;  // reset

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
    $display("ERROR: reached simulation timeout!");
    repeat (4) @(posedge clk);
    $finish();
    /* verilator lint_on INITIALDLY */
  end

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

  localparam tcb_phy_t TCB_PHY_LOG_SIZE = '{
    // protocol
    DLY: 1,
    // signal widths
    UNT: 8,
    ADR: XLEN,
    DAT: XLEN,
    ALN: $clog2(XLEN/8),   // $clog2(DAT/UNT)
    // data packing parameters
    MOD: TCB_LOG_SIZE,
    ORD: TCB_DESCENDING,
    // channel configuration
    CHN: TCB_COMMON_HALF_DUPLEX
  };

  localparam tcb_phy_t TCB_PHY_BYTE_ENA = '{
    // protocol
    DLY: 1,
    // signal widths
    UNT: 8,
    ADR: XLEN,
    DAT: XLEN,
    ALN: $clog2(XLEN/8),   // $clog2(DAT/UNT)
    // data packing parameters
    MOD: TCB_BYTE_ENA,
    ORD: TCB_DESCENDING,
    // channel configuration
    CHN: TCB_COMMON_HALF_DUPLEX
  };

  // system busses
  tcb_if #(TCB_PHY_LOG_SIZE) tcb_cpu       (.clk (clk), .rst (rst));
  tcb_if #(TCB_PHY_BYTE_ENA) tcb_mem [0:0] (.clk (clk), .rst (rst));

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

  r5p_mouse #(
    .IFU_RST (IFU_RST),
    .IFU_MSK (IFU_MSK),
    .GPR_ADR (GPR_ADR)
  ) dut (
    // system signals
    .clk     (clk),
    .rst     (rst),
    // TCB system bus (shared by instruction/load/store)
    .tcb_vld (tcb_cpu.vld),
    .tcb_wen (tcb_cpu.req.wen),
    .tcb_adr (tcb_cpu.req.adr),
    .tcb_siz (tcb_cpu.req.siz),
    .tcb_wdt (tcb_cpu.req.wdt),
    .tcb_rdt (tcb_cpu.rsp.rdt),
    .tcb_err (tcb_cpu.rsp.sts.err ),
    .tcb_rdy (tcb_cpu.rdy)
  );

  // signals not provided by the CPU
  assign tcb_cpu.req.ndn = TCB_LITTLE;

////////////////////////////////////////////////////////////////////////////////
// protocol checker
////////////////////////////////////////////////////////////////////////////////

  tcb_vip_protocol_checker tcb_cpu_chk (.tcb (tcb_cpu));
  tcb_vip_protocol_checker tcb_mem_chk (.tcb (tcb_mem[0]));

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

  // convert from LOG_SIZE to BYTE_ENA mode
  tcb_lib_logsize2byteena tcb_cnv (
    .sub  (tcb_cpu),
    .man  (tcb_mem[0])
  );

  tcb_vip_memory #(
    .MFN  (IFN),
    .SIZ  (MEM_SIZ),
    .SPN  (1)
  ) mem (
    .tcb  (tcb_mem[0:0])
  );

  // memory initialization file is provided at runtime
  initial
  begin
    string fn;
    if ($value$plusargs("firmware=%s", fn)) begin
      $display("Loading file into memory: %s", fn);
      void'(mem.read_bin(fn));
      void'(r5p_riscof.read_bin(fn));
    end else if (IFN == "") begin
      $display("ERROR: memory load file argument not found.");
      $finish;
    end
  end

////////////////////////////////////////////////////////////////////////////////
// RISCOF
////////////////////////////////////////////////////////////////////////////////

  r5p_riscof #(
    // memory
    .MEM_ADR (IFU_RST),
    .MEM_SIZ (MEM_SIZ),
    // miscellaneous
    .TIMEOUT (20000)
  ) r5p_riscof (
    .tcb (tcb_cpu)
  );

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
    .tcb  (tcb_cpu)
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

