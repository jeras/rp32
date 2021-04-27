////////////////////////////////////////////////////////////////////////////////
// r5p system bus arbiter
////////////////////////////////////////////////////////////////////////////////

module r5p_bus_arb #(
  // bus parameters
  int unsigned AW = 32,    // address width
  int unsigned DW = 32,    // data    width
  int unsigned SW = DW/8,  // select  width
  // interconnect parameters
  int unsigned BN = 2      // bus number
)(
  // system signals
  input  logic          clk,  // clock
  input  logic          rst,  // reset
  // system bus slave ports (master devices connect here)
  input  logic          s_req [BN-1:0],  // request
  input  logic          s_wen [BN-1:0],  // write enable
  input  logic [AW-1:0] s_adr [BN-1:0],  // address
  input  logic [SW-1:0] s_sel [BN-1:0],  // byte select
  input  logic [DW-1:0] s_wdt [BN-1:0],  // write data
  input  logic [DW-1:0] s_rdt [BN-1:0],  // read data
  input  logic          s_ack [BN-1:0],  // acknowledge
  // system bus master port (slave device connects here)
  input  logic          m_req,           // request
  input  logic          m_wen,           // write enable
  input  logic [AW-1:0] m_adr,           // address
  input  logic [SW-1:0] m_sel,           // byte select
  input  logic [DW-1:0] m_wdt,           // write data
  input  logic [DW-1:0] m_rdt,           // read data
  input  logic          m_ack            // acknowledge
);

endmodule: r5p_bus_arb