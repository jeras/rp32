////////////////////////////////////////////////////////////////////////////////
// R5P-mouse TCB monitor and execution trace logger
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

module r5p_mouse_trace
    import tcb_pkg::*;
#(
    // trace format ("HDLDB", "Spike")
    parameter string FORMAT,
    // trace file name
    parameter string FILE = ""
)(
    // instruction execution phase
    input logic [3-1:0] pha,
    // TCB system bus
    tcb_if.mon tcb
);

    import riscv_isa_pkg::*;
    import riscv_isa_i_pkg::*;
    import riscv_asm_pkg::*;
    import trace_spike_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// local parameters
////////////////////////////////////////////////////////////////////////////////

    // TODO: try to share this table with RTL, while keeping Verilog2005 compatibility ?
    // FSM phases (GPR access phases can be decoded from a single bit)
    localparam logic [3-1:0] IF  = 3'b000;  // instruction fetch
    localparam logic [3-1:0] RS1 = 3'b101;  // read register source 1
    localparam logic [3-1:0] RS2 = 3'b110;  // read register source 1
    localparam logic [3-1:0] MLD = 3'b001;  // memory load
    localparam logic [3-1:0] MST = 3'b010;  // memory store
    localparam logic [3-1:0] EXE = 3'b011;  // execute (only used to evaluate branching condition)
    localparam logic [3-1:0] WB  = 3'b100;  // GPR write-back

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // trace file name and descriptor
    string fn;  // file name
    int fd;

    // IFU (instruction fetch unit)
    logic            ifu_ena = 1'b0;  // enable
    logic [XLEN-1:0] ifu_adr;         // PC (IFU address)
    logic [XLEN-1:0] ifu_ins;         // instruction
    logic            ifu_ill;         // instruction is illegal
    // WBU (write back to destination register)
    logic            wbu_ena;         // enable
    logic [   5-1:0] wbu_idx;         // index of destination register
    logic [XLEN-1:0] wbu_dat;         // data
    // LSU (load/store unit)
    logic            lsu_ena;         // enable
    logic            lsu_wen;         // write enable
    logic            lsu_ren;         // read enable
    logic [   5-1:0] lsu_wid;         // index of data source GPR
    logic [   5-1:0] lsu_rid;         // index of data destination GPR
    logic [XLEN-1:0] lsu_adr;         // PC (IFU address)
    logic [XLEN-1:0] lsu_siz;         // load/store size
    logic [XLEN-1:0] lsu_wdt;         // write data (store)
    logic [XLEN-1:0] lsu_rdt;         // read data (load)

////////////////////////////////////////////////////////////////////////////////
// tracing
////////////////////////////////////////////////////////////////////////////////

    initial begin
        $display("DEBUG: FORMAT = '%s'", FORMAT);
    end

    // prepare string for each execution phase
    always_ff @(posedge tcb.clk)
    if (tcb.rst) begin
        ifu_ena <= 1'b0;
    end else if ($past(tcb.trn)) begin
        case ($past(pha))
            IF: begin
                // log instruction trace
                if (ifu_ena) begin
//                    $display("DEBUG: trace");
                    case (FORMAT)
                        "Spike": begin
//                            $display("DEBUG: trace Spike");
                            $fwrite(fd, trace_spike_pkg::trace(
                                .core (0),
                                // IFU
                                .ifu_adr (ifu_adr),
                                .ifu_ins (ifu_ins),
                                // WBU (write back to destination register)
                                .wbu_ena (wbu_ena),
                                .wbu_idx (wbu_idx),
                                .wbu_dat (wbu_dat),
                                // LSU
                                .lsu_ena (lsu_ena),
                                .lsu_wen (lsu_wen),
                                .lsu_ren (lsu_ren),
                                .lsu_adr (lsu_adr),
                                .lsu_siz (lsu_siz),
                                .lsu_wdt (lsu_wdt)
                            ));
                        end
                    endcase
                end
                // instruction fetch
                ifu_ena <= 1'b1;
                ifu_adr <= $past(tcb.req.adr);
                ifu_ins <=       tcb.rsp.rdt ;
                ifu_ill <= 1'b0;  // TODO;
                // clear write-back/load/store valid
                wbu_ena <= 1'b0;
                lsu_ena <= 1'b0;
                lsu_wen <= 1'b0;
                lsu_ren <= 1'b0;
            end
            WB: begin
                // GPR write-back (rs1/rs2 reads are not logged)
                wbu_ena <= 1'b1;
                wbu_idx <= $past(tcb.req.adr[2+:5]);
                wbu_dat <= $past(tcb.req.wdt);
            end
            MLD: begin
                // memory load
                lsu_ena <= 1'b1;
                lsu_ren <= 1'b1;
                lsu_rid <= $past(tcb.req.adr[2+:5]);
                lsu_adr <= $past(tcb.req.adr);
                lsu_siz <= $past(tcb.req.siz);
                lsu_rdt <=       tcb.rsp.rdt ;
            end
            MST: begin
                // memory store
                lsu_ena <= 1'b1;
                lsu_wen <= 1'b1;
                lsu_rid <= $past(tcb.req.adr[2+:5]);
                lsu_adr <= $past(tcb.req.adr);
                lsu_siz <= $past(tcb.req.siz);
                lsu_wdt <= $past(tcb.req.wdt);
            end
        endcase
    end

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

endmodule: r5p_mouse_trace
