////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module r5p_tb #(
  // RISC-V ISA
  int unsigned XLEN = 32,
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
  isa_ext_t    XTEN = RV_M | RV_C,
  isa_t        ISA = XLEN==32 ? '{RV_32I , XTEN}
                   : XLEN==64 ? '{RV_64I , XTEN}
                              : '{RV_128I, XTEN},
  // instruction bus
  int unsigned IAW = 21,    // instruction address width
  int unsigned IDW = 32,    // instruction data    width
  // data bus
  int unsigned DAW = 16,    // data address width
  int unsigned DDW = XLEN,  // data data    width
  int unsigned DBW = DDW/8  // data byte en width
)(
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
);

import riscv_asm_pkg::*;

// clock period counter
int unsigned cnt;

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// instruction fetch bus
logic           if_req;
logic [IAW-1:0] if_adr;
logic [IDW-1:0] if_rdt;
logic           if_ack;
// load/store bus, LS memory bus, controller bus
logic           ls_req, ls_mem_req, ls_ctl_req;
logic           ls_wen, ls_mem_wen, ls_ctl_wen;
logic [DAW-0:0] ls_adr, ls_mem_adr, ls_ctl_adr;  // +1 bits for decoder
logic [DBW-1:0] ls_ben, ls_mem_ben, ls_ctl_ben;
logic [DDW-1:0] ls_wdt, ls_mem_wdt, ls_ctl_wdt;
logic [DDW-1:0] ls_rdt, ls_mem_rdt, ls_ctl_rdt;
logic           ls_ack, ls_mem_ack, ls_ctl_ack;

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
  .DAW  (DAW+1),
  .DDW  (DDW)
) DUT (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // instruction fetch
  .if_req  (if_req),
  .if_adr  (if_adr),
  .if_rdt  (if_rdt),
  .if_ack  (if_ack),
  // data load/store
  .ls_req  (ls_req),
  .ls_wen  (ls_wen),
  .ls_adr  (ls_adr),
  .ls_ben  (ls_ben),
  .ls_wdt  (ls_wdt),
  .ls_rdt  (ls_rdt),
  .ls_ack  (ls_ack)
);

////////////////////////////////////////////////////////////////////////////////
// program memory
////////////////////////////////////////////////////////////////////////////////

string if_str;
always if_str = disasm(ISA, if_rdt);

mem #(
  .ISA  (ISA),
  .FN   ("mem_if.bin"),
  .SZ   (2**IAW),
  .DW   (IDW),
  .DBG  ("INS"),
  .OPC  (1'b1)
) mem_if (
  // system signals
  .clk  (clk),
  // instruction fetch
  .req  (if_req),
  .wen  (1'b0),
  .ben  ('1),
  .adr  (if_adr),
  .wdt  ('x),
  .rdt  (if_rdt),
  .ack  (if_ack)
);

/*
r5p_bus_mon #(
  .DW   (IDW),
  .AW   (IAW),
) bus_mon_if (
  // system signals
  .clk  (clk),
  .rst  (rst),
  // instruction fetch
  .req  (if_req),
  .wen  (1'b0),
  .adr  (if_adr),
  .ben  ('1),
  .wdt  ('x),
  .rdt  (if_rdt),
  .ack  (if_ack)
);
*/

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

r5p_bus_dec #(
  .AW  (DAW+1),
  .DW  (DDW),
  .BN  (2),       // bus number
  .AS  ({ {1'b1, {DAW{1'bx}}} ,   // 0x0_0000 ~ 0x0_ffff - data memory
          {1'b0, {DAW{1'bx}}} })  // 0x1_0000 ~ 0x1_ffff - controller
) ls_dec (
  // system signals
  .clk  (clk),
  .rst  (rst),
  // data load/store
  // slave port and master ports
  .s_req  (ls_req),  .m_req  ('{ls_ctl_req, ls_mem_req}),
  .s_wen  (ls_wen),  .m_wen  ('{ls_ctl_wen, ls_mem_wen}),
  .s_ben  (ls_ben),  .m_ben  ('{ls_ctl_ben, ls_mem_ben}),
  .s_adr  (ls_adr),  .m_adr  ('{ls_ctl_adr, ls_mem_adr}),
  .s_wdt  (ls_wdt),  .m_wdt  ('{ls_ctl_wdt, ls_mem_wdt}),
  .s_rdt  (ls_rdt),  .m_rdt  ('{ls_ctl_rdt, ls_mem_rdt}),
  .s_ack  (ls_ack),  .m_ack  ('{ls_ctl_ack, ls_mem_ack})
);

////////////////////////////////////////////////////////////////////////////////
// data memory
////////////////////////////////////////////////////////////////////////////////

mem #(
  .ISA  (ISA),
  .FN   ("mem_ls.bin"),
  .SZ   (2**DAW),
  .DW   (DDW),
  .DBG  ("DAT"),
  .TXT  (1'b1)
) mem_ls (
  // system signals
  .clk  (clk),
  // data load/store
  .req  (ls_mem_req),
  .wen  (ls_mem_wen),
  .ben  (ls_mem_ben),
  .adr  (ls_mem_adr[DAW-1:0]),
  .wdt  (ls_mem_wdt),
  .rdt  (ls_mem_rdt),
  .ack  (ls_mem_ack)
);

/*
r5p_bus_mon #(
  .DW   (DDW),
  .AW   (DAW),
) bus_mon_ls (
  // system signals
  .clk  (clk),
  .rst  (rst),
  // data load/store
  .req  (ls_req),
  .wen  (ls_wen),
  .adr  (ls_adr),
  .ben  (ls_ben),
  .wdt  (ls_wdt),
  .rdt  (ls_rdt),
  .ack  (ls_ack)
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
end else if (ls_ctl_req & ls_ctl_ack) begin
  if (ls_ctl_wen) begin
    // write access
    case (ls_ctl_adr[5-1:0])
      5'h00:  rvmodel_data_begin <= ls_ctl_wdt;
      5'h08:  rvmodel_data_end   <= ls_ctl_wdt;
      5'h10:  rvmodel_halt       <= ls_ctl_wdt[0];
      default:  ;  // do nothing
    endcase
  end
end

// controller response is immediate
assign ls_ctl_ack = 1'b1;

// finish simulation
always @(posedge clk)
if (rvmodel_halt) begin
  void'(mem_ls.write_hex("signature.txt", int'(rvmodel_data_begin), int'(rvmodel_data_end)));
  $finish;
end

// at the end dump the test signature
// TODO: not working in Verilator, at least if the C code ends the simulation.
final begin
  void'(mem_ls.write_hex("signature.txt", int'(rvmodel_data_begin), int'(rvmodel_data_end)));
  $display("TIME: cnt = %d", cnt);
end

////////////////////////////////////////////////////////////////////////////////
// timeout
////////////////////////////////////////////////////////////////////////////////

// time counter
always_ff @(posedge clk, posedge rst)
if (rst) begin
  cnt <= 0;
end else begin
  cnt <= cnt+1;
end

// timeout
//always @(posedge clk)
//if (cnt > 5000)  $finish;

////////////////////////////////////////////////////////////////////////////////
// waveforms
////////////////////////////////////////////////////////////////////////////////

//initial begin
//  $dumpfile("rp32_tb.vcd");
//  $dumpvars(0, rp32_tb);
//end

endmodule: r5p_tb