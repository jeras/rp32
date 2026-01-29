////////////////////////////////////////////////////////////////////////////////
// R5P Mouse RISCOF testbench
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

module r5p_mouse_riscof_tb
    import riscv_isa_pkg::*;
    import tcb_lite_pkg::*;
#(
    // constants used across the design in signal range sizing instead of literals
    localparam int unsigned XLEN = 32,
    localparam int unsigned XLOG = $clog2(XLEN),
    localparam int unsigned ILEN = 32,
    // RISC-V ISA
    // extensions  (see `riscv_isa_pkg` for enumeration definition)
    parameter  isa_ext_t    XTEN = '0,
    // privilige modes
    parameter  isa_priv_t   MODES = MODES_M,
    // ISA
`ifdef ENABLE_CSR
    parameter  isa_t        ISA = '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES},
`else
    parameter  isa_t        ISA = '{spec: RV32IC, priv: MODES_NONE},
`endif
    parameter  bit [XLEN-1:0] IFU_RST = 32'h8000_0000,
    parameter  bit [XLEN-1:0] IFU_MSK = 32'h803f_ffff,
    parameter  bit [XLEN-1:0] GPR_ADR = 32'h801f_ff80,
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
        repeat (20000) @(posedge clk);
        $display("ERROR: reached simulation timeout!");
        repeat (4) @(posedge clk);
        $finish();
        /* verilator lint_on INITIALDLY */
    end

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // TCB configurations               '{HSK: '{DLY,  HLD}, BUS: '{ MOD, CTL,  ADR,  DAT, STS}}
    localparam tcb_lite_cfg_t CFG_CPU = '{HSK: '{  1, 1'b0}, BUS: '{1'b0,   0, XLEN, XLEN,   0}};
    localparam tcb_lite_cfg_t CFG_MEM = '{HSK: '{  1, 1'b0}, BUS: '{1'b1,   0, XLEN, XLEN,   0}};

    // system bus
    tcb_lite_if #(CFG_CPU) tcb_cpu       (.clk (clk), .rst (rst));
    tcb_lite_if #(CFG_MEM) tcb_mem [0:0] (.clk (clk), .rst (rst));
    // TODO: handling a Verilator bug, localparam is not handled as a constant
    // %Error: ../../hdl/tbn/riscof/r5p_mouse_riscof_tb.sv:85:19: Can't convert defparam value to constant: Param '__paramNumber1' of 'tcb_cpu'
    //                                                          : ... note: In instance 'r5p_mouse_riscof_tb'
    //    85 |     tcb_lite_if #(CFG_CPU      ) tcb_cpu       (.clk (clk), .rst (rst));
    //       |                   ^~~~~~~
    //         ... See the manual at https://verilator.org/verilator_doc.html?v=5.045 for more assistance.

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

    r5p_mouse #(
        .IFU_RST (IFU_RST),
        .IFU_MSK (IFU_MSK),
        .GPR_ADR (GPR_ADR)
    ) dut (
        // system signals
        .clk     (clk),
        .rst     (rst),
        // TCB system bus (shared by instruction/load/store)
        .tcb_vld (tcb_cpu.vld),
        .tcb_wen (tcb_cpu.req.wen),
        .tcb_ren (tcb_cpu.req.ren),
        .tcb_xen (),
        .tcb_adr (tcb_cpu.req.adr),
        .tcb_siz (tcb_cpu.req.siz),
        .tcb_wdt (tcb_cpu.req.wdt),
        .tcb_rdt (tcb_cpu.rsp.rdt),
        .tcb_err (tcb_cpu.rsp.err),
        .tcb_rdy (tcb_cpu.rdy)
    );

    // signals not provided by the CPU
    assign tcb_cpu.req.lck = 1'b0;
    assign tcb_cpu.req.ndn = 1'b0;

////////////////////////////////////////////////////////////////////////////////
// protocol checker
////////////////////////////////////////////////////////////////////////////////

    tcb_lite_vip_protocol_checker tcb_cpu_chk (.mon (tcb_cpu));
    tcb_lite_vip_protocol_checker tcb_mem_chk (.mon (tcb_mem[0]));

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

    // convert from LOG_SIZE to BYTE_ENA mode
    tcb_lite_lib_logsize2byteena #(
        .ALIGNED (1'b0)
    ) tcb_cnv (
        .sub  (tcb_cpu),
        .man  (tcb_mem[0])
    );

    tcb_lite_vip_memory #(
        .MFN  (""),
        .SIZE (MEM_SIZ),
        .IFN  (1)
    ) mem (
        .sub  (tcb_mem[0:0])
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
        .tcb (tcb_cpu)
    );

////////////////////////////////////////////////////////////////////////////////
// Verbose execution trace
////////////////////////////////////////////////////////////////////////////////

`ifdef TRACE_SPIKE

    // GPR array
    logic [8-1:0] mem_gpr [0:4*8-1];
    logic [XLEN-1:0] gpr [0:32-1];

    // copy GPR array from system memory
    // TODO: apply proper streaming operator
//    assign mem_gpr = mem.mem[GPR_ADR & (MEM_SIZ-1) +: 4*8];
//    assign gpr = {>> XLEN {mem_gpr}};
//    assign gpr = {>> XLEN {mem.mem[GPR_ADR & (MEM_SIZ-1) +: 4*8]}};

    // tracer format class specialization (for Spike)
    typedef trace_spike_pkg::trace_spike #(XLEN) format_spike;

    // trace with given format
    r5p_mouse_trace #(
        .FORMAT   (format_spike),
        .FILE_PAR ("dut.trace.spike")
    ) trace_spike (
        // instruction execution phase
        .pha  (dut.ctl_pha),
        // TCB system bus
        .tcb  (tcb_cpu)
    );

    // tracer format class specialization (for Sail RISC-V)
    typedef trace_sail_pkg::trace_sail #(XLEN) format_sail;

    // trace with given format
    r5p_mouse_trace #(
        .FORMAT  (format_sail),
        .FILE_PAR ("dut.trace.sail")
    ) trace_sail (
        // instruction execution phase
        .pha  (dut.ctl_pha),
        // TCB system bus
        .tcb  (tcb_cpu)
    );

`endif

////////////////////////////////////////////////////////////////////////////////
// Waveforms
////////////////////////////////////////////////////////////////////////////////

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0);
    end

endmodule: r5p_mouse_riscof_tb
