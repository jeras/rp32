////////////////////////////////////////////////////////////////////////////////
// R5P mouse: SoC for Tang Nano 9k development board
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


//Part Number: GW1NR-LV9QN88PC6/I5

IO_LOC  "clk" 52;
IO_LOC  "led[5:0]" 10;
IO_LOC  "key_i" 3;
IO_LOC  "rst_i" 4;
IO_LOC  "clk_i" 52;

IO_LOC  "LED_R" 10;
IO_LOC  "LED_G" 11;
IO_LOC  "LED_B" 13;

// Use buildin USB-serial
IO_LOC  "TXD" 17;
IO_LOC  "RXD" 18;

// fake
IO_LOC  "led[7:6]" 35;

// oser
IO_LOC  "oser_out" 10;
IO_LOC  "io16"     29;
IO_LOC  "pclk_o"   15;
IO_LOC  "fclk_o"   16;

// ides
IO_LOC  "fclk_i" 54;
IO_LOC  "data_i" 29;
IO_LOC  "q_o[7:0]" 68;

// RGB LCD
IO_LOC  "LCD_B[4:0]" 54;
IO_LOC  "LCD_CLK" 35;
IO_LOC  "LCD_DEN" 33;
IO_LOC  "LCD_G[5:0]" 70;
IO_LOC  "LCD_HYNC" 40;
IO_PORT "LCD_HYNC" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=24;
IO_LOC  "LCD_R[0]" 75;
IO_PORT "LCD_R[0]" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=24;
IO_LOC  "LCD_R[1]" 74;
IO_PORT "LCD_R[1]" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=24;
IO_LOC  "LCD_R[2]" 73;
IO_PORT "LCD_R[2]" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=24;
IO_LOC  "LCD_R[3]" 72;
IO_PORT "LCD_R[3]" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=24;
IO_LOC  "LCD_R[4]" 71;
IO_PORT "LCD_R[4]" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=24;
IO_LOC  "LCD_SYNC" 34;
IO_PORT "LCD_SYNC" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=24;
IO_LOC  "LCD_XR"   32;
IO_PORT "LCD_XR" IO_TYPE=LVCMOS33;
IO_LOC  "LCD_XL"   39;
IO_PORT "LCD_XL" IO_TYPE=LVCMOS33;

IO_LOC  "tlvds_p" 25;
IO_PORT "tlvds_p" PULL_MODE=NONE IO_TYPE=LVDS25;
IO_LOC  "tlvds_n" 26;
IO_PORT "tlvds_n" PULL_MODE=NONE IO_TYPE=LVDS25;

IO_LOC  "mipi_out[0]" 25;
IO_PORT "LCD_XL" IO_TYPE=LVCMOS33;
IO_LOC  "mipi_out[1]" 26;
IO_PORT "LCD_XL" IO_TYPE=LVCMOS33;

IO_LOC  "mipi_in[0]" 80;
IO_PORT "mipi_in[0]" IO_TYPE=LVCMOS18;
IO_LOC  "mipi_in[1]" 79;
IO_PORT "mipi_in[1]" IO_TYPE=LVCMOS18;

IO_LOC  "i3c" 25;
IO_PORT "i3c" IO_TYPE=LVCMOS33;

IO_LOC  "elvds_p" 75;
IO_PORT "elvds_p" PULL_MODE=NONE IO_TYPE=LVDS25;
IO_LOC  "elvds_n" 74;
IO_PORT "elvds_n" PULL_MODE=NONE IO_TYPE=LVDS25;

//DVI
IO_LOC  "tmds_d_p[0]" 71;
IO_PORT "tmds_d_p[0]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "tmds_d_n[0]" 70;
IO_PORT "tmds_d_n[0]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "tmds_d_p[1]" 73;
IO_PORT "tmds_d_p[1]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "tmds_d_n[1]" 72;
IO_PORT "tmds_d_n[1]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "tmds_d_p[2]" 75;
IO_PORT "tmds_d_p[2]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "tmds_d_n[2]" 74;
IO_PORT "tmds_d_n[2]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "tmds_clk_p" 69;
IO_PORT "tmds_clk_p" PULL_MODE=NONE DRIVE=8;
IO_LOC  "tmds_clk_n" 68;
IO_PORT "tmds_clk_n" PULL_MODE=NONE DRIVE=8;

INS_LOC  "clk_div" TOPSIDE[0];

IO_LOC  "div_led" 10;
IO_PORT "div_led" IO_TYPE=LVCMOS18 PULL_MODE=NONE;




module r5p_mouse_soc_arty #(
    // implementation device (ASIC/FPGA vendor/device)
    parameter  string CHIP = "ARTIX_GEN"
)(
    // system signals
    input  logic          CLK100MHZ,  // clock
    input  logic          ck_rst,     // reset (active low)
    // GPIO
    inout  wire  [42-1:0] ck_io,
    // UART
    output wire           uart_rxd_out,
    input  wire           uart_txd_in
);

///////////////////////////////////////////////////////////////////////////////
// local parameters
////////////////////////////////////////////////////////////////////////////////

    localparam int unsigned GDW = 32;

///////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // clock
    logic clk;

    // reset synchronizer
    logic rst;

    // GPIO
    logic [GDW-1:0] gpio_o;
    logic [GDW-1:0] gpio_e;
    logic [GDW-1:0] gpio_i;

///////////////////////////////////////////////////////////////////////////////
// PLL
////////////////////////////////////////////////////////////////////////////////

    // TODO: use proper PLL
    assign clk = CLK100MHZ;

///////////////////////////////////////////////////////////////////////////////
// reset synchronizer
////////////////////////////////////////////////////////////////////////////////

    //logic rst_r;

    //always @(posedge clk, negedge ck_rst)
    //if (~ck_rst)  {rst, rst_r} <= 2'b1;
    //else          {rst, rst_r} <= {rst_r, 1'b0};

    // xpm_cdc_async_rst: Asynchronous Reset Synchronizer
    // Xilinx Parameterized Macro, version 2024.2
    xpm_cdc_async_rst #(
        .DEST_SYNC_FF    (4), // DECIMAL; range: 2-10
        .INIT_SYNC_FF    (0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        .RST_ACTIVE_HIGH (1)  // DECIMAL; 0=active low reset, 1=active high reset
    ) xpm_cdc_async_rst_inst (
        .src_arst  (~ck_rst),
        .dest_arst (rst),
        .dest_clk  (clk)
    );

////////////////////////////////////////////////////////////////////////////////
// R5P SoC instance
////////////////////////////////////////////////////////////////////////////////

    r5p_mouse_soc_top #(
        .GDW       (GDW)
    ) soc (
        // system signals
        .clk       (clk),
        .rst       (rst),
        // GPIO
        .gpio_o    (gpio_o),
        .gpio_e    (gpio_e),
        .gpio_i    (gpio_i),
        // UART
        .uart_txd  (uart_rxd_out),
        .uart_rxd  (uart_txd_in )
    );

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

    // GPIO inputs
    assign gpio_i = ck_io[GDW-1:0];

    // GPIO outputs
    generate
    for (genvar i=0; i<GDW; i++) begin
        assign ck_io[i] = gpio_e[i] ? gpio_o[i] : 1'bz;
    end
    endgenerate

    // unused IO
    assign ck_io[42-1:GDW] = 1'bz;

endmodule: r5p_mouse_soc_arty

