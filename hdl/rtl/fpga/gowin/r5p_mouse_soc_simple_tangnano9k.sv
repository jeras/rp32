////////////////////////////////////////////////////////////////////////////////
// R5P mouse: SoC simple for Tang Nano 9k development board
//
// NOTE: details on XPM libraries: ug953-vivado-7series-libraries.pdf
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

module r5p_mouse_soc_simple_tangnano9k (
    // 27MHz clock
    input  logic       XTAL_IN,
    // buttons
    input  logic [2:1] S,
    // LEDs (orange)
    output logic [6:1] LED,
    // UART
    output logic       FPGA_TX,
    output logic       FPGA_RX
);

///////////////////////////////////////////////////////////////////////////////
// local parameters
////////////////////////////////////////////////////////////////////////////////

    localparam int unsigned GPIO_DAT = $bits(LED);

///////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // clock
    logic clk;

    // reset synchronizer
    logic rst;

    // GPIO
    logic [GPIO_DAT-1:0] gpio_o;
    logic [GPIO_DAT-1:0] gpio_e;
    logic [GPIO_DAT-1:0] gpio_i;

///////////////////////////////////////////////////////////////////////////////
// PLL
////////////////////////////////////////////////////////////////////////////////

    // TODO: use proper PLL
    assign clk = XTAL_IN;

///////////////////////////////////////////////////////////////////////////////
// reset synchronizer
////////////////////////////////////////////////////////////////////////////////

    // TODO: use proper button debauncing and synchronous release reset
    assign rst = S[1];

    //logic rst_r;

    //always @(posedge clk, negedge ck_rst)
    //if (~ck_rst)  {rst, rst_r} <= 2'b1;
    //else          {rst, rst_r} <= {rst_r, 1'b0};

//    // xpm_cdc_async_rst: Asynchronous Reset Synchronizer
//    // Xilinx Parameterized Macro, version 2024.2
//    xpm_cdc_async_rst #(
//        .DEST_SYNC_FF    (4), // DECIMAL; range: 2-10
//        .INIT_SYNC_FF    (0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
//        .RST_ACTIVE_HIGH (1)  // DECIMAL; 0=active low reset, 1=active high reset
//    ) xpm_cdc_async_rst_inst (
//        .src_arst  (~ck_rst),
//        .dest_arst (rst),
//        .dest_clk  (clk)
//    );

////////////////////////////////////////////////////////////////////////////////
// R5P SoC instance
////////////////////////////////////////////////////////////////////////////////

    r5p_mouse_soc_simple_top #(
        .GPIO_DAT  (GPIO_DAT),
        .FIFO_SIZ  (16),        // UART FIFO is based on Gowin RAM16SDP4
        .MEM_SIZ   (1024*4)     // 4kB
    ) soc (
        // system signals
        .clk       (clk),
        .rst       (rst),
        // GPIO
        .gpio_o    (LED),
        .gpio_e    (),
        .gpio_i    (LED),
        // UART
        .uart_txd  (FPGA_TX),
        .uart_rxd  (FPGA_RX)
    );

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

/*
    // GPIO inputs
    assign gpio_i = LED[GPIO_DAT-1:0];

    // GPIO outputs
    generate
    for (genvar i=0; i<GPIO_DAT; i++) begin
        assign LED[i] = gpio_e[i] ? gpio_o[i] : 1'bz;
    end
    endgenerate
*/

endmodule: r5p_mouse_soc_simple_tangnano9k
