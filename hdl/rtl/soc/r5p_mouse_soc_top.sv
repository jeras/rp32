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

module r5p_mouse_soc_top #(
  /////////////////////////////////////////////////////////////////////////////
  // SoC peripherals
  /////////////////////////////////////////////////////////////////////////////
  bit          ENA_GPIO = 1'b1,
  bit          ENA_UART = 1'b0,
  // GPIO
  int unsigned GW = 32,
  /////////////////////////////////////////////////////////////////////////////
  // interconnect/memories
  /////////////////////////////////////////////////////////////////////////////
  // TCB bus
  int unsigned AW = 14,    // TCB address width (byte address)
  int unsigned DW = 32,    // TCB data    width
  // memory size (in bytes) and initialization file name
  int unsigned IMS = (DW/8)*(2**AW),
  string       IFN = "mem_cpu.vmem",
  /////////////////////////////////////////////////////////////////////////////
  // implementation device (ASIC/FPGA vendor/device)
  /////////////////////////////////////////////////////////////////////////////
  string       CHIP = ""
)(
  // system signals
  input  logic          clk,  // clock
  input  logic          rst,  // reset (active low)
  // GPIO
  output logic [GW-1:0] gpio_o,  // output
  output logic [GW-1:0] gpio_e,  // enable
  input  logic [GW-1:0] gpio_i,  // input
  // UART
  output logic          uart_txd,
  input  logic          uart_rxd
);

///////////////////////////////////////////////////////////////////////////////
// local parameters and checks
////////////////////////////////////////////////////////////////////////////////

// in this SoC the data address space is split in half between memory and peripherals
localparam int unsigned RAW = AW-1;

// TODO: check if instruction address bus width and instruction memory size fit
// TODO: check if data address bus width and data memory size fit

///////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// system busses
tcb_if #(.AW (AW), .DW (DW)) bus_cpu         (.clk (clk), .rst (rst));
tcb_if #(.AW (AW), .DW (DW)) bus_mem [3-1:0] (.clk (clk), .rst (rst));

////////////////////////////////////////////////////////////////////////////////
// R5P Mouse core instance
////////////////////////////////////////////////////////////////////////////////

r5p_mouse #(
  .RST_ADR (32'h0000_0000),
  .GPR_ADR (32'h0000_0000)
) cpu (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // TCL system bus (shared by instruction/load/store)
  .bus_vld (bus_cpu.vld),
  .bus_wen (bus_cpu.wen),
  .bus_adr (bus_cpu.adr),
  .bus_ben (bus_cpu.ben),
  .bus_wdt (bus_cpu.wdt),
  .bus_rdt (bus_cpu.rdt),
  .bus_err (bus_cpu.err),
  .bus_rdy (bus_cpu.rdy)
);

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

tcb_dec #(
  .AW  (AW),
  .DW  (DW),
  .PN  (3),   // port number
  .AS  ({ {1'b1, 14'bxx_xxxx_x1xx_xxxx} ,   // 0x20_0000 ~ 0x2f_ffff - 0x40 ~ 0x7f - UART controller
          {1'b1, 14'bxx_xxxx_x0xx_xxxx} ,   // 0x20_0000 ~ 0x2f_ffff - 0x00 ~ 0x3f - GPIO controller
          {1'b0, 14'bxx_xxxx_xxxx_xxxx} })  // 0x00_0000 ~ 0x1f_ffff - data memory
) ls_dec (
  .sub  (bus_cpu     ),
  .man  (bus_mem[2:0])
);

////////////////////////////////////////////////////////////////////////////////
// memory instances
////////////////////////////////////////////////////////////////////////////////

generate
if (CHIP == "ARTIX_XPM") begin: gen_artix_xpm

  // xpm_memory_spram: Single Port RAM
  // Xilinx Parameterized Macro, version 2021.2
  xpm_memory_spram #(
    .ADDR_WIDTH_A        (RAW-$clog2(4)),   // DECIMAL
    .AUTO_SLEEP_TIME     (0),                 // DECIMAL
    .BYTE_WRITE_WIDTH_A  (8),                 // DECIMAL
    .CASCADE_HEIGHT      (0),                 // DECIMAL
    .ECC_MODE            ("no_ecc"),          // String
    .MEMORY_INIT_FILE    ("none"),            // String
    .MEMORY_INIT_PARAM   ("0"),               // String
    .MEMORY_OPTIMIZATION ("true"),            // String
    .MEMORY_PRIMITIVE    ("auto"),            // String
    .MEMORY_SIZE         (8 * 2**RAW),        // DECIMAL
    .MESSAGE_CONTROL     (0),                 // DECIMAL
    .READ_DATA_WIDTH_A   (DW),               // DECIMAL
    .READ_LATENCY_A      (1),                 // DECIMAL
    .READ_RESET_VALUE_A  ("0"),               // String
    .RST_MODE_A          ("SYNC"),            // String
    .SIM_ASSERT_CHK      (0),                 // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_MEM_INIT        (1),                 // DECIMAL
    .USE_MEM_INIT_MMI    (0),                 // DECIMAL
    .WAKEUP_TIME         ("disable_sleep"),   // String
    .WRITE_DATA_WIDTH_A  (DW),               // DECIMAL
    .WRITE_MODE_A        ("read_first"),      // String
    .WRITE_PROTECT       (1)                  // DECIMAL
  ) mem (
    // unused control/status signals
    .injectdbiterra (1'b0),
    .injectsbiterra (1'b0),
    .dbiterra       (),
    .sbiterra       (),
    .sleep          (1'b0),
    .regcea         (1'b1),
    // system bus
    .clka   (bus_mem[0].clk),
    .rsta   (bus_mem[0].rst),
    .ena    (bus_mem[0].vld),
    .wea    (bus_mem[0].ben & {4{bus_mem[0].wen}}),
    .addra  (bus_mem[0].adr[RAW-1:$clog2(4)]),
    .dina   (bus_mem[0].wdt),
    .douta  (bus_mem[0].rdt)
  );

  assign bus_mem[0].err = 1'b0;
  assign bus_mem[0].rdy = 1'b1;

end: gen_artix_xpm
else if (CHIP == "ARTIX_GEN") begin: gen_artix_gen

  blk_mem_gen_0 mem (
    .clka   (bus_mem[0].clk),
    .ena    (bus_mem[0].vld),
    .wea    (bus_mem[0].ben & {4{bus_mem[0].wen}}),
    .addra  (bus_mem[0].adr[RAW-1:$clog2(4)]),
    .dina   (bus_mem[0].wdt),
    .douta  (bus_mem[0].rdt)
  );

  assign bus_mem[0].err = 1'b0;
  assign bus_mem[0].rdy = 1'b1;

end: gen_artix_gen
else if (CHIP == "CYCLONE_V") begin: gen_cyclone_v

  ram32x4096 mem (
    .clock    (bus_mem[0].clk),
    .wren     (bus_mem[0].vld &  bus_mem[0].wen),
    .rden     (bus_mem[0].vld & ~bus_mem[0].wen),
    .address  (bus_mem[0].adr[RAW-1:$clog2(4)]),
    .byteena  (bus_mem[0].ben),
    .data     (bus_mem[0].wdt),
    .q        (bus_mem[0].rdt)
  );

  assign bus_mem[0].err = 1'b0;
  assign bus_mem[0].rdy = 1'b1;

end: gen_cyclone_v
else if (CHIP == "ECP5") begin: gen_ecp5

  // file:///usr/local/diamond/3.12/docs/webhelp/eng/index.htm#page/Reference%20Guides/IPexpress%20Modules/pmi_ram_dp.htm#
  // TODO: use a single port or a true dual port memory
  pmi_ram_dp_be #(
    .pmi_wr_addr_depth     (8 * 2**RAW),
    .pmi_wr_addr_width     (RAW-$clog2(4)),
    .pmi_wr_data_width     (32),
    .pmi_rd_addr_depth     (8 * 2**RAW),
    .pmi_rd_addr_width     (RAW-$clog2(4)),
    .pmi_rd_data_width     (32),
    .pmi_regmode           ("reg"),
    .pmi_gsr               ("disable"),
    .pmi_resetmode         ("sync"),
    .pmi_optimization      ("speed"),
    .pmi_init_file         ("none"),
    .pmi_init_file_format  ("binary"),
    .pmi_byte_size         (8),
    .pmi_family            ("ECP5")
  ) mem (
    .WrClock    (bus_mem[0].clk),
    .WrClockEn  (bus_mem[0].vld),
    .WE         (bus_mem[0].wen),
    .WrAddress  (bus_mem[0].adr[RAW-1:$clog2(4)]),
    .ByteEn     (bus_mem[0].ben),
    .Data       (bus_mem[0].wdt),
    .RdClock    (bus_mem[0].clk),
    .RdClockEn  (bus_mem[0].vld),
    .Reset      (bus_mem[0].rst),
    .RdAddress  (bus_mem[0].adr[RAW-1:$clog2(4)]),
    .Q          (bus_mem[0].rdt)
  );
 
  assign bus_mem[0].err = 1'b0;
  assign bus_mem[0].rdy = 1'b1;

end: gen_ecp5
else begin: gen_default

  // data memory
  r5p_soc_memory #(
  //.FN   (),
    .AW   (RAW-1),
    .DW   (DW)
  ) mem (
    .bus  (bus_mem[0])
  );

end: gen_default
endgenerate

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

generate
if (ENA_GPIO) begin: gen_gpio

  // GPIO controller
  tcb_gpio #(
    .GW          (GW),
    .CFG_RSP_MIN (1'b1),
    .CHIP        (CHIP)
  ) gpio (
    // GPIO signals
    .gpio_o  (gpio_o),
    .gpio_e  (gpio_e),
    .gpio_i  (gpio_i),
    // bus interface
    .bus     (bus_mem[1])
  );

end: gen_gpio
else begin: gen_gpio_err

  // error response
  tcb_err gpio_err (.bus (bus_mem[1]));

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
  localparam int unsigned BCW = $clog2(BDR);  // a 9-bit counter is required

  // UART controller
  tcb_uart #(
    // UART parameters
    .CW       (BCW),
    // configuration register parameters (write enable, reset value)
    .CFG_TX_BDR_WEN (1'b0),  .CFG_TX_BDR_RST (BCW'(BDR)),
    .CFG_TX_IRQ_WEN (1'b0),  .CFG_TX_IRQ_RST ('x),
    .CFG_RX_BDR_WEN (1'b0),  .CFG_RX_BDR_RST (BCW'(BDR)),
    .CFG_RX_SMP_WEN (1'b0),  .CFG_RX_SMP_RST (BCW'(BDR/2)),
    .CFG_RX_IRQ_WEN (1'b0),  .CFG_RX_IRQ_RST ('x),
    // TCB parameters
    .CFG_RSP_MIN (1'b1)
  ) uart (
    // UART signals
    .uart_txd (uart_txd),
    .uart_rxd (uart_rxd),
    // system bus interface
    .bus      (bus_mem[2])
  );

end: gen_uart
else begin: gen_uart_err

  // error response
  tcb_err uart_err (.bus (bus_mem[2]));

  // GPIO signals
  assign uart_txd = 1'b1;
  //     uart_rxd

end: gen_uart_err
endgenerate

endmodule: r5p_mouse_soc_top
