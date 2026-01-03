////////////////////////////////////////////////////////////////////////////////
// R5P-degu TCB monitor and execution trace logger
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

module r5p_degu_trace
    import trace_generic_pkg::*;
    import tcb_pkg::*;
    import riscv_isa_pkg::*;
    import riscv_isa_i_pkg::*;
//    import riscv_asm_pkg::*;
#(
    // constants used across the design in signal range sizing instead of literals
    parameter  int unsigned XLEN = 32,
    localparam int unsigned XLOG = $clog2(XLEN),
    // TODO: check for GPR size differently
    parameter  int unsigned GNUM = 32,
    localparam int unsigned GLOG = $clog2(GNUM),
    // trace format class type (HDLDB, Spike, ...)
    parameter type FORMAT = trace_generic_pkg::trace_generic,
    // trace file name
    parameter string FILE_ARG = "TEST_DIR",
    parameter string FILE_PAR = "dut.log"
)(
    // GPR array
    input logic            gpr_den,  // destination enable
    input logic [GLOG-1:0] gpr_did,  // destination index
    input logic [XLEN-1:0] gpr_ddt,  // destination data
    input logic [GLOG-1:0] gpr_sid,  // source index
    // TCB IFU/LSU system busses
    tcb_if.mon tcb_ifu,
    tcb_if.mon tcb_lsu
);

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // IFU (instruction fetch unit)
    logic            ifu_ena = 1'b0;  // enable
    logic [XLEN-1:0] ifu_adr;         // PC (IFU address)
    logic            ifu_siz;         // instruction size (0-16bit, 1-32bit)
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
    logic [   2-1:0] lsu_siz;         // load/store logarithmic size
    logic [XLEN-1:0] lsu_wdt;         // write data (store)
    logic [XLEN-1:0] lsu_rdt;         // read data (load)

    // instruction pipeline
    logic [XLEN-1:0] ifp_adr;         // PC (IFU address)
    logic            ifp_siz;         // instruction size (0-16bit, 1-32bit)
    logic [XLEN-1:0] ifp_ins;         // instruction
    logic            ifp_ill;         // instruction is illegal

////////////////////////////////////////////////////////////////////////////////
// tracing
////////////////////////////////////////////////////////////////////////////////

    // object tracer of class FORMAT
    FORMAT tracer;

    // open trace file if name is given by parameter
    initial
    begin
        string filename;
        // trace file if name is combined from plusargs (directory) and parameter (file)
        if ($value$plusargs({FILE_ARG, "=%s"}, filename)) begin
            filename = {filename, FILE_PAR};
        end
        // initialize tracing object
        tracer = new(filename);
    end

    final
    begin
        tracer.close();
    end

    // instruction pipeline
    always_ff @(posedge tcb_ifu.clk)
    if ($past(tcb_ifu.trn, 1)) begin
        ifu_ena <= 1'b0;  // enable
        ifp_adr <= $past(tcb_ifu.req.adr);
        ifp_siz <= opsiz(tcb_ifu.rsp.rdt[1:0]) == 4;
        ifp_ins <=       tcb_ifu.rsp.rdt ;
        ifp_ill <= 1'b0;  // TODO
    end

    // instruction fetch
    always_ff @(posedge tcb_ifu.clk)
    begin
        if ($past(tcb_ifu.trn, 2)) begin
//            $display("DEBUG: fetch");
            tracer.trace(
                .timestamp ($time),
                .core (0),
                // IFU
                .ifu_adr (ifp_adr),
                .ifu_siz (ifp_siz),
                .ifu_ins (ifp_ins),
                .ifu_ill (ifp_ill),
                // WBU (write back to destination register)
                .wbu_ena (gpr_den),
                .wbu_idx (gpr_did),
                .wbu_dat (gpr_ddt),
                // LSU
                .lsu_ena ($past(tcb_lsu.trn    )),
                .lsu_wen ($past(tcb_lsu.req.wen)),
                .lsu_ren ($past(tcb_lsu.req.ren)),
                .lsu_wid ($past(gpr_sid)),
                .lsu_rid (      gpr_did),
                .lsu_adr ($past(tcb_lsu.req.adr)),
                .lsu_siz ($past(tcb_lsu.req.siz)),
                .lsu_wdt ($past(tcb_lsu.req.wdt)),
                .lsu_rdt (      tcb_lsu.rsp.rdt )
            );

        end
    end

endmodule: r5p_degu_trace
