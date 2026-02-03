////////////////////////////////////////////////////////////////////////////////
// R5P: Mouse SoC
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

module r5p_mouse_soc_top
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

    // convert from TCB_LOG_SIZE to TCB_BYTE_ENA mode
    tcb_lite_lib_logsize2byteena tcb_mem_converter (
        .sub  (tcb_dmx[0]),
        .man  (tcb_mem)
    );

    // register request path to convert from DLY=1 CPU to DLY=0 peripherals
    tcb_lite_lib_register_request tcb_lsu_register (
        .sub  (tcb_dmx[1]),
        .man  (tcb_pb0)
    );

    logic [$clog2(2)-1:0] tcb_pb0_sel;

    // decoding peripherals (GPIO/UART)
    tcb_lite_lib_decoder #(
        .ADR (CFG_CPU.BUS.ADR),
        .IFN (2),
        .DAM ({{17'bx, 15'bxx_xxxx_x1xx_xxxx},   // 0x40 ~ 0x7f - UART controller
               {17'bx, 15'bxx_xxxx_x0xx_xxxx}})  // 0x00 ~ 0x3f - GPIO controller
    ) tcb_pb0_dec (
        .mon  (tcb_pb0),
        .sel  (tcb_pb0_sel)
    );

    // demultiplexing peripherals (GPIO/UART)
    tcb_lite_lib_demultiplexer #(
        .IFN (2)
    ) tcb_pb0_demux (
        // control
        .sel  (tcb_pb0_sel),
        // TCB interfaces
        .sub  (tcb_pb0),
        .man  (tcb_per)
    );

////////////////////////////////////////////////////////////////////////////////
// memory instances
////////////////////////////////////////////////////////////////////////////////

    // shared code/data memory
    r5p_soc_memory #(
        .FNM  (MEM_FNM),
        .SIZ  (MEM_SIZ)
    ) mem (
        .sub  (tcb_mem)
    );

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

    generate
    if (ENA_GPIO) begin: gen_gpio

        // GPIO controller
        tcb_lite_peri_gpio #(
            .GPIO_DAT (GPIO_DAT),
            .SYS_MIN  (1'b1)
        ) gpio (
            // GPIO signals
            .gpio_o  (gpio_o),
            .gpio_e  (gpio_e),
            .gpio_i  (gpio_i),
            // bus interface
            .sub     (tcb_per[0]),
            .irq     ()
        );

    end: gen_gpio
    else begin: gen_gpio_err

        // error response
        tcb_lite_lib_error gpio_err (
            .sub  (tcb_per[0]),
            .sts  ('0)
        );

        // GPIO signals
        assign gpio_o = '0;
        assign gpio_e = '0;
        //     gpio_i

    end: gen_gpio_err
    endgenerate

////////////////////////////////////////////////////////////////////////////////
// UART
////////////////////////////////////////////////////////////////////////////////

    generate
    if (ENA_UART) begin: gen_uart

        // baudrate parameters (divider and counter width)
        localparam int unsigned BDR = 50_000_000 / 115_200;  // 50MHz / 115200 = 434.0
        localparam int unsigned UART_BDR = $clog2(BDR);  // a 9-bit counter is required

        // UART controller
        tcb_lite_peri_uart #(
            // UART parameters
            .UART_BDR       (UART_BDR),
            .FIFO_SIZ       (FIFO_SIZ),
            // configuration register parameters (write enable, reset value)
            .CFG_TX_BDR_WEN (1'b0),  .CFG_TX_BDR_RST (UART_BDR'(BDR)),
            .CFG_TX_IRQ_WEN (1'b0),  .CFG_TX_IRQ_RST ('x),
            .CFG_RX_BDR_WEN (1'b0),  .CFG_RX_BDR_RST (UART_BDR'(BDR)),
            .CFG_RX_SMP_WEN (1'b0),  .CFG_RX_SMP_RST (UART_BDR'(BDR/2)),
            .CFG_RX_IRQ_WEN (1'b0),  .CFG_RX_IRQ_RST ('x),
            // TCB parameters
            .SYS_MIN (1'b1)
        ) uart (
            // UART signals
            .uart_txd (uart_txd),
            .uart_rxd (uart_rxd),
            // TCB-Lite interface
            .sub      (tcb_per[1]),
            // interrupts
            .irq_tx   (),
            .irq_rx   ()
        );

    end: gen_uart
    else begin: gen_uart_err

        // error response
        tcb_lite_lib_error uart_err (
            .sub (tcb_per[1]),
            .sts  ('x)
        );

        // UART signals
        assign uart_txd = 1'b1;
        //     uart_rxd

    end: gen_uart_err
    endgenerate

endmodule: r5p_mouse_soc_top
