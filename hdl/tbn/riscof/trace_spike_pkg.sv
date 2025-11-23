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

package trace_spike_pkg;
    import riscv_isa_pkg::*;
    import riscv_isa_i_pkg::*;

    parameter int unsigned XLEN = 32;

////////////////////////////////////////////////////////////////////////////////
// tracing (matching spike simulator logs)
////////////////////////////////////////////////////////////////////////////////

    // format GPR string with desired whitespace
    function string format_gpr (logic [5-1:0] idx);
        if (idx < 10)  return($sformatf("x%0d ", idx));
        else           return($sformatf("x%0d", idx));
    endfunction: format_gpr

    // prepare string for committed instruction
    function string trace (
        int unsigned     core,     // core (hart) index
        // IFU
        logic [XLEN-1:0] ifu_adr,  // PC (IFU address)
        logic [XLEN-1:0] ifu_ins,  // instruction
        // WBU (write back to destination register)
        logic            wbu_ena,  // enable
        logic [   5-1:0] wbu_idx,  // index of destination register
        logic [XLEN-1:0] wbu_dat,  // data
        // LSU
        logic            lsu_ena,  // enable
        logic            lsu_wen,  // write enable
        logic            lsu_ren,  // read enable
        logic [XLEN-1:0] lsu_adr,  // PC (IFU address)
        logic [XLEN-1:0] lsu_siz,  // load/store size
        logic [XLEN-1:0] lsu_wdt   // write data (store)
    );
        string str_if;  // instruction fetch
        string str_wb;  // write-back
        string str_ld;  // load
        string str_st;  // store
        string str_ls;  // load/store

        // prepare fetch
        str_if = $sformatf(" 0x%8h (0x%8h)", ifu_adr, ifu_ins);

        // prepare write-back
        str_wb = wbu_ena ? $sformatf(" %s 0x%8h", format_gpr(wbu_idx), wbu_dat) : "";

        // prepare load
        if (lsu_ena & lsu_ren) begin
            str_ld = $sformatf(" mem 0x%8h", lsu_adr);
        end else begin
            str_ld = "";
        end

        // prepare store
        if (lsu_ena & lsu_wen) begin
            case (lsu_siz)
                2'd0: str_st = $sformatf(" mem 0x%8h 0x%2h", lsu_adr, lsu_wdt[ 8-1:0]);
                2'd1: str_st = $sformatf(" mem 0x%8h 0x%4h", lsu_adr, lsu_wdt[16-1:0]);
                2'd2: str_st = $sformatf(" mem 0x%8h 0x%8h", lsu_adr, lsu_wdt[32-1:0]);
//                 2'd3: str_st = $sformatf(" mem 0x%8h 0x%16h", lsu_adr, lsu_wdt[64-1:0]);
                default: $error("Unsupported store size %0d", lsu_siz);
            endcase
        end else begin
            str_st = "";
        end

        // combine fetch/write-back/load/store
        return($sformatf("core   %0d: 3%s%s%s%s\n", core, str_if, str_wb, str_ld, str_st));
    endfunction: trace

////////////////////////////////////////////////////////////////////////////////
// statistics
////////////////////////////////////////////////////////////////////////////////

endpackage: trace_spike_pkg
