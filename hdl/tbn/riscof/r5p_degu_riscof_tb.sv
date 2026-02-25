////////////////////////////////////////////////////////////////////////////////
// R5P Degu RISCOF testbench
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

module r5p_degu_riscof_tb
    import riscv_isa_pkg::*;
    import riscv_asm_pkg::*;
    import tcb_lite_pkg::*;
#(
    // constants used across the design in signal range sizing instead of literals
    localparam int unsigned XLEN = 32,
    localparam int unsigned XLOG = $clog2(XLEN),
    // RISC-V ISA
    // extensions  (see `riscv_isa_pkg` for enumeration definition)
//  parameter  isa_ext_t    XTEN = RV_M | RV_C | RV_Zicsr,
    parameter  isa_ext_t    XTEN = RV_C,
    // privilige modes
    parameter  isa_priv_t   MODES = MODES_M,
    // ISA
`ifdef ENABLE_CSR
    parameter  isa_t        ISA = '{spec: '{base: RV_32I, ext: XTEN}, priv: MODES},
`else
    parameter  isa_t        ISA = '{spec: '{base: RV_32I, ext: XTEN}, priv: MODES_NONE},
`endif
    // core
    parameter  bit [XLEN-1:0] IFU_RST = 32'h8000_0000,
    parameter  bit [XLEN-1:0] IFU_MSK = 32'h803f_ffff,
    // memory size
    parameter  int unsigned MEM_SIZ = 2**22,
    // memory configuration
    // trace file name
    parameter  string       FILE_ARG = "TEST_DIR",
    parameter  string       FILE_PAR = "dut.bin",
    // testbench parameters
    parameter  bit          ABI = 1'b1    // enable ABI translation for GPR names
)();

    // system signals
    logic clk = 1'b1;  // clock
    logic rst = 1'b1;  // reset

////////////////////////////////////////////////////////////////////////////////
// test sequence
////////////////////////////////////////////////////////////////////////////////

    // clock
    always #(20ns/2) clk = ~clk;

    // reset
    initial
    begin
        /* verilator lint_off INITIALDLY */
        repeat (4) @(posedge clk);
        // synchronous reset release
        rst <= 1'b0;
        repeat (10000) @(posedge clk);
        $display("ERROR: reached simulation timeout!");
        repeat (4) @(posedge clk);
        $finish();
        /* verilator lint_on INITIALDLY */
    end

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // TCB configurations               '{HSK: '{DLY,  HLD}, BUS: '{ MOD, CTL,  ADR,  DAT, STS}}
    localparam tcb_lite_cfg_t CFG_IFU = '{HSK: '{  1, 1'b0}, BUS: '{1'b0,   0, XLEN, XLEN,   0}};
    localparam tcb_lite_cfg_t CFG_LSU = '{HSK: '{  1, 1'b0}, BUS: '{1'b0,   0, XLEN, XLEN,   0}};
    localparam tcb_lite_cfg_t CFG_MEM = '{HSK: '{  1, 1'b0}, BUS: '{1'b1,   0, XLEN, XLEN,   0}};

    // system bus
    tcb_lite_if #(CFG_IFU) tcb_ifu         (.clk (clk), .rst (rst));  // instruction fetch unit
    tcb_lite_if #(CFG_LSU) tcb_lsu         (.clk (clk), .rst (rst));  // load/store unit
    tcb_lite_if #(CFG_MEM) tcb_mem [2-1:0] (.clk (clk), .rst (rst));  // 2 port memory model

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

    r5p_degu #(
        // RISC-V ISA
        .ISA  (ISA),
        // system bus implementation details
        .IFU_RST (IFU_RST),
        .IFU_MSK (IFU_MSK)
    ) dut (
        // system signals
        .clk     (clk),
        .rst     (rst),
        // TCB system bus
        .tcb_ifu (tcb_ifu),
        .tcb_lsu (tcb_lsu)
    );

////////////////////////////////////////////////////////////////////////////////
// protocol checker
////////////////////////////////////////////////////////////////////////////////

    tcb_lite_vip_protocol_checker tcb_ifu_chk (.mon (tcb_ifu));
    tcb_lite_vip_protocol_checker tcb_lsu_chk (.mon (tcb_lsu));

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

    // convert from LOG_SIZE to BYTE_ENA mode
    tcb_lite_lib_logsize2byteena #(
        .ALIGNED (1'b0)
    ) tcb_ifu_cnv (
        .sub  (tcb_ifu),
        .man  (tcb_mem[0])
    );

    // convert from LOG_SIZE to BYTE_ENA mode
    tcb_lite_lib_logsize2byteena #(
        .ALIGNED (1'b0)
    ) tcb_lsu_cnv (
        .sub  (tcb_lsu),
        .man  (tcb_mem[1])
    );

    tcb_lite_vip_memory #(
        .FILE (""),
        .SIZE (MEM_SIZ),
        .IFN  (2),
        .WRM  (2'b10)
    ) mem (
        .sub  (tcb_mem[1:0])
    );

    // memory initialization file is provided at runtime
    initial
    begin
        string filename;
        // trace file if name is combined from plusargs (directory) and parameter (file)
        if ($value$plusargs({FILE_ARG, "=%s"}, filename)) begin
            filename = {filename, FILE_PAR};
            $display("Loading file into memory: %s", filename);
            void'(mem.read_bin(filename));
            void'(r5p_htif.read_bin(filename));
        end else begin
            $display("ERROR: memory load file argument not found.");
            $finish;
        end
    end

////////////////////////////////////////////////////////////////////////////////
// RISCOF
////////////////////////////////////////////////////////////////////////////////

    r5p_htif #(
        // memory
        .MEM_ADR (IFU_RST),
        .MEM_SIZ (MEM_SIZ),
        // miscellaneous
        .TIMEOUT (20000)
    ) r5p_htif (
        .tcb (tcb_lsu)
    );

////////////////////////////////////////////////////////////////////////////////
// Verbose execution trace
////////////////////////////////////////////////////////////////////////////////

`ifdef TRACE_SPIKE

    // TODO: instead of an address width decode the ISA
    localparam int unsigned AW = 5;

    logic [XLEN-1:0] gpr_tmp [0:2**AW-1];
    logic [XLEN-1:0] gpr_dly [0:2**AW-1] = '{default: '0};

    // GPR change log
    always_ff @(posedge clk)
    begin
        // delayed copy of all GPR
        gpr_dly <= gpr_tmp;
        // check each GPR for changes
        for (int unsigned i=0; i<32; i++) begin
            if (gpr_dly[i] != gpr_tmp[i]) begin
                $display("%t, Info   %8h <= %s <= %8h", $time, gpr_dly[i], gpr_n(i[5-1:0], 1'b1), gpr_tmp[i]);
            end
        end
    end

    // tracer format class specialization (for Spike)
    typedef trace_spike_pkg::trace_spike #(XLEN) format_spike;

    // trace with given format
    r5p_degu_trace #(
        .XLEN   (XLEN),
        .FORMAT (format_spike),
        .FILE_PAR ("dut.trace.spike")
    ) trace_spike (
        // GPR register file array
        // hierarchical path to GPR inside RTL
        .gpr_den  (dut.gpr.e_rd),
        .gpr_did  (dut.gpr.a_rd),
        .gpr_ddt  (dut.gpr.d_rd),
        .gpr_sid  (dut.gpr.a_rs1),
        // TCB IFU/LSU system busses
        .tcb_ifu  (tcb_ifu),
        .tcb_lsu  (tcb_lsu)
    );

    // tracer format class specialization (for Sail RISC-V)
    typedef trace_sail_pkg::trace_sail #(XLEN) format_sail;

    // trace with given format
    r5p_degu_trace #(
        .XLEN    (XLEN),
        .FORMAT  (format_sail),
        .FILE_PAR ("dut.trace.sail")
    ) trace_sail (
        // GPR register file array
        // hierarchical path to GPR inside RTL
        .gpr_den  (dut.gpr.e_rd),
        .gpr_did  (dut.gpr.a_rd),
        .gpr_ddt  (dut.gpr.d_rd),
        .gpr_sid  (dut.gpr.a_rs1),
        // TCB IFU/LSU system busses
        .tcb_ifu  (tcb_ifu),
        .tcb_lsu  (tcb_lsu)
    );

`endif

////////////////////////////////////////////////////////////////////////////////
// Waveforms
////////////////////////////////////////////////////////////////////////////////

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0);
    end

endmodule: r5p_degu_riscof_tb
