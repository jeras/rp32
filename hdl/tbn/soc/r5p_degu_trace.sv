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
    import tcb_pkg::*;
    import trace_spike_pkg::*;
#(
    // constants used across the design in signal range sizing instead of literals
    localparam int unsigned XLEN = 32,
    localparam int unsigned XLOG = $clog2(XLEN),
    // trace format class type (HDLDB, Spike, ...)
    parameter type FORMAT = trace_spike_pkg::spike,
    // trace file name
    parameter string FILE = "",
    // TODO: check for GPR size differently
    parameter  int unsigned GNUM = 32,
    localparam int unsigned GLOG = $clog2(GNUM)
)(
    // GPR array
    input logic            gpr_wen,
    input logic [GLOG-1:0] gpr_wid,
    input logic [XLEN-1:0] gpr_wdt,
    // TCB IFU/LSU system busses
    tcb_if.mon tcb_ifu,
    tcb_if.mon tcb_lsu
);

//    import riscv_isa_pkg::*;
//    import riscv_isa_i_pkg::*;
//    import riscv_asm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

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

    // object tracer of class FORMAT
    FORMAT tracer;

    // open trace file if name is given by parameter
    initial
    begin
        string filename;
        // trace file if name is given by parameter
        if ($value$plusargs("trace=%s", filename)) begin
        end
        // trace file with filename obtained through plusargs
        else if (FILE) begin
            filename = FILE;
        end
        if (filename) begin
            tracer = new(filename);
            $display("TRACING: opened trace file: '%s'.", filename);
        end else begin
            $display("TRACING: no trace file name was provided.");
        end
    end
  
    final
    begin
        tracer.close();
    end

    // initialize dummy data into the queue to enforce order
    initial
    begin
      str_gpr = '{};
      str_lsu = '{};
      str_ifu = '{""};
    end

    // instruction fetch
    always_ff @(posedge tcb_ifu.clk)
    begin
        if ($past(tcb_ifu.trn)) begin
            if (opsiz(tcb_ifu.rsp.rdt) == 4) begin
                str_ifu.push_front($sformatf(" 0x%8h (0x%8h)", $past(tcb_ifu.req.adr), tcb_ifu.rsp.rdt));
            end else begin
                str_ifu.push_front($sformatf(" 0x%8h (0x%4h)", $past(tcb_ifu.req.adr), tcb_ifu.rsp.rdt[16-1:0]));
            end
        end
    end

    // GPR write-back (rs1/rs2 reads are not logged)
    always_ff @(posedge tcb_ifu.clk)
    begin
      if ($past(tcb_ifu.trn)) begin
        if (gpr_wen) begin
          // ignore GPR x0
          if (gpr_wid != 0) begin
              str_gpr.push_front($sformatf(" %s 0x%8h", format_gpr(gpr_wid), gpr_wdt));
          end
        end else begin
          str_gpr.push_front("");
        end
      end
    end

    // memory load/store
    always_ff @(posedge tcb_lsu.clk)
    begin
      if ($past(tcb_lsu.trn)) begin
        if ($past(tcb_lsu.req.wen)) begin
          // memory store
          str_lsu.push_front($sformatf(" mem 0x%8h 0x%8h", $past(tcb_lsu.req.adr), $past(tcb_lsu.req.wdt)));
        end else begin
          // memory load
          str_lsu.push_front($sformatf(" 0x%8h (0x%8h)", $past(tcb_lsu.req.adr), tcb_lsu.rsp.rdt));
        end
      end
    end

    // prepare string for committed instruction
    always_ff @(posedge tcb_ifu.clk)
    begin
      // only log if a log file was opened
      if (fd) begin
        // at instruction fetch combine strings from previous instructions
        if ($past(tcb_ifu.trn)) begin
          $fwrite(fd, "core   0: 3%s%s%s\n", str_ifu.pop_back(), str_gpr.pop_back(), str_lsu.pop_back());
        end
      end
    end

endmodule: r5p_degu_trace
