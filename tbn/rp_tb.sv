////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module rp_tb #(
  int unsigned PAW = 16,    // program address width
  int unsigned PDW = 32,    // program data    width
  int unsigned DAW = 16,    // data    address width
  int unsigned DDW = 32,    // data    data    width
  int unsigned DSW = DDW/8  // data    select  width
)(
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
);

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// program bus
logic           bup_req;
logic [PAW-1:0] bup_adr;
logic [PDW-1:0] bup_rdt;
logic           bup_ack;
// data bus
logic           bud_req;
logic           bud_wen;
logic [DSW-1:0] bud_sel;
logic [DAW-1:0] bud_adr;
logic [DDW-1:0] bud_wdt;
logic [DDW-1:0] bud_rdt;
logic           bud_ack;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

rp32_core #(
  .PDW (PDW),
  .PAW (PAW),
  .DAW (DAW),
  .DDW (DDW)
) DUT (
  // system signals
  .clk      (clk),
  .rst      (rst),
  // program bus
  .bup_req  (bup_req),
  .bup_adr  (bup_adr),
  .bup_rdt  (bup_rdt),
  .bup_ack  (bup_ack),
  // data bus
  .bud_req  (bud_req),
  .bud_wen  (bud_wen),
  .bud_sel  (bud_sel),
  .bud_adr  (bud_adr),
  .bud_wdt  (bud_wdt),
  .bud_rdt  (bud_rdt),
  .bud_ack  (bud_ack)
);

////////////////////////////////////////////////////////////////////////////////
// program memory
////////////////////////////////////////////////////////////////////////////////

mem #(
  .FN ("test_isa.vmem"),
  .SZ (2**PAW),
  .DW (PDW)
) mem_prg (
  .clk (clk),
  .req (bup_req),
  .wen ('0),
  .sel ('1),
  .adr (bup_adr),
  .wdt ('x),
  .rdt (bup_rdt),
  .ack (bup_ack)
);

////////////////////////////////////////////////////////////////////////////////
// data memory
////////////////////////////////////////////////////////////////////////////////

mem #(
  .SZ (2**DAW),
  .DW (DDW)
) mem_dat (
  .clk (clk),
  .req (bud_req),
  .wen (bud_wen),
  .sel (bud_sel),
  .adr (bud_adr),
  .wdt (bud_wdt),
  .rdt (bud_rdt),
  .ack (bud_ack)
);

////////////////////////////////////////////////////////////////////////////////
// waveforms
////////////////////////////////////////////////////////////////////////////////

//initial begin
//  $dumpfile("rp32_tb.vcd");
//  $dumpvars(0, rp32_tb);
//end

endmodule: rp_tb
