////////////////////////////////////////////////////////////////////////////////
// R5P Degu SoC
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

module r5p_degu_soc_top
    import riscv_isa_pkg::*;
    import tcb_lite_pkg::*;
#(
    // constants used across the design in signal range sizing instead of literals
    localparam int unsigned XLEN = 32,
    localparam int unsigned XLOG = $clog2(XLEN),
    localparam int unsigned BLEN = XLEN/8,
    localparam int unsigned BLOG = $clog2(BLEN),
    // SoC peripherals
    parameter  bit            ENA_GPIO = 1'b1,
    parameter  bit            ENA_UART = 1'b0,
    // GPIO
    parameter  int unsigned   GPIO_DAT = 32,
    // UART
    parameter  int unsigned   FIFO_SIZ = 32,
    // RISC-V ISA
`ifndef SYNOPSYS_VERILOG_COMPILER
    // extensions  (see `riscv_isa_pkg` for enumeration definition)
    parameter  isa_ext_t    XTEN = RV_C,
    // privilige modes
    parameter  isa_priv_t   MODES = MODES_M,
    // ISA
`ifdef ENABLE_CSR
    parameter  isa_t        ISA = '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES},
`else
    parameter  isa_t        ISA = '{spec: RV32IC, priv: MODES_NONE},
`endif
`endif
    // IFU bus
    parameter  bit [XLEN-1:0] IFU_RST = 32'h8000_0000,
    parameter  bit [XLEN-1:0] IFU_MSK = 32'h8000_3fff,
    // IFU memory (size in bytes, file name)
    parameter  int unsigned   IFM_ADR = 14,
    parameter  int unsigned   IFM_SIZ = (XLEN/8)*(2**IFM_ADR),
    parameter  string         IFM_FNM = "mem_if.mem",
    // LSU bus
    parameter  bit [XLEN-1:0] LSU_MSK = 32'h8000_7fff,
    // LSU memory (size)
    parameter  int unsigned   LSM_ADR = 14,
    parameter  int unsigned   LSM_SIZ = (XLEN/8)*(2**LSM_ADR)
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

`ifdef SYNOPSYS_VERILOG_COMPILER
    parameter isa_t ISA = '{spec: RV32I, priv: MODES_NONE};
`endif

////////////////////////////////////////////////////////////////////////////////
// local parameters and parameter validation
////////////////////////////////////////////////////////////////////////////////

// TODO: check if instruction address bus width and instruction memory size fit
// TODO: check if data address bus width and data memory size fit

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // TCB configurations               '{HSK: '{DLY,  HLD}, BUS: '{ MOD, CTL,  ADR,  DAT, STS}}
    localparam tcb_lite_cfg_t CFG_IFU = '{HSK: '{  1, 1'b0}, BUS: '{1'b0,   0, XLEN, XLEN,   0}};
    localparam tcb_lite_cfg_t CFG_LSU = '{HSK: '{  1, 1'b0}, BUS: '{1'b0,   0, XLEN, XLEN,   0}};
    localparam tcb_lite_cfg_t CFG_MEM = '{HSK: '{  1, 1'b0}, BUS: '{1'b1,   0, XLEN, XLEN,   0}};
    localparam tcb_lite_cfg_t CFG_PER = '{HSK: '{  0, 1'b0}, BUS: '{1'b0,   0, XLEN, XLEN,   0}};

    // system busses
    tcb_lite_if #(CFG_IFU) tcb_ifu         (.clk (clk), .rst (rst));  // instruction fetch unit (RISC-V mode)
    tcb_lite_if #(CFG_MEM) tcb_ifm         (.clk (clk), .rst (rst));  // instruction fetch unit (MEMORY mode)
    tcb_lite_if #(CFG_LSU) tcb_lsu         (.clk (clk), .rst (rst));  // load/store unit
    tcb_lite_if #(CFG_LSU) tcb_lsd [2-1:0] (.clk (clk), .rst (rst));  // load/store demultiplexer
    tcb_lite_if #(CFG_MEM) tcb_lsm         (.clk (clk), .rst (rst));  // memory bus DLY=1
    tcb_lite_if #(CFG_PER) tcb_pb0         (.clk (clk), .rst (rst));  // peripherals bus DLY=0
    tcb_lite_if #(CFG_PER) tcb_per [2-1:0] (.clk (clk), .rst (rst));  // peripherals

////////////////////////////////////////////////////////////////////////////////
// R5P Degu core instance
////////////////////////////////////////////////////////////////////////////////

    r5p_degu #(
        // RISC-V ISA
        .ISA     (ISA),
        // system bus implementation details
        .IFU_RST (IFU_RST),
        .IFU_MSK (IFU_MSK)
    ) cpu (
        // system signals
        .clk     (clk),
        .rst     (rst),
        // TCB system bus
        .tcb_ifu (tcb_ifu),
        .tcb_lsu (tcb_lsu)
    );

////////////////////////////////////////////////////////////////////////////////
// instruction fetch TCB interconnect
////////////////////////////////////////////////////////////////////////////////

    // convert from TCB_LOG_SIZE to TCB_BYTE_ENA mode
    tcb_lite_lib_logsize2byteena #(
        .ALIGNED (1'b0)
    ) tcb_ifu_logsize2byteena (
        .sub  (tcb_ifu),
        .man  (tcb_ifm)
    );

////////////////////////////////////////////////////////////////////////////////
// load/store TCB interconnect
////////////////////////////////////////////////////////////////////////////////

    logic [$clog2(2)-1:0] tcb_lsu_sel;

    // decoding memory/peripherals
    tcb_lite_lib_decoder #(
        .ADR (CFG_LSU.BUS.ADR),
        .IFN (2),
        .DAM ({{17'b0, 1'b1, 14'bxx_xxxx_xxxx_xxxx},   // 0x20_0000 ~ 0x2f_ffff - peripherals
               {17'b0, 1'b0, 14'bxx_xxxx_xxxx_xxxx}})  // 0x00_0000 ~ 0x1f_ffff - data memory
    ) tcb_lsu_dec (
        .mon  (tcb_lsu    ),
        .sel  (tcb_lsu_sel)
    );

    // demultiplexing memory/peripherals
    tcb_lite_lib_demultiplexer #(
        .IFN (2)
    ) tcb_lsu_demux (
        // control
        .sel  (tcb_lsu_sel),
        // TCB interfaces
        .sub  (tcb_lsu),
        .man  (tcb_lsd)
    );

    // convert from TCB_LOG_SIZE to TCB_BYTE_ENA mode
    tcb_lite_lib_logsize2byteena tcb_lsm_logsize2byteena (
        .sub  (tcb_lsd[0]),
        .man  (tcb_lsm)
    );

    // register request path to convert from DLY=1 CPU to DLY=0 peripherals
    tcb_lite_lib_register_request tcb_lsu_register (
        .sub  (tcb_lsd[1]),
        .man  (tcb_pb0)
    );

    logic [$clog2(2)-1:0] tcb_pb0_sel;

    // decoding peripherals (GPIO/UART)
    tcb_lite_lib_decoder #(
        .ADR (CFG_LSU.BUS.ADR),
        .IFN (2),
        .DAM ({{17'bx, 15'bxx_xxxx_x1xx_xxxx},   // 0x20_0000 ~ 0x2f_ffff - 0x40 ~ 0x7f - UART controller
               {17'bx, 15'bxx_xxxx_x0xx_xxxx}})  // 0x20_0000 ~ 0x2f_ffff - 0x00 ~ 0x3f - GPIO controller
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

    // instruction memory
    r5p_soc_memory #(
        .FNM  (IFM_FNM),
        .SIZ  (IFM_SIZ)
    ) imem (
        .sub  (tcb_ifm)
    );

    // data memory
    r5p_soc_memory #(
    //.FNM  (),
        .SIZ  (LSM_SIZ)
    ) dmem (
        .sub  (tcb_lsm)
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
            .irq     ()  // TODO
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

endmodule: r5p_degu_soc_top
