////////////////////////////////////////////////////////////////////////////////
// R5P SoC
////////////////////////////////////////////////////////////////////////////////

module r5p_soc_top #(
  // RISC-V ISA
  int unsigned XLEN = 32,   // is used to quickly switch between 32 and 64 for testing
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
  isa_ext_t    XTEN = RV_M | RV_C | RV_Zicsr,
  // privilige modes
  isa_priv_t   MODES = MODES_M,
  // ISA
//isa_t        ISA = XLEN==32 ? '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES}
//                 : XLEN==64 ? '{spec: '{base: RV_64I , ext: XTEN}, priv: MODES}
//                            : '{spec: '{base: RV_128I, ext: XTEN}, priv: MODES},
  isa_t ISA = '{spec: RV32I, priv: MODES_NONE},
  // instruction bus
  int unsigned IAW = 22,    // instruction address width
  int unsigned IDW = 32,    // instruction data    width
  // data bus
  int unsigned DAW = 22,    // data address width
  int unsigned DDW = XLEN,  // data data    width
  int unsigned DBW = DDW/8  // data byte en width
)(
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
);

////////////////////////////////////////////////////////////////////////////////
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
  .ISA  (ISA),
  .XLEN (XLEN),
  // instruction bus
  .IDW  (IDW),
  .IAW  (IAW),
  // data bus
  .DAW  (DAW),
  .DDW  (DDW)
) DUT (
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
assign bus_if.wen = 'x;

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

r5p_bus_dec #(
  .AW  (DAW),
  .BN  (2),                      // bus number
  .AS  ({ {2'b1x, 20'hxxxxx} ,   // 0x00_0000 ~ 0x1f_ffff - data memory
          {2'b0x, 20'hxxxxx} })  // 0x20_0000 ~ 0x2f_ffff - controller
) ls_dec (
  .s  (bus_ls      ),
  .m  (bus_mem[1:0])
);

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

mem #(
  .ISA  (ISA),
//.FN   (),
  .SZ   (2**IAW),
  .DBG  ("BUS")
) mem (
  .bus_if  (bus_if),
  .bus_ls  (bus_mem[0])
);

// memory initialization file is provided at runtime
initial
begin
  string fn;
  if ($value$plusargs("FILE_MEM=%s", fn)) begin
    $display("Loading file into memory: %s", fn);
    void'(mem.read_bin(fn));
  end else begin
    $display("ERROR: memory load file argument not found.");
    $finish;
  end
end

/*
r5p_bus_mon bus_mon_if (
  .s  (bus_if)
);
*/

////////////////////////////////////////////////////////////////////////////////
// controller
////////////////////////////////////////////////////////////////////////////////

logic [DDW-1:0] rvmodel_data_begin;
logic [DDW-1:0] rvmodel_data_end;
logic           rvmodel_halt = '0;

always_ff @(posedge clk, posedge rst)
if (rst) begin
  rvmodel_data_begin <= 'x;
  rvmodel_data_end   <= 'x;
  rvmodel_halt       <= '0;
end else if (bus_mem[1].vld & bus_mem[1].rdy) begin
  if (bus_mem[1].wen) begin
    // write access
    case (bus_mem[1].adr[5-1:0])
      5'h00:  rvmodel_data_begin <= bus_mem[1].wdt;
      5'h08:  rvmodel_data_end   <= bus_mem[1].wdt;
      5'h10:  rvmodel_halt       <= bus_mem[1].wdt[0];
      default:  ;  // do nothing
    endcase
  end
end

// controller response is immediate
assign bus_mem[1].rdy = 1'b1;

// finish simulation
always @(posedge clk)
if (rvmodel_halt | timeout) begin
  string fn;
  if (rvmodel_halt)  $display("HALT");
  if (timeout     )  $display("TIMEOUT");
  if ($value$plusargs("FILE_SIG=%s", fn)) begin
    $display("Saving signature file: %s", fn);
  //void'(mem.write_hex("signature_debug.txt", 'h10000200, 'h1000021c));
    void'(mem.write_hex(fn, int'(rvmodel_data_begin), int'(rvmodel_data_end)));
  end else begin
    $display("ERROR: signature save file argument not found.");
    $finish;
  end
  $finish;
end

// at the end dump the test signature
// TODO: not working in Verilator, at least if the C code ends the simulation.
final begin
  $display("FINAL");
//void'(mem.write_hex(FILE_SIG, int'(rvmodel_data_begin), int'(rvmodel_data_end)));
  $display("TIME: cnt = %d", cnt);
end

endmodule: r5p_soc_top
