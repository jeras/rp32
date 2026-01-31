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

    localparam int unsigned ADR = $clog2(SIZ);

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

`ifdef YOSYS_SLANG
    localparam int unsigned MEM_DATA = sub.DAT;
    localparam int unsigned MEM_SIZE = SIZ/(sub.DAT/8);
    `include "mem_if.vh"
`else
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
`endif

////////////////////////////////////////////////////////////////////////////////
// load/store
////////////////////////////////////////////////////////////////////////////////

    logic [ADR-sub.MAX-1:0] adr;

    assign adr = sub.req.adr[ADR-1:sub.MAX];

    always @(posedge sub.clk)
    if (sub.trn) begin
        // read
        if (sub.req.ren) begin
            sub.rsp.rdt <= mem[adr];
        end
        // write
        if (sub.req.wen) begin
            if (sub.req.byt[0]) mem[adr][ 7: 0] <= sub.req.wdt[ 7: 0];
            if (sub.req.byt[1]) mem[adr][15: 8] <= sub.req.wdt[15: 8];
            if (sub.req.byt[2]) mem[adr][23:16] <= sub.req.wdt[23:16];
            if (sub.req.byt[3]) mem[adr][31:24] <= sub.req.wdt[31:24];
        end
    end

    // response error status
    assign sub.rsp.sts = '0;
    assign sub.rsp.err = 1'b0;

    // handshake backpressure
    assign sub.rdy = 1'b1;

endmodule: r5p_soc_memory
