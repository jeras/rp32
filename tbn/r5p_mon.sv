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
  .IDW (IDW),
  .IAW (IAW),
  .DAW (DAW),
  .DDW (DDW)
) DUT (
  // system signals
  .clk      (clk),
  .rst      (rst),
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
  .FN ("../src/main.bin"),
  .SZ (2**IAW),
  .DW (IDW),
  .DBG ("INS"),
  .OPC (1'b1)
) mem_if (
  .clk (clk),
  .req (if_req),
  .wen (1'b0),
  .sel ('1),
  .adr (if_adr),
  .wdt ('x),
  .rdt (if_rdt),
  .ack (if_ack)
);

////////////////////////////////////////////////////////////////////////////////
// data memory
////////////////////////////////////////////////////////////////////////////////

mem #(
  .SZ (2**DAW),
  .DW (DDW),
  .DBG ("DAT"),
  .TXT (1'b1)
) mem_ls (
  .clk (clk),
  .req (ls_req),
  .wen (ls_wen),
  .sel (ls_sel),
  .adr (ls_adr),
  .wdt (ls_wdt),
  .rdt (ls_rdt),
  .ack (ls_ack)
);

////////////////////////////////////////////////////////////////////////////////
// LS debug
////////////////////////////////////////////////////////////////////////////////

// data bus
logic           ls_req_r;
logic           ls_wen_r;
logic [DAW-1:0] ls_adr_r;
logic [DSW-1:0] ls_sel_r;
logic [DDW-1:0] ls_wdt_r;
logic [DDW-1:0] ls_rdt_r;
logic           ls_ack_r;

// delayed signals
always_ff @(posedge clk, posedge rst)
if (rst) begin
  ls_req_r <= '0;
  ls_wen_r <= 'x;
  ls_sel_r <= 'x;
  ls_adr_r <= 'x;
  ls_wdt_r <= 'x;
  ls_rdt_r <= 'x;
  ls_ack_r <= '0;
end else begin
  ls_req_r <= ls_req;
  ls_wen_r <= ls_wen;
  ls_sel_r <= ls_sel;
  ls_adr_r <= ls_adr;
  ls_wdt_r <= ls_wdt;
  ls_rdt_r <= ls_rdt;
  ls_ack_r <= ls_ack;
end

// write access
always @(posedge clk)
if (ls_req & ls_ack & ls_wen) begin
  $display("STORE: address=@0x%08h data=0x%08h mask=0b%04b, TXT=%s", ls_adr, ls_wdt, ls_sel, ls_wdt[8-1:0]);
end

// read access
always @(posedge clk)
if (ls_req_r & ls_ack_r & ~ls_wen_r) begin
  $display("LOAD: address=@0x%08h data=0x%08h mask=0b%04b, TXT=%s", ls_adr_r, ls_rdt, ls_sel_r, ls_rdt[8-1:0]);
end

////////////////////////////////////////////////////////////////////////////////
// IF debug
////////////////////////////////////////////////////////////////////////////////

logic           if_trn = 1'b0;
logic [IAW-1:0] if_adr_r;

always_ff @(posedge clk)
if (if_req & if_ack) begin
  if_trn <= 1'b1;
  if_adr_r <= if_adr;
end else begin
  if_trn <= 1'b0;
end

always @(posedge clk)
if (if_trn) begin
  $display("OP: @0x%08x 0x%08x: %s", if_adr_r, if_rdt, disasm32(if_rdt));
end

////////////////////////////////////////////////////////////////////////////////
// LS debug
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// waveforms
////////////////////////////////////////////////////////////////////////////////

//initial begin
//  $dumpfile("rp32_tb.vcd");
//  $dumpvars(0, rp32_tb);
//end

endmodule: r5p_tb