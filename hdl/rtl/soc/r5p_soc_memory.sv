////////////////////////////////////////////////////////////////////////////////
// R5P: single RW port tightly coupled memory (RTL for simulation and inference)
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

module r5p_soc_memory
  import tcb_pkg::*;
#(
  string       FNM = "",    // binary initialization file name
  int unsigned SIZ = 4096   // memory size in bytes (4kB by default)
)(
  // TCB interface
  tcb_if.sub tcb
);

//localparam int unsigned ADR = tcb.CFG.BUS.ADR;
  localparam int unsigned DAT = tcb.CFG.BUS.DAT;
  localparam int unsigned BYT = tcb.CFG_BUS_BYT;
  localparam int unsigned MAX = tcb.CFG_BUS_MAX;
  localparam int unsigned ADR = $clog2(SIZ);

////////////////////////////////////////////////////////////////////////////////
// TCB interface parameter validation
////////////////////////////////////////////////////////////////////////////////

  initial
  begin
    // TCB mode must be memory (RISC-V mode is not supported)
    assert (tcb.CFG.BUS.MOD == TCB_MOD_BYTE_ENA) else $fatal("Unsupported TCB mode in %m.");
    // check if address is wide enough for the memory size
    assert (tcb.CFG.BUS.ADR >= ADR             ) else $fatal("TCB address not wide enough to address entire memory size in %m.");
  end

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

  logic [DAT-1:0] mem [0:SIZ/(DAT/8)-1];

  initial
  begin
    if (FNM != "") begin
      $display("INFO: Reading initialization file %s into memory %m.", FNM);
      // TODO: binary mode
      $readmemh(FNM, mem);
    end else begin
      $display("INFO: No initialization file name provided for memory %m.");
    end
  end

////////////////////////////////////////////////////////////////////////////////
// load/store
////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge tcb.clk)
  if (tcb.vld) begin
    if (tcb.req.wen) begin
      // write access
      for (int unsigned b=0; b<BYT; b++) begin
        if (tcb.req.byt[b])  mem[tcb.req.adr[ADR-1:MAX]][8*b+:8] <= tcb.req.wdt[b];
      end
    end else begin
      // read access
      for (int unsigned b=0; b<BYT; b++) begin
        if (tcb.req.byt[b])  tcb.rsp.rdt[b] <= mem[tcb.req.adr[ADR-1:MAX]][8*b+:8];
      end
    end
  end

  // respond with no error
  assign tcb.rsp.sts.err = 1'b0;
  // always ready
  assign tcb.rdy = 1'b1;

endmodule: r5p_soc_memory
