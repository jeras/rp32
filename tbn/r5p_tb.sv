////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module r5p_tb #(
  int unsigned IAW = 16,    // instruction address width
  int unsigned IDW = 32,    // instruction data    width
  int unsigned DAW = 16,    // data address width
  int unsigned DDW = 32,    // data data    width
  int unsigned DSW = DDW/8  // data select  width
)(
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
);

import riscv_asm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// program bus
logic           if_req;
logic [IAW-1:0] if_adr;
logic [IDW-1:0] if_rdt;
logic           if_ack;
// data bus
logic           ls_req;
logic           ls_wen;
logic [DAW-1:0] ls_adr;
logic [DSW-1:0] ls_sel;
logic [DDW-1:0] ls_wdt;
logic [DDW-1:0] ls_rdt;
logic           ls_ack;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

r5p_core #(
  .IDW  (IDW),
  .IAW  (IAW),
  .DAW  (DAW),
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
  .ls_sel  (ls_sel),
  .ls_wdt  (ls_wdt),
  .ls_rdt  (ls_rdt),
  .ls_ack  (ls_ack)
);

////////////////////////////////////////////////////////////////////////////////
// program memory
////////////////////////////////////////////////////////////////////////////////

mem #(
  .FN   ("../src/main.bin"),
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
  .sel  ('1),
  .adr  (if_adr),
  .wdt  ('x),
  .rdt  (if_rdt),
  .ack  (if_ack)
);

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
  .sel  ('1),
  .wdt  ('x),
  .rdt  (if_rdt),
  .ack  (if_ack)
);

////////////////////////////////////////////////////////////////////////////////
// data memory
////////////////////////////////////////////////////////////////////////////////

mem #(
  .SZ   (2**DAW),
  .DW   (DDW),
  .DBG  ("DAT"),
  .TXT  (1'b1)
) mem_ls (
  // system signals
  .clk  (clk),
  // data load/store
  .req  (ls_req),
  .wen  (ls_wen),
  .sel  (ls_sel),
  .adr  (ls_adr),
  .wdt  (ls_wdt),
  .rdt  (ls_rdt),
  .ack  (ls_ack)
);

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
  .sel  (ls_sel),
  .wdt  (ls_wdt),
  .rdt  (ls_rdt),
  .ack  (ls_ack)
);

////////////////////////////////////////////////////////////////////////////////
// waveforms
////////////////////////////////////////////////////////////////////////////////

//initial begin
//  $dumpfile("rp32_tb.vcd");
//  $dumpvars(0, rp32_tb);
//end

endmodule: r5p_tb