////////////////////////////////////////////////////////////////////////////////
// R5P: Mouse SoC simple (can be compiled with Yosys without Slang)
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

module r5p_mouse_soc_simple_top
//    import riscv_isa_pkg::*;
    import tcb_lite_pkg::*;
#(
    // constants used across the design in signal range sizing instead of literals
    localparam int unsigned   XLEN = 32,
    // SoC peripherals
    parameter  bit            ENA_GPIO = 1'b1,
    parameter  bit            ENA_UART = 1'b1,
    // GPIO
    parameter  int unsigned   GPIO_DAT = 32,
    // UART
    parameter  int unsigned   FIFO_SIZ = 32,
    // TCB bus
    parameter  bit [XLEN-1:0] IFU_RST = 32'h8000_0000,
    parameter  bit [XLEN-1:0] IFU_MSK = 32'h8000_3fff,
    parameter  bit [XLEN-1:0] GPR_ADR = 32'h8000_3f80,
    // TCB memory (size in bytes, file name)
    parameter  int unsigned   MEM_SIZ = 2**14,  // 16kB
`ifndef YOSYS_STRINGPARAM
    parameter  string         MEM_FNM = "mem_if.mem"
`else
    parameter                 MEM_FNM = "mem_if.mem"
`endif
)(
    // system signals
    input  logic                clk,  // clock
    input  logic                rst,  // reset (active high)
    // GPIO
    output logic [GPIO_DAT-1:0] gpio_o,  // output
    output logic [GPIO_DAT-1:0] gpio_e,  // enable
    input  logic [GPIO_DAT-1:0] gpio_i,  // input
    // UART
    output logic                uart_txd,
    input  logic                uart_rxd
);

////////////////////////////////////////////////////////////////////////////////
// local parameters and parameter validation
////////////////////////////////////////////////////////////////////////////////

    localparam MEM_ADR = $clog2(MEM_SIZ);

// TODO: check if instruction address bus width and instruction memory size fit
// TODO: check if data address bus width and data memory size fit

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // TCB configurations               '{HSK: '{DLY,  HLD}, BUS: '{ MOD, CTL,  ADR,  DAT, STS}}
    localparam tcb_lite_cfg_t CFG_CPU = '{HSK: '{  1, 1'b0}, BUS: '{1'b0,   0, XLEN, XLEN,   0}};
    localparam tcb_lite_cfg_t CFG_MEM = '{HSK: '{  1, 1'b0}, BUS: '{1'b1,   0, XLEN, XLEN,   0}};
    localparam tcb_lite_cfg_t CFG_PER = '{HSK: '{  0, 1'b0}, BUS: '{1'b0,   0, XLEN, XLEN,   0}};

    // system busses
    tcb_lite_if #(CFG_CPU) tcb_cpu         (.clk (clk), .rst (rst));
    tcb_lite_if #(CFG_CPU) tcb_dmx [2-1:0] (.clk (clk), .rst (rst));  // demultiplexer
    tcb_lite_if #(CFG_MEM) tcb_mem         (.clk (clk), .rst (rst));  // memory bus DLY=1
    tcb_lite_if #(CFG_PER) tcb_pb0         (.clk (clk), .rst (rst));  // peripherals bus DLY=0
    tcb_lite_if #(CFG_PER) tcb_per [2-1:0] (.clk (clk), .rst (rst));  // peripherals

////////////////////////////////////////////////////////////////////////////////
// R5P Mouse core instance
////////////////////////////////////////////////////////////////////////////////

    r5p_mouse #(
        .IFU_RST (IFU_RST),
        .IFU_MSK (IFU_MSK),
        .GPR_ADR (GPR_ADR)
    ) cpu (
        // system signals
        .clk     (clk),
        .rst     (rst),
        // TCB system bus (shared by instruction/load/store)
        .tcb_vld (tcb_cpu.vld),
        .tcb_ren (tcb_cpu.req.ren),
        .tcb_wen (tcb_cpu.req.wen),
        .tcb_xen (               ),
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
// instruction fetch/load/store TCB interconnect
////////////////////////////////////////////////////////////////////////////////

    logic [$clog2(2)-1:0] tcb_cpu_sel;

    // decoding memory/peripherals
    tcb_lite_lib_decoder #(
        .ADR (CFG_CPU.BUS.ADR),
        .IFN (2),
        .DAM ({{12'h800, 4'b0001, 16'bxxxx_xxxx_xxxx_xxxx},   // 0x8001_0000 ~ 0x8001_ffff - peripherals
               {12'h800, 4'b0000, 16'bxxxx_xxxx_xxxx_xxxx}})  // 0x8000_0000 ~ 0x8000_ffff - data memory
    ) tcb_lsu_dec (
        .mon  (tcb_cpu    ),
        .sel  (tcb_cpu_sel)
    );

    // demultiplexing memory/peripherals
    tcb_lite_lib_demultiplexer #(
        .IFN (2)
    ) tcb_lsu_demux (
        // control
        .sel  (tcb_cpu_sel),
        // TCB interfaces
        .sub  (tcb_cpu),
        .man  (tcb_dmx)
    );

////////////////////////////////////////////////////////////////////////////////
// memory instances
////////////////////////////////////////////////////////////////////////////////

`ifdef YOSYS_SLANG
    localparam int unsigned MEM_DATA = XLEN;
    localparam int unsigned MEM_SIZE = MEM_SIZ/4;
    `include "mem_if.vh"
`else
    logic [XLEN-1:0] mem [0:MEM_SIZ/4-1];
    initial  $readmemh(MEM_FNM, mem);
`endif

    logic [MEM_ADR-1:2] mem_adr;  // address
    logic       [4-1:0] mem_byt;  // byte_enable
    logic    [XLEN-1:0] mem_wdt;  // write data

    // TODO: handle proper byte mapping
    assign mem_adr = tcb_dmx[0].req.adr[MEM_ADR-1:2];
    assign mem_byt = '1;
    assign mem_wdt = tcb_dmx[0].req.wdt;

    always_ff @(posedge clk)
    if (tcb_dmx[0].trn) begin
        if (~tcb_dmx[0].req.wen) begin
            // read
            tcb_dmx[0].rsp.rdt <= mem[mem_adr];
        end else begin
            // write
            if (mem_byt[0]) mem[mem_adr][ 7: 0] <= mem_wdt[ 7: 0];
            if (mem_byt[1]) mem[mem_adr][15: 8] <= mem_wdt[15: 8];
            if (mem_byt[2]) mem[mem_adr][23:16] <= mem_wdt[23:16];
            if (mem_byt[3]) mem[mem_adr][31:24] <= mem_wdt[31:24];
        end
    end

    // there are no error conditions
    assign tcb_dmx[0].rsp.sts =   '0;
    assign tcb_dmx[0].rsp.err = 1'b0;

    // there is no backpressure
    assign tcb_dmx[0].rdy = 1'b1;

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

    logic [GPIO_DAT-1:0] gpio_r [1:0];

    // input resynchronization
    always @(posedge clk)
    begin
        gpio_r[0] <= gpio_i;
        gpio_r[1] <= gpio_r[0];
    end

    logic               per_ena;  // enable
    logic               per_wen;  // write enable
    logic [MEM_ADR-1:2] per_adr;  // address
    logic    [XLEN-1:0] per_wdt;  // write data

    // delayed peripheral transfer
    always_ff @(posedge clk, posedge rst)
    if (rst)  per_ena <= 1'b0;
    else      per_ena <= tcb_dmx[1].trn;

    // delayed peripheral request
    always_ff @(posedge clk)
    if (tcb_dmx[1].trn) begin
        per_wen <= tcb_cpu.req.wen;
        per_adr <= tcb_cpu.req.adr[MEM_ADR-1:2];
        per_wdt <= tcb_cpu.req.wdt;
    end

    // GPIO write access
    always_ff @(posedge clk, posedge rst)
    if (rst) begin
        gpio_o <= '0;
        gpio_e <= '0;
    end else begin
        if (per_ena & per_wen) begin
            if (per_adr[2] == 1'b0) gpio_o <= per_wdt[GPIO_DAT-1:0];
            if (per_adr[2] == 1'b1) gpio_e <= per_wdt[GPIO_DAT-1:0];
        end
    end

    always_comb
    case (per_adr[3:2])
        2'b00:    tcb_dmx[1].rsp.rdt = gpio_o;
        2'b01:    tcb_dmx[1].rsp.rdt = gpio_e;
        2'b10:    tcb_dmx[1].rsp.rdt = gpio_r[1];
        default:  tcb_dmx[1].rsp.rdt = 'x;
    endcase

    // there are no error conditions
    assign tcb_dmx[1].rsp.sts =   '0;
    assign tcb_dmx[1].rsp.err = 1'b0;

    // there is no backpressure
    assign tcb_dmx[1].rdy = 1'b1;

////////////////////////////////////////////////////////////////////////////////
// UART
////////////////////////////////////////////////////////////////////////////////

    // UART is just a loopback
    // register used to avoid combinational loop in testbench
    always_ff @(posedge clk)
    uart_txd <= uart_rxd;

endmodule: r5p_mouse_soc_simple_top
