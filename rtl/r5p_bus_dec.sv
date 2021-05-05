////////////////////////////////////////////////////////////////////////////////
// r5p system bus decoder
////////////////////////////////////////////////////////////////////////////////

module r5p_bus_dec #(
  // bus parameters
  int unsigned AW = 32,    // address width
  int unsigned DW = 32,    // data    width
  int unsigned SW = DW/8,  // select  width
  // interconnect parameters
  int unsigned BN = 2,     // bus number
  logic [BN-1:0] [AW-1:0] AS = '{BN{'x}}
)(
  // system signals
  input  logic                   clk,  // clock
  input  logic                   rst,  // reset
  // system bus slave port (master device connects here)
  input  logic                   s_req,  // request
  input  logic                   s_wen,  // write enable
  input  logic          [AW-1:0] s_adr,  // address
  input  logic          [SW-1:0] s_sel,  // byte select
  input  logic          [DW-1:0] s_wdt,  // write data
  output logic          [DW-1:0] s_rdt,  // read data
  output logic                   s_ack,  // acknowledge
  // system bus master ports (slave devices connect here)
  output logic [BN-1:0]          m_req,  // request
  output logic [BN-1:0]          m_wen,  // write enable
  output logic [BN-1:0] [AW-1:0] m_adr,  // address
  output logic [BN-1:0] [SW-1:0] m_sel,  // byte select
  output logic [BN-1:0] [DW-1:0] m_wdt,  // write data
  input  logic [BN-1:0] [DW-1:0] m_rdt,  // read data
  input  logic [BN-1:0]          m_ack   // acknowledge
);

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// decoder signals
logic [BN-1:0]          s_dec;
logic [BN-1:0]          m_dec;

// temporary signals
logic [BN-1:0] [DW-1:0] t_rdt;  // read data
logic [BN-1:0]          t_ack;  // acknowledge

generate
for (genvar i=0; i<BN; i++) begin
  // decoder
  assign s_dec[i] = s_adr ==? AS[i];
  // forward path
  assign m_req[i] = s_dec[i] ? s_req : '0;
  assign m_wen[i] = s_dec[i] ? s_wen : 'x;
  assign m_sel[i] = s_dec[i] ? s_sel : 'x;
  assign m_adr[i] = s_dec[i] ? s_adr : 'x;
  assign m_wdt[i] = s_dec[i] ? s_wdt : 'x;
  // backward path
  assign t_rdt[i] = m_dec[i] ? m_rdt[i] : '0;
  assign t_ack[i] = s_dec[i] ? m_ack[i] : '0;
end
endgenerate

always_comb
begin
  s_rdt = '0;
  s_ack = '0;
  for (int unsigned i=0; i<BN; i++) begin
    s_rdt |= t_rdt[i];
    s_ack |= t_ack[i];
  end
end

// TODO: 
//assign s_rdt = m_rdt.and;
//assign s_ack = m_ack.and;

// copy of decoder at a bus transfer
always_ff @(posedge clk, posedge rst)
if (rst) begin
  m_dec <= '0;
end else if (s_req & s_ack) begin
  m_dec <= s_dec;
end

endmodule: r5p_bus_dec