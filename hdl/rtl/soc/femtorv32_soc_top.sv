////////////////////////////////////////////////////////////////////////////////
// FEMTORV32: SoC
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

module femtorv32_soc_top #(
  // GPIO
  int unsigned GW = 32,
  // instruction bus
  int unsigned AW = 14,    // instruction address width (byte address)
  int unsigned DW = 32,    // instruction data    width
  // instruction memory size (in bytes) and initialization file name
  int unsigned IMS = (DW/8)*(2**AW),
  string       IFN = "mem_if.vmem",
  // implementation device (ASIC/FPGA vendor/device)
  string       CHIP = ""
)(
  // system signals
  input  logic          clk,  // clock
  input  logic          rst,  // reset (active low)
  // GPIO
  output logic [GW-1:0] gpio_o,
  output logic [GW-1:0] gpio_e,
  input  logic [GW-1:0] gpio_i
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
tcb_if #(.AW (AW), .DW (DW)) bus_ls        (.clk (clk), .rst (rst));
tcb_if #(.AW (AW), .DW (DW)) bus_mem [1:0] (.clk (clk), .rst (rst));

////////////////////////////////////////////////////////////////////////////////
// FEMTORV32 core instance
////////////////////////////////////////////////////////////////////////////////

logic [31:0] mem_addr ;  // address bus
logic [31:0] mem_wdata;  // data to be written
logic  [3:0] mem_wmask;  // write mask for the 4 bytes of each word
logic [31:0] mem_rdata;  // input lines for both data and instr
logic        mem_rstrb;  // active to initiate memory read (used by IO)
logic        mem_rbusy;  // asserted if memory is busy reading value
logic        mem_wbusy;  // asserted if memory is busy writing value

FemtoRV32 #(
  .RESET_ADDR (32'h00000000),
  .ADDR_WIDTH (AW)
) cpu (
  .clk       ( clk),
  .reset     (~rst),       // set to 0 to reset the processor
  .mem_addr  (mem_addr ),  // address bus
  .mem_wdata (mem_wdata),  // data to be written
  .mem_wmask (mem_wmask),  // write mask for the 4 bytes of each word
  .mem_rdata (mem_rdata),  // input lines for both data and instr
  .mem_rstrb (mem_rstrb),  // active to initiate memory read (used by IO)
  .mem_rbusy (mem_rbusy),  // asserted if memory is busy reading value
  .mem_wbusy (mem_wbusy)   // asserted if memory is busy writing value
);

// data load/store
assign bus_ls.vld =      |mem_wmask | mem_rstrb;
assign bus_ls.wen =      |mem_wmask;
assign bus_ls.adr =  AW'(mem_addr);
assign bus_ls.ben =       mem_wmask | {4{mem_rstrb}};
assign bus_ls.wdt =       mem_wdata;

assign mem_rdata = bus_ls.rdt;
assign mem_rbusy = 1'b0;
assign mem_wbusy = 1'b0;

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

tcb_dec #(
  .AW  (AW),
  .DW  (DW),
  .PN  (2),                    // port number
  .AS  ({ {1'b1, 14'hxxxx} ,   // 0x00_0000 ~ 0x1f_ffff - data memory
          {1'b0, 14'hxxxx} })  // 0x20_0000 ~ 0x2f_ffff - controller
) ls_dec (
  .s  (bus_ls      ),
  .m  (bus_mem[1:0])
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

// GPIO controller
tcb_gpio #(
  .GW      (GW),
  .CFG_MIN (1'b1),
  .CHIP    (CHIP)
) gpio (
  // GPIO signals
  .gpio_o  (gpio_o),
  .gpio_e  (gpio_e),
  .gpio_i  (gpio_i),
  // bus interface
  .bus     (bus_mem[1])
);

////////////////////////////////////////////////////////////////////////////////
// UART
////////////////////////////////////////////////////////////////////////////////

// TODO

endmodule: femtorv32_soc_top
