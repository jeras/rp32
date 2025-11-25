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

    class spike #(
        parameter int unsigned XLEN = 32
    );

        string fn;  // file name
        int fd;  // file descriptor

        function new (input string filename);
            fd = $fopen(filename, "w");
            if (fd) begin
                fn = filename;
                $display("TRACING: opened trace file for writing: '%s'.", filename);
            end else begin
                $display("TRACING: could not open trace file for writing: '%s'.", filename);
            end
        endfunction: new

        function void close ();
            if (fd) begin
                $fclose(fd);
                $display("TRACING: closed trace file: '%s'.", fn);
            end
        endfunction: close

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
            string str_if;  // instruction fetch
            string str_wb;  // write-back
            string str_ls;  // load/store

            // fetch address
            case (XLEN)
                32: str_if = $sformatf(" 0x%8h" , ifu_adr);
                64: str_if = $sformatf(" 0x%16h", ifu_adr);
            endcase
            // fetch instruction
            case (ifu_siz)
                0: str_if = {str_if, $sformatf(" (0x%4h)", ifu_ins[16-1:0])};  // 16bit
                1: str_if = {str_if, $sformatf(" (0x%8h)", ifu_ins[32-1:0])};  // 32bit
            endcase

            // write-back (x0 access is not logged)
            if (wbu_ena && (wbu_idx != 0)) begin
                case (XLEN)
                    32: str_wb = $sformatf(" %s 0x%8h" , format_gpr(wbu_idx), wbu_dat);
                    64: str_wb = $sformatf(" %s 0x%16h", format_gpr(wbu_idx), wbu_dat);
                endcase
            end else begin
                str_wb = "";
            end

            // load/store
            if (lsu_ena) begin
                // load/store address
                if (lsu_wen | lsu_wen) begin
                    case (XLEN)
                        32: str_ls = $sformatf(" mem 0x%8h" , lsu_adr);
                        64: str_ls = $sformatf(" mem 0x%16h", lsu_adr);
                    endcase
                end
                // store data
                if (lsu_wen) begin
                    case (lsu_siz)
                        2'd0: str_ls = {str_ls, $sformatf(" 0x%2h" , lsu_wdt[ 8-1:0])};
                        2'd1: str_ls = {str_ls, $sformatf(" 0x%4h" , lsu_wdt[16-1:0])};
                        2'd2: str_ls = {str_ls, $sformatf(" 0x%8h" , lsu_wdt[32-1:0])};
                        2'd3: str_ls = {str_ls, $sformatf(" 0x%16h", lsu_wdt[64-1:0])};
                        default: $error("Unsupported store size %0d", lsu_siz);
                    endcase
                end
            end else begin
                str_ls = "";
            end

            // combine fetch/write-back/load/store and write it to trace file
            $fwrite(fd, $sformatf("core   %0d: 3%s%s%s\n", core, str_if, str_wb, str_ls));
        endfunction: trace

    endclass: spike

endpackage: trace_spike_pkg
