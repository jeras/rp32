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

module riscv_tb #(
  // RISC-V ISA
  int unsigned XLEN = 32,    // is used to quickly switch between 32 and 64 for testing
  // instruction bus
  int unsigned IAW = 22,     // instruction address width
  int unsigned IDW = 32,     // instruction data    width
  // data bus
  int unsigned DAW = 32,     // data address width
  int unsigned DDW = XLEN,   // data data    width
  int unsigned DBW = DDW/8,  // data byte en width
  // memory configuration
  string       IFN = "",     // instruction memory file name
  // testbench parameters
  bit          ABI = 1'b1    // enable ABI translation for GPIO names
)();

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
    rst <= 1'b0;
    repeat (20000) @(posedge clk);
    timeout <= 1'b1;
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

  // TCB interface
  logic          tcb_vld;
  logic          tcb_wen;
  logic [32-1:0] tcb_adr;
  logic [ 4-1:0] tcb_ben;
  logic [32-1:0] tcb_wdt;
  logic [32-1:0] tcb_rdt;
  logic          tcb_err;
  logic          tcb_rdy;

  logic          tcb_trn;

  // internal state signals
  logic dbg_ifu;  // indicator of instruction fetch
  logic dbg_lsu;  // indicator of load/store
  logic dbg_gpr;  // indicator of GPR access

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

  r5p_mouse #(
    .RST_ADR (32'h0000_0000),
    .GPR_ADR (32'h001f_ff80)
  ) cpu (
    // system signals
    .clk     (clk),
    .rst     (rst),
`ifdef TRACE_DEBUG
    // internal state signals
    .dbg_ifu (dbg_ifu),
    .dbg_lsu (dbg_lsu),
    .dbg_gpr (dbg_gpr),
`endif
    // TCL system bus (shared by instruction/load/store)
    .bus_vld (tcb_vld),
    .bus_wen (tcb_wen),
    .bus_adr (tcb_adr),
    .bus_ben (tcb_ben),
    .bus_wdt (tcb_wdt),
    .bus_rdt (tcb_rdt),
    .bus_err (tcb_err),
    .bus_rdy (tcb_rdy)
  );

  // TCB transfer
  assign tcb_trn = tcb_vld & tcb_rdy;

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

  localparam SIZ = 2**IAW;

  logic [8-1:0] mem [0:SIZ-1];

  always @(posedge clk)
  if (tcb_trn) begin
    // write access
    if (tcb_wen) begin: write
      for (int unsigned b=0; b<4; b++) begin: byteenable
        if (tcb_ben[b]) begin
          mem[{tcb_adr[32-1:2], 2'b0} + b] <= tcb_wdt[b*8+:8];
        end
      end: byteenable
    end: write
    else begin: read
      // read access
      for (int unsigned b=0; b<4; b++) begin: byteenable
        if (tcb_ben[b]) begin
           tcb_rdt[b*8+:8] <= mem[{tcb_adr[32-1:2], 2'b0} + b];
        end else begin
           tcb_rdt[b*8+:8] <= 'x;
        end
      end: byteenable
    end: read
  end

  // memory initialization file is provided at runtime
  initial
  begin
    string fn;
    if ($value$plusargs("FILE_MEM=%s", fn)) begin
      int code;  // status code
      int fd;    // file descriptor
      bit [640-1:0] err;
      $display("Loading file into memory: %s", fn);
      fd = $fopen(fn, "rb");
      code = $fread(mem, fd);
      if (code == 0) begin
        code = $ferror(fd, err);
        $display("DEBUG: read_bin: code = %d, err = %s", code, err);
      end else begin
        $display("DEBUG: read %dB from binary file", code);
      end
      $fclose(fd);
    end else if (IFN == "") begin
      $display("ERROR: memory load file argument not found.");
      $finish;
    end
  end

  // memory is always ready
  assign tcb_rdy = 1'b1;

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
  end else if (tcb_trn) begin
    // decode address
    if (tcb_adr[32-1:0] ==? 32'h0020_00xx) begin
      if (tcb_wen) begin
        // write access
        case (tcb_adr[8-1:0])
          8'h00:  rvmodel_data_begin <= tcb_wdt;
          8'h08:  rvmodel_data_end   <= tcb_wdt;
          8'h10:  rvmodel_halt       <= tcb_wdt[0];
          default:  ;  // do nothing
        endcase
      end
    end
  end

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
      int fd;    // file descriptor
      $display("Saving signature file with data from 0x%8h to 0x%8h: %s", rvmodel_data_begin, rvmodel_data_end, fn);
      // dump
      fd = $fopen(fn, "w");
      for (int unsigned addr=rvmodel_data_begin; addr<rvmodel_data_end; addr+=4) begin
          $fwrite(fd, "%h%h%h%h\n", mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]);
      end
      $fclose(fd);
    end else begin
      $display("ERROR: signature save file argument not found.");
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
    // debug mode enable (must be active with VALID)
    .dbg_ifu (dbg_ifu),
    .dbg_lsu (dbg_lsu),
    .dbg_gpr (dbg_gpr & tcb_wen),
    // system bus
    .bus  (bus)
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
