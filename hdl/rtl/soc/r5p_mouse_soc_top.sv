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
  import riscv_isa_pkg::*;
  import tcb_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  localparam int unsigned BLEN = XLEN/8,
  localparam int unsigned BLOG = $clog2(BLEN),
  // SoC peripherals
  parameter  bit          ENA_GPIO = 1'b1,
  parameter  bit          ENA_UART = 1'b0,
  // GPIO
  parameter  int unsigned GW = 32,
  // TCB bus
  parameter  bit [XLEN-1:0] IFU_RST = 32'h8000_0000,
  parameter  bit [XLEN-1:0] IFU_MSK = 32'h8000_3fff,
  // TCB memory (size in bytes, file name)
  parameter  int unsigned   MEM_ADR = 14,
  parameter  int unsigned   MEM_SIZ = (XLEN/8)*(2**IFM_ADR),
  parameter  string         MEM_FNM = "mem_if.vmem",
  // implementation device (ASIC/FPGA vendor/device)
  parameter  string         CHIP = ""
)(
  // system signals
  input  logic          clk,  // clock
  input  logic          rst,  // reset (active high)
  // GPIO
  output logic [GW-1:0] gpio_o,  // output
  output logic [GW-1:0] gpio_e,  // enable
  input  logic [GW-1:0] gpio_i,  // input
  // UART
  output logic          uart_txd,
  input  logic          uart_rxd
);

////////////////////////////////////////////////////////////////////////////////
// local parameters and parameter validation
////////////////////////////////////////////////////////////////////////////////

// TODO: check if instruction address bus width and instruction memory size fit
// TODO: check if data address bus width and data memory size fit

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

  localparam tcb_par_phy_t TCB_PHY_RISC_V = '{
    // protocol
    DLY: 1,
    // signal widths
    UNT: 8,
    ADR: XLEN,
    DAT: XLEN,
    ALN: $clog2(XLEN/8),   // $clog2(DAT/UNT)
    // data packing parameters
    MOD: TCB_RISC_V,
    ORD: TCB_DESCENDING,
    // channel configuration
    CHN: TCB_COMMON_HALF_DUPLEX
  };

  localparam tcb_par_phy_t TCB_PHY_MEMORY = '{
    // protocol
    DLY: 1,
    // signal widths
    UNT: 8,
    ADR: XLEN,
    DAT: XLEN,
    ALN: $clog2(XLEN/8),   // $clog2(DAT/UNT)
    // data packing parameters
    MOD: TCB_MEMORY,
    ORD: TCB_DESCENDING,
    // channel configuration
    CHN: TCB_COMMON_HALF_DUPLEX
  };

  // system busses
  tcb_if #(TCB_PHY_RISC_V) tcb_cpu (.clk (clk), .rst (rst));
  tcb_if #(TCB_PHY_RISC_V) tcb_dmx [2-1:0] (.clk (clk), .rst (rst));  // demultiplexer
  tcb_if #(TCB_PHY_MEMORY) tcb_mem         (.clk (clk), .rst (rst));  // memory bus DLY=1
  tcb_if #(TCB_PHY_RISC_V) tcb_pb0         (.clk (clk), .rst (rst));  // peripherals bus DLY=0
  tcb_if #(TCB_PHY_RISC_V) tcb_per [2-1:0] (.clk (clk), .rst (rst));  // peripherals

////////////////////////////////////////////////////////////////////////////////
// R5P Mouse core instance
////////////////////////////////////////////////////////////////////////////////

  r5p_mouse #(
    .IFU_RST (IFU_RST),
    .IFU_MSK (IFU_MSK),
    .GPR_ADR (GPR_ADR),
    // implementation device (ASIC/FPGA vendor/device)
    .CHIP    (CHIP)
  ) core (
    // system signals
    .clk     (clk),
    .rst     (rst),
    // TCB system bus (shared by instruction/load/store)
    .tcb_vld ( tcb_cpu.vld ),
    .tcb_wen ( tcb_cpu.req.wen ),
    .tcb_adr ( tcb_cpu.req.adr ),
    .tcb_fn3 ({tcb_cpu.req.uns,
               tcb_cpu.req.siz}),
    .tcb_wdt ( tcb_cpu.req.wdt ),
    .tcb_rdt ( tcb_cpu.rsp.rdt ),
    .tcb_err ( tcb_cpu.rsp.sts.err ),
    .tcb_rdy ( tcb_cpu.rdy )
  );

  // signals not provided by the CPU
  assign tcb_cpu.req.ndn = TCB_LITTLE;

////////////////////////////////////////////////////////////////////////////////
// instruction fetch/load/store TCB interconnect
////////////////////////////////////////////////////////////////////////////////

  logic [2-1:0] tcb_cpu_sel;

  // decoding memory/peripherals
  tcb_lib_decoder #(
    .PHY (TCB_PHY_RISC_V),
    .SPN (2),
    .DAM ({{17'b0, 1'b1, 14'bxx_xxxx_xxxx_xxxx},   // 0x20_0000 ~ 0x2f_ffff - peripherals
           {17'b0, 1'b0, 14'bxx_xxxx_xxxx_xxxx}})  // 0x00_0000 ~ 0x1f_ffff - data memory
  ) tcb_lsu_dec (
    .tcb  (tcb_cpu    ),
    .sel  (tcb_cpu_sel)
  );

  // demultiplexing memory/peripherals
  tcb_lib_demultiplexer #(
    .MPN (2)
  ) tcb_lsu_demux (
    // control
    .sel  (tcb_cpu_sel),
    // TCB interfaces
    .sub  (tcb_cpu),
    .man  (tcb_dmx)
  );

  // convert from RISC-V to MEMORY mode
  tcb_lib_riscv2memory tcb_mem_converter (
    .sub  (tcb_dmx[0]),
    .man  (tcb_mem),
    // control/status
    .mal  ()
  );

  // register request path to convert from DLY=1 CPU to DLY=0 peripherals
  tcb_lib_register_request tcb_lsu_register (
    .sub  (tcb_dmx[1]),
    .man  (tcb_pb0)
  );

  logic [2-1:0] tcb_pb0_sel;

  // decoding peripherals (GPIO/UART)
  tcb_lib_decoder #(
    .PHY (TCB_PHY_LSU),
    .SPN (2),
    .DAM ({{17'bx, 15'bxx_xxxx_x1xx_xxxx},   // 0x20_0000 ~ 0x2f_ffff - 0x40 ~ 0x7f - UART controller
           {17'bx, 15'bxx_xxxx_x0xx_xxxx}})  // 0x20_0000 ~ 0x2f_ffff - 0x00 ~ 0x3f - GPIO controller
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
      .ADDR_WIDTH_A        ($clog2(MEM_SIZ/BLEN)),  // DECIMAL
      .AUTO_SLEEP_TIME     (0),                     // DECIMAL
      .BYTE_WRITE_WIDTH_A  (8),                     // DECIMAL
      .CASCADE_HEIGHT      (0),                     // DECIMAL
      .ECC_MODE            ("no_ecc"),              // String
      .MEMORY_INIT_FILE    ("mem.mem"),             // String
      .MEMORY_INIT_PARAM   (""),                    // String
      .MEMORY_OPTIMIZATION ("true"),                // String
      .MEMORY_PRIMITIVE    ("auto"),                // String
      .MEMORY_SIZE         (8 * MEM_SIZ),           // DECIMAL
      .MESSAGE_CONTROL     (0),                     // DECIMAL
      .READ_DATA_WIDTH_A   (XLEN),                  // DECIMAL
      .READ_LATENCY_A      (1),                     // DECIMAL
      .READ_RESET_VALUE_A  ("0"),                   // String
      .RST_MODE_A          ("SYNC"),                // String
      .SIM_ASSERT_CHK      (0),                     // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_MEM_INIT        (1),                     // DECIMAL
      .USE_MEM_INIT_MMI    (0),                     // DECIMAL
      .WAKEUP_TIME         ("disable_sleep"),       // String
      .WRITE_DATA_WIDTH_A  (XLEN),                  // DECIMAL
      .WRITE_MODE_A        ("read_first"),          // String
      .WRITE_PROTECT       (1)                      // DECIMAL
    ) mem (
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
      .wea    (tcb_mem.req.ben & {4{tcb_mem.req.wen}}),
      .addra  (tcb_mem.req.adr[$clog2(MEM_SIZ)-1:BLOG]),
      .dina   (tcb_mem.req.wdt),
      .douta  (tcb_mem.rsp.rdt)
    );

    assign tcb_mem.rsp.sts.err = 1'b0;
    assign tcb_mem.rdy = 1'b1;

  end: gen_artix_xpm
  else if (CHIP == "ARTIX_GEN") begin: gen_artix_gen

    blk_mem_gen_0 mem (
      .clka   (tcb_mem.clk),
      .ena    (tcb_mem.vld),
      .wea    (tcb_mem.req.ben & {4{tcb_mem[0].wen}}),
      .addra  (tcb_mem.req.adr[$clog2(IFM_SIZ)-1:BLOG]),
      .dina   (tcb_mem.req.wdt),
      .douta  (tcb_mem.rsp.rdt)
    );

    assign tcb_mem.rsp.sts.err = 1'b0;
    assign tcb_mem.rdy = 1'b1;

  end: gen_artix_gen
  else if (CHIP == "CYCLONE_V") begin: gen_cyclone_v

    ram32x4096 mem (
      .clock    (tcb_mem.clk),
      // read/write access
      .wren     (tcb_mem.vld &  tcb_mem.req.wen),
      .rden     (tcb_mem.vld & ~tcb_mem.req.wen),
      .address  (tcb_mem.req.adr[$clog2(MEM_SIZ)-1:BLOG]),
      .byteena  (tcb_mem.req.ben),
      .data     (tcb_mem.req.wdt),
      .q        (tcb_mem.rsp.rdt)
    );

    assign tcb_mem.rsp.sts.err = 1'b0;
    assign tcb_mem.rdy = 1'b1;

  end: gen_cyclone_v
  else if (CHIP == "ECP5") begin: gen_ecp5

    // file:///usr/local/diamond/3.12/docs/webhelp/eng/index.htm#page/Reference%20Guides/IPexpress%20Modules/pmi_ram_dp.htm#
    // TODO: use a single port or a true dual port memory
    pmi_ram_dp_be #(
      .pmi_wr_addr_depth     (8 *    MEM_SIZ      ),
      .pmi_wr_addr_width     ($clog2(MEM_SIZ/BLEN)),
      .pmi_wr_data_width     (               XLEN ),
      .pmi_rd_addr_depth     (8 *    MEM_SIZ      ),
      .pmi_rd_addr_width     ($clog2(MEM_SIZ/BLEN)),
      .pmi_rd_data_width     (               XLEN ),
      .pmi_regmode           ("reg"),
      .pmi_gsr               ("disable"),
      .pmi_resetmode         ("sync"),
      .pmi_optimization      ("speed"),
      .pmi_init_file         ("none"),
      .pmi_init_file_format  ("binary"),
      .pmi_byte_size         (8),
      .pmi_family            ("ECP5")
    ) mem (
      .WrClock    (tcb_mem.clk),
      .WrClockEn  (tcb_mem.vld),
      .WE         (tcb_mem.req.wen),
      .WrAddress  (tcb_mem.req.adr[$clog2(LSM_SIZ)-1:BLOG]),
      .ByteEn     (tcb_mem.req.ben),
      .Data       (tcb_mem.req.wdt),
      .RdClock    (tcb_mem.clk),
      .RdClockEn  (tcb_mem.vld),
      .Reset      (tcb_mem.rst),
      .RdAddress  (tcb_mem.req.adr[$clog2(LSM_SIZ)-1:BLOG]),
      .Q          (tcb_mem.rsp.rdt)
    );
 
    assign tcb_mem.rsp.sts.err = 1'b0;
    assign tcb_mem.rdy = 1'b1;

  end: gen_ecp5
  else begin: gen_default

    // shared memory
    r5p_soc_memory #(
    //.FNM  (),
      .SIZ  (MEM_SIZ)
    ) mem (
      .tcb  (tcb_mem)
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
      .tcb     (tcb_mem[1])
    );

  end: gen_gpio
  else begin: gen_gpio_err

    // error response
    tcb_lib_error gpio_err (.sub (tcb_mem[1]));

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
      .tcb      (tcb_mem[2])
    );

  end: gen_uart
  else begin: gen_uart_err

    // error response
    tcb_lib_error uart_err (.sub (tcb_mem[2]));

    // GPIO signals
    assign uart_txd = 1'b1;
    //     uart_rxd

  end: gen_uart_err
  endgenerate

endmodule: r5p_mouse_soc_top

