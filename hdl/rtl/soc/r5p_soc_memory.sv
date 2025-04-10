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

  localparam int unsigned UNT = tcb.PHY.UNT;
  localparam int unsigned DAT = tcb.PHY.DAT;
  localparam int unsigned ADR = $clog2(SIZ);

////////////////////////////////////////////////////////////////////////////////
// TCB interface parameter validation
////////////////////////////////////////////////////////////////////////////////

  initial
  begin
    // TCB mode must be memory (RISC-V mode is not supported)
    assert (tcb.PHY.MOD == TCB_BYTE_ENA) else $fatal("Unsupported TCB mode in %m.");
    // check if address is wide enough for the memory size
    assert (tcb.PHY.ADR >= ADR         ) else $fatal("TCB address not wide enough to address entire memory size in %m.");
  end

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

  logic [DAT-1:0] mem [0:SIZ-1];

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

always @(posedge tcb.clk)
if (tcb.vld) begin
  if (tcb.wen) begin
    // write access
    mem[tcb.adr[ADR-1:$clog2(DAT/UNT)]] <= tcb.wdt;
//  for (int unsigned b=0; b<tcb.BW; b++) begin
//    if (tcb.ben[b])  mem[tcb.adr[AW-1:$clog2(BW)]][8*b+:8] <= tcb.wdt[8*b+:8];
//  end
  end else begin
    // read access
    tcb.rdt <= mem[tcb.adr[ADR-1:$clog2(DAT/UNT)]];
//  for (int unsigned b=0; b<tcb.BW; b++) begin
//    if (tcb.ben[b])  tcb.rdt[8*b+:8] <= mem[tcb.adr[AW-1:$clog2(BW)]][8*b+:8];
//    else             tcb.rdt[8*b+:8] <= 'x;
//  end
  end
end

// respond with no error
assign tcb.rsp.sts.err = 1'b0;
// always ready
assign tcb.rdy = 1'b1;

endmodule: r5p_soc_memory
