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
    import tcb_lite_pkg::*;
#(
    string       FNM = "",    // binary initialization file name
    int unsigned SIZ = 4096   // memory size in bytes (4kB by default)
)(
    // TCB interface
    tcb_lite_if.sub sub
);

////////////////////////////////////////////////////////////////////////////////
// TCB interface parameter validation
////////////////////////////////////////////////////////////////////////////////

    initial
    begin
        // TCB mode must be memory (RISC-V mode is not supported)
        assert (sub.MOD == 1'b1) else $fatal("Unsupported TCB-Lite mode.");
    end

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

    logic [sub.DAT-1:0] mem [0:SIZ/(sub.DAT/8)-1];
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

    always_ff @(posedge sub.clk)
    if (sub.vld) begin
        // write access
        if (sub.req.wen) begin
            for (int unsigned b=0; b<sub.BYT; b++) begin
                if (sub.req.byt[b])  mem[sub.req.adr[sub.ADR-1:sub.MAX]][8*b+:8] <= sub.req.wdt[b];
            end
        end
        // read access
        if (sub.req.ren) begin
            for (int unsigned b=0; b<sub.BYT; b++) begin
                if (sub.req.byt[b])  sub.rsp.rdt[b] <= mem[sub.req.adr[sub.ADR-1:sub.MAX]][8*b+:8];
            end
        end
    end

    // respond with no error
    assign sub.rsp.sts = '0;
    assign sub.rsp.err = 1'b0;
    // always ready
    assign sub.rdy = 1'b1;

endmodule: r5p_soc_memory
