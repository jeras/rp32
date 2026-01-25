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

module r5p_mouse_soc_simple_top #(
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
    parameter  int unsigned   MEM_ADR = 14,
    parameter  int unsigned   MEM_SIZ = (XLEN/8)*(2**MEM_ADR),
    parameter  string         MEM_FNM = "mem_if.mem"
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

    // TCB system bus (shared by instruction/load/store)
    logic            tcb_vld;  // valid
    logic            tcb_ren;  // write enable
    logic            tcb_wen;  // write enable
    logic            tcb_xen;  // write enable
    logic [XLEN-1:0] tcb_adr;  // address
    logic    [2-1:0] tcb_siz;  // RISC-V func3[1:0]
    logic [XLEN-1:0] tcb_wdt;  // write data
    logic [XLEN-1:0] tcb_rdt;  // read data
    logic            tcb_err;  // error
    logic            tcb_rdy;  // ready

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
        .tcb_vld (tcb_vld),
        .tcb_ren (tcb_ren),
        .tcb_wen (tcb_wen),
        .tcb_xen (tcb_xen),
        .tcb_adr (tcb_adr),
        .tcb_siz (tcb_siz),
        .tcb_wdt (tcb_wdt),
        .tcb_rdt (tcb_rdt),
        .tcb_err (tcb_err),
        .tcb_rdy (tcb_rdy)
    );

    // there are no error conditions
    assign tcb_err = 1'b0;

    // there is no backpressure
    assign tcb_rdy = 1'b1;

////////////////////////////////////////////////////////////////////////////////
// instruction fetch/load/store TCB interconnect
////////////////////////////////////////////////////////////////////////////////

    // system bus memory signals
    logic               mem_ena;  // enable
    logic    [XLEN-1:0] mem_rdt;  // read data

    // system bus peripheral signals (no byte enable)
    logic               per_ena;  // enable
    logic    [XLEN-1:0] per_rdt;  // read data

    // delayed address for TCB response data multiplexer
    logic    [XLEN-1:0] dly_adr;  // address

    always_ff @(posedge clk)
    dly_adr <= tcb_adr;

    // system bus address decoder
    assign mem_ena = (tcb_vld & tcb_rdy) & (tcb_adr[16] == 1'b0);
    assign per_ena = (tcb_vld & tcb_rdy) & (tcb_adr[16] == 1'b1);

    // system bus response multiplexer
    assign tcb_rdt = dly_adr[16] ? per_rdt : mem_rdt;

////////////////////////////////////////////////////////////////////////////////
// memory instances
////////////////////////////////////////////////////////////////////////////////

    logic [XLEN-1:0] mem [0:MEM_SIZ/4-1];

    logic [MEM_ADR-1:2] mem_adr;  // address
    logic       [4-1:0] mem_byt;  // byte_enable
    logic    [XLEN-1:0] mem_wdt;  // write data

    // TODO: handle proper byte mapping
    assign mem_adr = tcb_adr[MEM_ADR-1:2];
    assign mem_byt = '1;
    assign mem_wdt = tcb_wdt;

    always_ff @(posedge clk)
    if (mem_ena) begin
        if (~tcb_wen) begin
            // read
            mem_rdt <= mem[mem_adr];
        end else begin
            // write
            if (mem_byt[0]) mem[mem_adr][ 7: 0] <= mem_wdt[ 7: 0];
            if (mem_byt[1]) mem[mem_adr][15: 8] <= mem_wdt[15: 8];
            if (mem_byt[2]) mem[mem_adr][23:16] <= mem_wdt[23:16];
            if (mem_byt[3]) mem[mem_adr][31:24] <= mem_wdt[31:24];
        end
    end

    initial  $readmemh(MEM_FNM, mem);

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

    // GPIO write access
    always_ff @(posedge clk, posedge rst)
    if (rst) begin
        gpio_o <= '0;
        gpio_e <= '0;
    end else begin
        if (per_ena & tcb_wen) begin
            if (tcb_adr[2] == 1'b0) gpio_o <= tcb_wdt[GPIO_DAT-1:0];
            if (tcb_adr[2] == 1'b1) gpio_e <= tcb_wdt[GPIO_DAT-1:0];
        end
    end

    always_comb
    casex (tcb_adr[3:2])
        2'b00:    per_rdt = gpio_o;
        2'b01:    per_rdt = gpio_e;
        default:  per_rdt = gpio_i;
    endcase

endmodule: r5p_mouse_soc_simple_top
