////////////////////////////////////////////////////////////////////////////////
// TCB monitor and execution trace logger (Spike format)
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

module trace_spike_pkg
    import riscv_isa_pkg::*;
    import riscv_isa_i_pkg::*;
#(
    parameter int unsigned XLEN = 32
    // trace file name
    parameter string FILE = ""
);

////////////////////////////////////////////////////////////////////////////////
// tracing (matching spike simulator logs)
////////////////////////////////////////////////////////////////////////////////

    // format GPR string with desired whitespace
    function string format_gpr (logic [5-1:0] idx);
        if (idx < 10)  return($sformatf("x%0d ", idx));
        else           return($sformatf("x%0d", idx));
    endfunction: format_gpr

    // prepare string for committed instruction
    function void trace (
        // IFU
        logic [XLEN-1:0] ifu_adr,  // PC (IFU address)
        logic [XLEN-1:0] ifu_ins,  // instruction
        // WBU (write back to destination register)
        logic [   5-1:0] wbu_idx,  // index
        logic [XLEN-1:0] wbu_dat,  // data
        // LSU
        logic [XLEN-1:0] lsu_adr,  // PC (IFU address)
        logic [XLEN-1:0] lsu_siz,  // PC (IFU address)
        logic [XLEN-1:0] lsu_wdt,  // instruction
        logic [XLEN-1:0] lsu_rdt,  // instruction
    );
        string str_if;
        string str_wb;
        string str_ld;
        string str_st;
        str_if = $sformatf(" 0x%8h (0x%8h)", ifu_adr, ifu_ins);
        str_wb = $sformatf(" %s 0x%8h", format_gpr(wbu_idx), wbu_dat);
        str_ld = $sformatf(" mem 0x%8h", $past(tcb.req.adr));
        case (lsu_siz)
            2'd0: str_st = $sformatf(" mem 0x%8h 0x%2h", lsu_adr, lsu_wdt[ 8-1:0]);
            2'd1: str_st = $sformatf(" mem 0x%8h 0x%4h", lsu_adr, lsu_wdt[16-1:0]);
            2'd2: str_st = $sformatf(" mem 0x%8h 0x%8h", lsu_adr, lsu_wdt[32-1:0]);
//          2'd3: str_st = $sformatf(" mem 0x%8h 0x%16h", lsu_adr, lsu_wdt[64-1:0]);
        endcase

        $fwrite(fd, "core   0: 3%s%s%s%s\n", str_if, str_wb, str_ld, str_st);
    endfunction: trace
  
    // open trace file if name is given by parameter
    initial
    begin
      // trace file if name is given by parameter
      if ($value$plusargs("trace=%s", fn)) begin
      end
      // trace file with filename obtained through plusargs
      else if (FILE) begin
        fn = FILE;
      end
      if (fn) begin
        fd = $fopen(fn, "w");
        $display("TRACING: opened trace file: '%s'.", fn);
      end else begin
        $display("TRACING: no trace file name was provided.");
      end
    end
  
    final
    begin
      $fclose(fd);
      $display("TRACING: closed trace file: '%s'.", fn);
    end

////////////////////////////////////////////////////////////////////////////////
// statistics
////////////////////////////////////////////////////////////////////////////////

endmodule: trace_spike
