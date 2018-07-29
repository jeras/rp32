module rp32_core #(
  // program bus
  int unsigned PAW = 32,    // program address width
  int unsigned PDW = 32,    // program data    width
  int unsigned PSW = PDW/8, // program select  width
  // data bus
  int unsigned DAW = 32,    // data    address width
  int unsigned DDW = 32,    // data    data    width
  int unsigned DSW = DDW/8  // data    select  width
)(
  // system signals
  input  logic                  clk,
  input  logic                  rst_n,
  // program bus (instruction fetch)
  output logic                  bup_req,
  output logic [PAW-1:0]        bup_adr,
  input  logic [PSW-1:0][8-1:0] bup_rdt,
  input  logic                  bup_ack,
  // data bus (load/store)
  output logic                  bud_req,  // write or read request
  output logic                  bud_wen,  // write enable
  output logic [DSW-1:0]        bud_sel,  // byte select
  output logic [DAW-1:0]        bud_adr,  // address
  output logic [DSW-1:0][8-1:0] bud_wdt,  // write data
  input  logic [DSW-1:0][8-1:0] bud_rdt,  // read data
  input  logic                  bud_ack   // write or read acknowledge
);

///////////////////////////////////////////////////////////////////////////////
// instruction fetch
///////////////////////////////////////////////////////////////////////////////

// request becomes active after reset
always_ff @ (posedge clk, negedge rst_n)
if (~rst_n)  bup_req <= 1'b0;
else         bup_req <= 1'b1;

// program counter
always_ff @ (posedge clk, negedge rst_n)
if (~rst_n)  bup_adr <= 0;
else         bup_adr <= bup_adr + 1;

endmodule: rp32_core
