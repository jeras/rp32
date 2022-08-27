// ============================================================================
// Copyright (c) 2014 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development
//   Kits made by Terasic.  Other use of this code, including the selling
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use
//   or functionality of this code.
//
// ============================================================================
//
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// ============================================================================
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Yue Yang          :| 08/25/2014:| Initial Revision
// ============================================================================

//`define Enable_DRAM
`define Enable_GPIO
//`define Enable_HEX
//`define Enable_KEY
//`define Enable_LEDR
//`define Enable_PS2
`define Enable_RESET
//`define Enable_SD
//`define Enable_SW
//`define Enable_VGA

module r5p_soc_de0_cv (
      // clock inputs
      input  wire        CLOCK_50,   // CLOCK  "3.3-V LVTTL"
      input  wire        CLOCK2_50,  // CLOCK2 "3.3-V LVTTL"
      input  wire        CLOCK3_50,  // CLOCK3 "3.3-V LVTTL"
      inout  wire        CLOCK4_50,  // CLOCK4 "3.3-V LVTTL"
`ifdef Enable_DRAM
      // DRAM  "3.3-V LVTTL"
      output wire [12:0] DRAM_ADDR,
      output wire  [1:0] DRAM_BA,
      output wire        DRAM_CAS_N,
      output wire        DRAM_CKE,
      output wire        DRAM_CLK,
      output wire        DRAM_CS_N,
      inout  wire [15:0] DRAM_DQ,
      output wire        DRAM_LDQM,
      output wire        DRAM_RAS_N,
      output wire        DRAM_UDQM,
      output wire        DRAM_WE_N,
`endif
`ifdef Enable_GPIO
      // GPIO
      inout  wire [35:0] GPIO_0,  // GPIO "3.3-V LVTTL"
      inout  wire [35:0] GPIO_1,  // GPIO "3.3-V LVTTL"
`endif
`ifdef Enable_HEX
      // HEX
      output wire  [6:0] HEX0,  // HEX0  "3.3-V LVTTL"
      output wire  [6:0] HEX1,  // HEX1  "3.3-V LVTTL"
      output wire  [6:0] HEX2,  // HEX2  "3.3-V LVTTL"
      output wire  [6:0] HEX3,  // HEX3  "3.3-V LVTTL"
      output wire  [6:0] HEX4,  // HEX4  "3.3-V LVTTL"
      output wire  [6:0] HEX5,  // HEX5  "3.3-V LVTTL"
`endif
`ifdef Enable_KEY
      ///////// KEY  "3.3-V LVTTL" /////////
      input  wire  [3:0] KEY,
`endif
`ifdef Enable_LEDR
      ///////// LEDR /////////
      output wire  [9:0] LEDR,
`endif
`ifdef Enable_PS2
      ///////// PS2 "3.3-V LVTTL" /////////
      inout  wire        PS2_CLK,
      inout  wire        PS2_CLK2,
      inout  wire        PS2_DAT,
      inout  wire        PS2_DAT2,
`endif
`ifdef Enable_RESET
      ///////// RESET "3.3-V LVTTL" /////////
      input  wire        RESET_N
`endif
`ifdef Enable_SD
      ///////// SD "3.3-V LVTTL" /////////
      output wire        SD_CLK,
      inout  wire        SD_CMD,
      inout  wire  [3:0] SD_DATA,
`endif
`ifdef Enable_SW
      ///////// SW "3.3-V LVTTL"/////////
      input  wire  [9:0] SW,
`endif
`ifdef Enable_VGA
      ///////// VGA  "3.3-V LVTTL" /////////
      output wire  [3:0] VGA_B,
      output wire  [3:0] VGA_G,
      output wire        VGA_HS,
      output wire  [3:0] VGA_R,
      output wire        VGA_VS
`endif
);

///////////////////////////////////////////////////////////////////////////////
// local parameters
////////////////////////////////////////////////////////////////////////////////

localparam int unsigned GW = 32;

///////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// clock
logic clk;

// reset synchronizer
logic rst;

// GPIO
logic [GW-1:0] gpio_o;
logic [GW-1:0] gpio_e;
logic [GW-1:0] gpio_i;

///////////////////////////////////////////////////////////////////////////////
// PLL
////////////////////////////////////////////////////////////////////////////////

// TODO: use proper PLL
assign clk = CLOCK_50;

///////////////////////////////////////////////////////////////////////////////
// reset synchronizer
////////////////////////////////////////////////////////////////////////////////

logic rst_r;

always @(posedge clk, negedge RESET_N)
if (~RESET_N)  {rst, rst_r} <= 2'b1;
else           {rst, rst_r} <= {rst_r, 1'b0};

////////////////////////////////////////////////////////////////////////////////
// R5P SoC instance
////////////////////////////////////////////////////////////////////////////////

r5p_degu_soc_top #(
  .GW    (GW),
  .CHIP  ("CYCLONE_V")
) soc (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // GPIO
  .gpio_o  (gpio_o),
  .gpio_e  (gpio_e),
  .gpio_i  (gpio_i)
);

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

// GPIO inputs
assign gpio_i = GPIO_0[GW-1:0];

// GPIO outputs
genvar i;
generate
for (i=0; i<GW; i++) begin: gen_gpio
  assign GPIO_0[i] = gpio_e[i] ? gpio_o[i] : 1'bz;
end: gen_gpio
endgenerate

// unused GPIO
assign GPIO_0[35:GW] = 'z;
assign GPIO_1[35:00] = 'z;

endmodule: r5p_soc_de0_cv