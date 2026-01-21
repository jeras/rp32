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

package trace_sail_pkg;
    import riscv_isa_pkg::*;
    import riscv_isa_i_pkg::*;
    import trace_generic_pkg::*;

    class trace_sail #(
        parameter int unsigned XLEN = 32
    ) extends trace_generic #(XLEN);

        function new (input string filename);
            super.new(filename);
        endfunction: new

////////////////////////////////////////////////////////////////////////////////
// tracing (matching spike simulator logs)
////////////////////////////////////////////////////////////////////////////////

        function string hex (
            logic [XLEN-1:0] dat,
            int siz = XLEN/8,  // logarithmic size
            int off = 0        // beginning offset
        );
            hex = "";
            for (int unsigned i=off; i<off+siz; i++) begin
                hex = {$sformatf("%2h", dat[8*i+:8]), hex};
            end
            return hex.toupper();
        endfunction: hex

        // prepare string for committed instruction
        function void trace (
            time             timestamp,       // 64-bit unsigned integer
            int unsigned     core,            // core (hart) index
            // IFU
            logic [XLEN-1:0] ifu_adr,         // PC (IFU address)
            logic            ifu_siz,         // instruction size (0-16bit, 1-32bit)
            logic [XLEN-1:0] ifu_ins,         // instruction
            logic            ifu_ill,         // instruction is illegal
            // WBU (write back to destination register)
            logic            wbu_ena,         // enable
            logic [   5-1:0] wbu_idx,         // index of destination register
            logic [XLEN-1:0] wbu_dat,         // data
            // LSU (load/store unit)
            logic            lsu_ena,         // enable
            logic            lsu_wen,         // write enable
            logic            lsu_ren,         // read enable
            logic [   5-1:0] lsu_wid,         // index of data source GPR
            logic [   5-1:0] lsu_rid,         // index of data destination GPR
            logic [XLEN-1:0] lsu_adr,         // PC (IFU address)
            logic [   2-1:0] lsu_siz,         // load/store logarithmic size
            logic [XLEN-1:0] lsu_wdt,         // write data (store)
            logic [XLEN-1:0] lsu_rdt          // read data (load)
        );
            string str_if = "";  // instruction fetch
            string str_ls = "";  // load/store
            string str_wb = "";  // write-back

            // fetch address/instruction
            case (ifu_siz)
                0: str_if =  $sformatf("mem[X,0x0%s] -> 0x%s\n", hex(ifu_adr  ), hex(ifu_ins, 2, 0));   // 16bit
                1: str_if = {$sformatf("mem[X,0x0%s] -> 0x%s\n", hex(ifu_adr+0), hex(ifu_ins, 2, 0)),
                             $sformatf("mem[X,0x0%s] -> 0x%s\n", hex(ifu_adr+2), hex(ifu_ins, 2, 2))};  // 32bit
            endcase

            // load/store
            if (lsu_ena) begin
                if (lsu_wen) begin
                    // load address/data
                    str_ls = $sformatf("mem[W,0x0%s] <- 0x%s\n", hex(lsu_adr), hex(lsu_wdt, 2**lsu_siz));
                end
                if (lsu_ren) begin
                    // store address/data
                    str_ls = $sformatf("mem[R,0x0%s] -> 0x%s\n", hex(lsu_adr), hex(lsu_rdt, 2**lsu_siz));
                end
            end

            // write-back (x0 access is not logged)
            if (wbu_ena && (wbu_idx != 0)) begin
                str_wb = $sformatf("x%0d <- 0x%s\n", wbu_idx, hex(wbu_dat));
            end

            // combine fetch/write-back/load/store and write it to trace file
            $fwrite(fd, $sformatf("%s%s%s", str_if, str_ls, str_wb));
        endfunction: trace

    endclass: trace_sail

endpackage: trace_sail_pkg
