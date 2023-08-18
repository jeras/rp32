////////////////////////////////////////////////////////////////////////////////
// R5P: Degu SoC
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
  import tcb_pkg::*;
#(
  /////////////////////////////////////////////////////////////////////////////
  // SoC peripherals
  /////////////////////////////////////////////////////////////////////////////
  bit          ENA_GPIO = 1'b1,
  bit          ENA_UART = 1'b0,
  // GPIO
  int unsigned GW = 32,
///////////////////////////////////////////////////////////////////////////////
// RISC-V ISA
///////////////////////////////////////////////////////////////////////////////
  int unsigned XLEN = 32,   // is used to quickly switch between 32 and 64 for testing
`ifndef SYNOPSYS_VERILOG_COMPILER
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
  isa_ext_t    XTEN = RV_M | RV_C | RV_Zicsr,
  // privilige modes
  isa_priv_t   MODES = MODES_M,
  // ISA
`ifdef ENABLE_CSR
  isa_t        ISA = '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES}
`else
  isa_t        ISA = '{spec: RV32IC, priv: MODES_NONE},
`endif
`endif
  /////////////////////////////////////////////////////////////////////////////
  // interconnect/memories
  /////////////////////////////////////////////////////////////////////////////
  // instruction bus
  int unsigned IAW = 14,     // instruction address width (byte address)
  int unsigned IDW = 32,     // instruction data    width
  // data bus
  int unsigned DAW = 15,     // data address width (byte address)
  int unsigned DDW = XLEN,   // data data    width
  int unsigned DBW = DDW/8,  // data byte en width
  // instruction memory size (in bytes) and initialization file name
  int unsigned IMS = (IDW/8)*(2**IAW),
  string       IFN = "mem_if.vmem",
  // data memory size (in bytes)
  int unsigned DMS = (DDW/8)*(2**DAW),
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

`ifdef SYNOPSYS_VERILOG_COMPILER
parameter isa_t ISA = '{spec: RV32I, priv: MODES_NONE};
`endif

///////////////////////////////////////////////////////////////////////////////
// local parameters and checks
////////////////////////////////////////////////////////////////////////////////

// in this SoC the data address space is split in half between memory and peripherals
localparam int unsigned RAW = DAW-1;

// TODO: check if instruction address bus width and instruction memory size fit
// TODO: check if data address bus width and data memory size fit

///////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

localparam tcb_par_phy_t PHY_IFU = '{
  // protocol
  DLY: 1,
  // signal bus widths
  SLW: TCB_PAR_PHY_DEF.SLW,
  ABW: IAW,
  DBW: IDW,
  ALW: $clog2(IDW/TCB_PAR_PHY_DEF.SLW),
  // size/mode/order parameters
  SIZ: TCB_PAR_PHY_DEF.SIZ,
  MOD: TCB_PAR_PHY_DEF.MOD,
  ORD: TCB_PAR_PHY_DEF.ORD,
  // channel configuration
  CHN: TCB_PAR_PHY_DEF.CHN
};

localparam tcb_par_phy_t PHY_LSU = '{
  // protocol
  DLY: 1,
  // signal bus widths
  SLW: TCB_PAR_PHY_DEF.SLW,
  ABW: DAW,
  DBW: DDW,
  ALW: $clog2(DDW/TCB_PAR_PHY_DEF.SLW),
  // size/mode/order parameters
  SIZ: TCB_PAR_PHY_DEF.SIZ,
  MOD: TCB_PAR_PHY_DEF.MOD,
  ORD: TCB_PAR_PHY_DEF.ORD,
  // channel configuration
  CHN: TCB_PAR_PHY_DEF.CHN
};

localparam tcb_par_phy_t PHY_MEM = '{
  // protocol
  DLY: 1,
  // signal bus widths
  SLW: TCB_PAR_PHY_DEF.SLW,
  ABW: DAW,
  DBW: DDW,
  ALW: $clog2(DDW/TCB_PAR_PHY_DEF.SLW),
  // size/mode/order parameters
  SIZ: TCB_PAR_PHY_DEF.SIZ,
  MOD: TCB_PAR_PHY_DEF.MOD,
  ORD: TCB_PAR_PHY_DEF.ORD,
  // channel configuration
  CHN: TCB_PAR_PHY_DEF.CHN
};

localparam tcb_par_phy_t PHY_PER = '{
  // protocol
  DLY: 0,
  // signal bus widths
  SLW: TCB_PAR_PHY_DEF.SLW,
  ABW: DAW,
  DBW: DDW,
  ALW: $clog2(DDW/TCB_PAR_PHY_DEF.SLW),
  // size/mode/order parameters
  SIZ: TCB_PAR_PHY_DEF.SIZ,
  MOD: TCB_PAR_PHY_DEF.MOD,
  ORD: TCB_PAR_PHY_DEF.ORD,
  // channel configuration
  CHN: TCB_PAR_PHY_DEF.CHN
};

// system busses
tcb_if #(PHY_IFU) tcb_ifu         (.clk (clk), .rst (rst));  // instruction fetch unit
tcb_if #(PHY_LSU) tcb_lsu         (.clk (clk), .rst (rst));  // load/store unit
tcb_if #(PHY_LSU) tcb_lsd [2-1:0] (.clk (clk), .rst (rst));  // load/store demultiplexer
tcb_if #(PHY_MEM) tcb_mem         (.clk (clk), .rst (rst));  // memory bus DLY=1
tcb_if #(PHY_PER) tcb_pb0         (.clk (clk), .rst (rst));  // peripherals bus DLY=0
tcb_if #(PHY_PER) tcb_per [2-1:0] (.clk (clk), .rst (rst));  // peripherals

////////////////////////////////////////////////////////////////////////////////
// R5P Degu core instance
////////////////////////////////////////////////////////////////////////////////

r5p_degu #(
  // RISC-V ISA
  .XLEN (XLEN),
  .ISA  (ISA),
  // implementation device (ASIC/FPGA vendor/device)
  .CHIP (CHIP)
) core (
  // system signals
  .clk  (clk),
  .rst  (rst),
  // system bus
  .ifb  (tcb_ifu),
  .lsb  (tcb_lsu)
);

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

logic [2-1:0] tcb_lsu_sel;

// decoding memory/peripherals
tcb_lib_decoder #(
  .PHY (PHY_LSU),
  .SPN (2),
  .DAM ({{1'b1, 14'bxx_xxxx_xxxx_xxxx},   // 0x20_0000 ~ 0x2f_ffff - peripherals
         {1'b0, 14'bxx_xxxx_xxxx_xxxx}})  // 0x00_0000 ~ 0x1f_ffff - data memory
) tcb_lsu_dec (
  .tcb  (tcb_lsu    ),
  .sel  (tcb_lsu_sel)
);

// demultiplexing memory/peripherals
tcb_lib_demultiplexer #(
  .MPN (2)
) tcb_lsu_demux (
  // control
  .sel  (tcb_lsu_sel),
  // TCB interfaces
  .sub  (tcb_lsu),
  .man  (tcb_lsd)
);

// convert from reference to memory more
//tcb_lib_converter tcb_lsu_converter (
tcb_lib_passthrough tcb_lsu_converter (
  .sub  (tcb_lsd[0]),
  .man  (tcb_mem)
);

// register request path to convert from DLY=1 CPU to DLY=0 peripherals
tcb_lib_register_request tcb_lsu_register (
  .sub  (tcb_lsd[1]),
  .man  (tcb_pb0)
);

logic [2-1:0] tcb_pb0_sel;

// decoding peripherals (GPIO/UART)
tcb_lib_decoder #(
  .PHY (PHY_LSU),
  .SPN (2),
  .DAM ({{15'bxx_xxxx_x1xx_xxxx},   // 0x20_0000 ~ 0x2f_ffff - 0x40 ~ 0x7f - UART controller
         {15'bxx_xxxx_x0xx_xxxx}})  // 0x20_0000 ~ 0x2f_ffff - 0x00 ~ 0x3f - GPIO controller
) tcb_pb0_dec (
  .tcb  (tcb_pb0),
  .sel  (tcb_pb0_sel)
);

// demultiplexing peripherals (GPIO/UART)
tcb_lib_demultiplexer #(
  .MPN (2)
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

generate
if (CHIP == "ARTIX_XPM") begin: gen_artix_xpm

  // xpm_memory_spram: Single Port RAM
  // Xilinx Parameterized Macro, version 2021.2
  xpm_memory_spram #(
    .ADDR_WIDTH_A        (IAW-2),           // DECIMAL
    .AUTO_SLEEP_TIME     (0),               // DECIMAL
    .BYTE_WRITE_WIDTH_A  (8),               // DECIMAL
    .CASCADE_HEIGHT      (0),               // DECIMAL
    .ECC_MODE            ("no_ecc"),        // String
    .MEMORY_INIT_FILE    ("imem.mem"),      // String
    .MEMORY_INIT_PARAM   (""),              // String
    .MEMORY_OPTIMIZATION ("true"),          // String
    .MEMORY_PRIMITIVE    ("auto"),          // String
    .MEMORY_SIZE         (8 * 2**IAW),      // DECIMAL
    .MESSAGE_CONTROL     (0),               // DECIMAL
    .READ_DATA_WIDTH_A   (IDW),             // DECIMAL
    .READ_LATENCY_A      (1),               // DECIMAL
    .READ_RESET_VALUE_A  ("0"),             // String
    .RST_MODE_A          ("SYNC"),          // String
    .SIM_ASSERT_CHK      (0),               // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_MEM_INIT        (1),               // DECIMAL
    .USE_MEM_INIT_MMI    (0),               // DECIMAL
    .WAKEUP_TIME         ("disable_sleep"), // String
    .WRITE_DATA_WIDTH_A  (IDW),             // DECIMAL
    .WRITE_MODE_A        ("read_first"),    // String
    .WRITE_PROTECT       (1)                // DECIMAL
  ) imem (
    // unused control/status signals
    .injectdbiterra (1'b0),
    .injectsbiterra (1'b0),
    .dbiterra       (),
    .sbiterra       (),
    .sleep          (1'b0),
    .regcea         (1'b1),
    // system bus
    .clka   (   tcb_ifu.clk),
    .rsta   (   tcb_ifu.rst),
    .ena    (   tcb_ifu.vld),
    .wea    ({4{tcb_ifu.req.wen}}),
    .addra  (   tcb_ifu.req.adr[IAW-1:2]),
    .dina   (   tcb_ifu.req.wdt),
    .douta  (   tcb_ifu.rsp.rdt)
  );

  assign tcb_ifu.rsp.sts.err = 1'b0;
  assign tcb_ifu.rdy = 1'b1;

  // xpm_memory_spram: Single Port RAM
  // Xilinx Parameterized Macro, version 2021.2
  xpm_memory_spram #(
    .ADDR_WIDTH_A        (RAW-$clog2(DBW)),   // DECIMAL
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
    .READ_DATA_WIDTH_A   (DDW),               // DECIMAL
    .READ_LATENCY_A      (1),                 // DECIMAL
    .READ_RESET_VALUE_A  ("0"),               // String
    .RST_MODE_A          ("SYNC"),            // String
    .SIM_ASSERT_CHK      (0),                 // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_MEM_INIT        (1),                 // DECIMAL
    .USE_MEM_INIT_MMI    (0),                 // DECIMAL
    .WAKEUP_TIME         ("disable_sleep"),   // String
    .WRITE_DATA_WIDTH_A  (DDW),               // DECIMAL
    .WRITE_MODE_A        ("read_first"),      // String
    .WRITE_PROTECT       (1)                  // DECIMAL
  ) dmem (
    // unused control/status signals
    .injectdbiterra (1'b0),
    .injectsbiterra (1'b0),
    .dbiterra       (),
    .sbiterra       (),
    .sleep          (1'b0),
    .regcea         (1'b1),
    // system bus
    .clka   (tcb_mem.clk),
    .rsta   (tcb_mem.rst),
    .ena    (tcb_mem.vld),
    .wea    (tcb_mem.ben & {DBW{tcb_mem.wen}}),
    .addra  (tcb_mem.adr[RAW-1:$clog2(DBW)]),
    .dina   (tcb_mem.wdt),
    .douta  (tcb_mem.rdt)
  );

  assign tcb_mem.rsp.sts.err = 1'b0;
  assign tcb_mem.rdy = 1'b1;

end: gen_artix_xpm
else if (CHIP == "ARTIX_GEN") begin: gen_artix_gen

  blk_mem_gen_0 imem (
    .clka   (   tcb_ifu.clk),
    .ena    (   tcb_ifu.vld),
    .wea    ({4{tcb_ifu.req.wen}}),
    .addra  (   tcb_ifu.req.adr[IAW-1:2]),
    .dina   (   tcb_ifu.req.wdt),
    .douta  (   tcb_ifu.rsp.rdt)
  );

  assign tcb_ifu.rsp.sts.err = 1'b0;
  assign tcb_ifu.rdy = 1'b1;

  blk_mem_gen_0 dmem (
    .clka   (tcb_mem.clk),
    .ena    (tcb_mem.vld),
    .wea    (tcb_mem.req.ben &
        {DBW{tcb_mem.req.wen}}),
    .addra  (tcb_mem.req.adr[RAW-1:$clog2(DBW)]),
    .dina   (tcb_mem.req.wdt),
    .douta  (tcb_mem.rsp.rdt)
  );

  assign tcb_mem.rsp.sts.err = 1'b0;
  assign tcb_mem.rdy = 1'b1;

end: gen_artix_gen
else if (CHIP == "CYCLONE_V") begin: gen_cyclone_v

  rom32x4096 imem (
    // write access
    .clock      (tcb_ifu.clk),
    .wren       (1'b0),
    .wraddress  ('x),
    .data       ('x),
    // read access
    .rdaddress  (tcb_ifu.adr[IAW-1:2]),
    .rden       (tcb_ifu.vld),
    .q          (tcb_ifu.rdt)
  );

  assign tcb_ifu.rsp.sts.err = 1'b0;
  assign tcb_ifu.rdy = 1'b1;

  ram32x4096 dmem (
    .clock    (tcb_mem.clk),
    .wren     (tcb_mem.vld &  tcb_mem.wen),
    .rden     (tcb_mem.vld & ~tcb_mem.wen),
    .address  (tcb_mem.adr[RAW-1:$clog2(DBW)]),
    .byteena  (tcb_mem.ben),
    .data     (tcb_mem.wdt),
    .q        (tcb_mem.rdt)
  );

  assign tcb_mem.rsp.sts.err = 1'b0;
  assign tcb_mem.rdy = 1'b1;

end: gen_cyclone_v
else if (CHIP == "ECP5") begin: gen_ecp5

  // file:///usr/local/diamond/3.12/docs/webhelp/eng/index.htm#page/Reference%20Guides/IPexpress%20Modules/pmi_ram_dp.htm#
  pmi_ram_dp #(
    .pmi_wr_addr_depth     (8 * 2**RAW),
    .pmi_wr_addr_width     (RAW-$clog2(DBW)),
    .pmi_wr_data_width     (32),
    .pmi_rd_addr_depth     (8 * 2**RAW),
    .pmi_rd_addr_width     (RAW-$clog2(DBW)),
    .pmi_rd_data_width     (32),
    .pmi_regmode           ("reg"),
    .pmi_gsr               ("disable"),
    .pmi_resetmode         ("sync"),
    .pmi_optimization      ("speed"),
    .pmi_init_file         ("imem.mem"),
    .pmi_init_file_format  ("binary"),
    .pmi_family            ("ECP5")
  ) imem (
    // write access
    .WrClock    (tcb_ifu.clk),
    .WrClockEn  (1'b0),
    .WE         (1'b0),
    .WrAddress  ('x),
    .Data       ('x),
    // read access
    .RdClock    (tcb_ifu.clk),
    .RdClockEn  (1'b1),
    .Reset      (tcb_ifu.rst),
    .RdAddress  (tcb_ifu.adr[IAW-1:2]),
    .Q          (tcb_ifu.rdt)
  );

  assign tcb_ifu.rsp.sts.err = 1'b0;
  assign tcb_ifu.rdy = 1'b1;

  // TODO: use a single port or a true dual port memory
  pmi_ram_dp_be #(
    .pmi_wr_addr_depth     (8 * 2**RAW),
    .pmi_wr_addr_width     (RAW-$clog2(DBW)),
    .pmi_wr_data_width     (32),
    .pmi_rd_addr_depth     (8 * 2**RAW),
    .pmi_rd_addr_width     (RAW-$clog2(DBW)),
    .pmi_rd_data_width     (32),
    .pmi_regmode           ("reg"),
    .pmi_gsr               ("disable"),
    .pmi_resetmode         ("sync"),
    .pmi_optimization      ("speed"),
    .pmi_init_file         ("none"),
    .pmi_init_file_format  ("binary"),
    .pmi_byte_size         (8),
    .pmi_family            ("ECP5")
  ) dmem (
    .WrClock    (tcb_mem.clk),
    .WrClockEn  (tcb_mem.vld),
    .WE         (tcb_mem.wen),
    .WrAddress  (tcb_mem.adr[RAW-1:$clog2(DBW)]),
    .ByteEn     (tcb_mem.ben),
    .Data       (tcb_mem.wdt),
    .RdClock    (tcb_mem.clk),
    .RdClockEn  (tcb_mem.vld),
    .Reset      (tcb_mem.rst),
    .RdAddress  (tcb_mem.adr[RAW-1:$clog2(DBW)]),
    .Q          (tcb_mem.rdt)
  );
 
  assign tcb_mem.rsp.sts.err = 1'b0;
  assign tcb_mem.rdy = 1'b1;

end: gen_ecp5
else begin: gen_default

  // instruction memory
  r5p_soc_mem #(
    .FN   (IFN),
    .AW   (IAW),
    .DW   (IDW)
  ) imem (
    .bus  (tcb_ifu)
  );

  // data memory
  r5p_soc_mem #(
  //.FN   (),
    .AW   (RAW-1),
    .DW   (DDW)
  ) dmem (
    .bus  (tcb_mem)
  );

end: gen_default
endgenerate

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

generate
if (ENA_GPIO) begin: gen_gpio

  // GPIO controller
  tcb_cmn_gpio #(
    .GW          (GW),
    .CFG_RSP_MIN (1'b1),
    .CHIP        (CHIP)
  ) gpio (
    // GPIO signals
    .gpio_o  (gpio_o),
    .gpio_e  (gpio_e),
    .gpio_i  (gpio_i),
    // bus interface
    .tcb     (tcb_per[0])
  );

end: gen_gpio
else begin: gen_gpio_err

  // error response
  tcb_lib_error gpio_err (.sub (tcb_per[0]));

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
  tcb_cmn_uart #(
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
    .tcb      (tcb_per[1])
  );

end: gen_uart
else begin: gen_uart_err

  // error response
  tcb_lib_error uart_err (.sub (tcb_per[1]));

  // GPIO signals
  assign uart_txd = 1'b1;
  //     uart_rxd

end: gen_uart_err
endgenerate

endmodule: r5p_degu_soc_top
