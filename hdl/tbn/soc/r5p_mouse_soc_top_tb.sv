////////////////////////////////////////////////////////////////////////////////
// R5P mouse: testbench for SoC
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

module r5p_mouse_soc_top_tb #(
    // constants used across the design in signal range sizing instead of literals
    localparam int unsigned XLEN = 32,
    parameter  int unsigned GLEN = 32,
    // SoC peripherals
    parameter  bit          ENA_GPIO = 1'b1,
    parameter  bit          ENA_UART = 1'b0,
    // GPIO
    parameter  int unsigned GPIO_DAT = 32,

    // TCB bus
    parameter  bit [XLEN-1:0] IFU_RST = 32'h8000_0000,
    parameter  bit [XLEN-1:0] IFU_MSK = 32'h8000_3fff,
    parameter  bit [XLEN-1:0] GPR_ADR = 32'h8000_3f80,
    // TCB memory (size in bytes, file name)
    parameter  int unsigned   MEM_SIZ = 2**14,
    parameter  string         MEM_FNM = "mem_if.mem"
);

    // system signals
    logic                     clk = 1'b1;  // clock
    logic                     rst = 1'b1;  // reset
    
    // GPIO
    wire logic [GPIO_DAT-1:0] gpio_o;  // output
    wire logic [GPIO_DAT-1:0] gpio_e;  // enable
    wire logic [GPIO_DAT-1:0] gpio_i;  // input
    // UART
    wire logic                uart_txd;
    wire logic                uart_rxd;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

    r5p_mouse_soc_top #(
        // SoC peripherals
        .ENA_GPIO (ENA_GPIO),
        .ENA_UART (ENA_UART),
        // GPIO
        .GPIO_DAT (GPIO_DAT),
        // UART
        .FIFO_SIZ (16),
        // TCB bus
        .IFU_RST  (IFU_RST),
        .IFU_MSK  (IFU_MSK),
        .GPR_ADR  (GPR_ADR),
        // TCB memory (size in bytes, file name)
        .MEM_SIZ  (MEM_SIZ),
        .MEM_FNM  (MEM_FNM)
    ) dut (
        // system signals
        .clk      (clk),
        .rst      (rst),
        // GPIO
        .gpio_o   (gpio_o),
        .gpio_e   (gpio_e),
        .gpio_i   (gpio_i),
        // UART
        .uart_rxd (uart_rxd),
        .uart_txd (uart_txd)
    );

    // UART loopback
//    assign uart_rxd = uart_txd;

    // GPIO loopback
    generate
    for (genvar i=0; i<GPIO_DAT; i++) begin: gpio_loopback
        assign gpio_i[i] = gpio_e[i] ? gpio_o[i] : 1'bz;
        pullup gpio_p     (gpio_i[i]);
    end: gpio_loopback
    endgenerate  

////////////////////////////////////////////////////////////////////////////////
// tracing
////////////////////////////////////////////////////////////////////////////////

`ifdef TRACE_HDLDB

    import hdldb_trace_pkg::*;

    // trace with HDLDB format
        // tracer format class specialization
    typedef hdldb_trace_pkg::hdldb #(XLEN) format;

    // trace with Spike format
    r5p_mouse_trace #(
        .FORMAT (format)
    ) trace_hdldb (
        // instruction execution phase
        .pha  (dut.ctl_pha),
        // TCB system bus
        .tcb  (tcb_cpu)
    );

`endif

////////////////////////////////////////////////////////////////////////////////
// test sequence
////////////////////////////////////////////////////////////////////////////////

    // 50ns period is 20MHz frequency
    // 37.037ns period is 27MHz (Tang Nano 9k)
    always #(50ns/2) clk = ~clk;
//    always #(37.037ns/2) clk = ~clk;

    // reset sequence
    initial begin
        repeat(4) @(posedge clk);
        rst <= 1'b0;
        repeat(200) @(posedge clk);
        $finish();
    end

    tcb_lite_vip_protocol_checker chk (.mon (dut.tcb_cpu));

endmodule: r5p_mouse_soc_top_tb
