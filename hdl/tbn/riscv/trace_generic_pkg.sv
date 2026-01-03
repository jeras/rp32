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

package trace_generic_pkg;
    import riscv_isa_pkg::*;
    import riscv_isa_i_pkg::*;

    virtual class trace_generic #(
        parameter int unsigned XLEN = 32
    );

        string fn;  // file name
        int fd;  // file descriptor

        function new (input string filename);
            fd = $fopen(filename, "w");
            if (fd!=0) begin
                fn = filename;
                $display("TRACING: opened trace file for writing: '%s'.", filename);
            end else begin
                $display("TRACING: could not open trace file for writing: '%s'.", filename);
            end
        endfunction: new

        function void close ();
            if (fd!=0) begin
                $fclose(fd);
                $display("TRACING: closed trace file: '%s'.", fn);
            end
        endfunction: close

////////////////////////////////////////////////////////////////////////////////
// tracing (pure virtual function must be implemented by the extending class)
////////////////////////////////////////////////////////////////////////////////

        // prepare string for committed instruction
        pure virtual function void trace (
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

    endclass: trace_generic

endpackage: trace_generic_pkg
