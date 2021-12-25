////////////////////////////////////////////////////////////////////////////////
// R5P SoC
////////////////////////////////////////////////////////////////////////////////

import riscv_isa_pkg::*;

module r5p_soc_top #(
  // GPIO
  int unsigned GW = 32,
  // RISC-V ISA
  int unsigned XLEN = 32,   // is used to quickly switch between 32 and 64 for testing
  `ifndef SYNOPSYS_VERILOG_COMPILER
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
  isa_ext_t    XTEN = RV_M | RV_C | RV_Zicsr,
  // privilige modes
  isa_priv_t   MODES = MODES_M,
  // ISA
//isa_t        ISA = XLEN==32 ? '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES}
//                 : XLEN==64 ? '{spec: '{base: RV_64I , ext: XTEN}, priv: MODES}
//                            : '{spec: '{base: RV_128I, ext: XTEN}, priv: MODES},
  isa_t ISA = '{spec: RV32I, priv: MODES_NONE},
  `endif
  // instruction bus
  int unsigned IAW = 14,    // instruction address width
  int unsigned IDW = 32,    // instruction data    width
  // data bus
  int unsigned DAW = 15,    // data address width
  int unsigned DDW = XLEN,  // data data    width
  int unsigned DBW = DDW/8, // data byte en width
  // memory initialization file names
  string       IFN = "mem_if.vmem"     // instruction memory file name
)(
  // system signals
  input  logic          clk,  // clock
  input  logic          rst,  // reset
  // GPIO
  inout  wire  [GW-1:0] gpio
);

`ifdef SYNOPSYS_VERILOG_COMPILER
// ISA
localparam  isa_t ISA = '{spec: RV32I, priv: MODES_NONE};
`endif

///////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

r5p_bus_if #(.AW (IAW), .DW (IDW)) bus_if        (.clk (clk), .rst (rst));
r5p_bus_if #(.AW (DAW), .DW (DDW)) bus_ls        (.clk (clk), .rst (rst));
r5p_bus_if #(.AW (DAW), .DW (DDW)) bus_mem [1:0] (.clk (clk), .rst (rst));

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

r5p_core #(
  // RISC-V ISA
  .XLEN (XLEN),
  .ISA  (ISA),
  // instruction bus
  .IAW  (IAW),
  .IDW  (IDW),
  // data bus
  .DAW  (DAW),
  .DDW  (DDW)
) core (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // instruction fetch
  .if_req  (bus_if.vld),
  .if_adr  (bus_if.adr),
  .if_rdt  (bus_if.rdt),
  .if_ack  (bus_if.rdy),
  // data load/store
  .ls_req  (bus_ls.vld),
  .ls_wen  (bus_ls.wen),
  .ls_adr  (bus_ls.adr),
  .ls_ben  (bus_ls.ben),
  .ls_wdt  (bus_ls.wdt),
  .ls_rdt  (bus_ls.rdt),
  .ls_ack  (bus_ls.rdy)
);

assign bus_if.wen = 1'b0;
assign bus_if.ben = '1;
assign bus_if.wdt = 'x;

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

r5p_bus_dec #(
  .AW  (DAW),
  .DW  (DDW),
  .BN  (2),                    // bus number
  .AS  ({ {1'b1, 14'hxxxx} ,   // 0x00_0000 ~ 0x1f_ffff - data memory
          {1'b0, 14'hxxxx} })  // 0x20_0000 ~ 0x2f_ffff - controller
) ls_dec (
  .s  (bus_ls      ),
  .m  (bus_mem[1:0])
);

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

r5p_soc_mem #(
  .FN   (IFN),
  .AW   (IAW),
  .DW   (IDW)
) imem (
  .bus  (bus_if)
);

r5p_soc_mem #(
//.FN   (),
  .AW   (DAW-1),
  .DW   (DDW)
) dmem (
  .bus  (bus_mem[0])
);

////////////////////////////////////////////////////////////////////////////////
// controller
////////////////////////////////////////////////////////////////////////////////

logic [GW-1:0] gpio_o;
logic [GW-1:0] gpio_e;
logic [GW-1:0] gpio_i;

always_ff @(posedge clk, posedge rst)
if (rst) begin
  gpio_o <= '0;
  gpio_e <= '0;
end else if (bus_mem[1].vld & bus_mem[1].rdy) begin
  if (bus_mem[1].wen) begin
    // write access
    case (bus_mem[1].adr[5-1:0])
      5'h00:   gpio_o <= bus_mem[1].wdt[GW-1:0];
      5'h08:   gpio_e <= bus_mem[1].wdt[GW-1:0];
      default: ;  // do nothing
    endcase
  end else begin
    // read access
    case (bus_mem[1].adr[5-1:0])
      5'h00:   bus_mem[1].rdt <= gpio_o;
      5'h08:   bus_mem[1].rdt <= gpio_e;
      5'h10:   bus_mem[1].rdt <= gpio_i;
      default: bus_mem[1].rdt <= 'x;
    endcase
  end
end

// controller response is immediate
assign bus_mem[1].rdy = 1'b1;

// GPIO
generate for (genvar i=0; i<GW; i++)
begin
  assign gpio[i] = gpio_e[i] ? gpio_o[i] : 1'bz;
end
endgenerate

assign gpio_i = gpio;

endmodule: r5p_soc_top
