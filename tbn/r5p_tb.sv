////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module r5p_tb #(
  int unsigned IAW = 21,    // instruction address width
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

// instruction fetch bus
logic           if_req;
logic [IAW-1:0] if_adr;
logic [IDW-1:0] if_rdt;
logic           if_ack;
// load/store bus, LS memory bus, controller bus
logic           ls_req, ls_mem_req, ls_ctl_req;
logic           ls_wen, ls_mem_wen, ls_ctl_wen;
logic [DAW-0:0] ls_adr, ls_mem_adr, ls_ctl_adr;  // +1 bits for decoder
logic [DSW-1:0] ls_sel, ls_mem_sel, ls_ctl_sel;
logic [DDW-1:0] ls_wdt, ls_mem_wdt, ls_ctl_wdt;
logic [DDW-1:0] ls_rdt, ls_mem_rdt, ls_ctl_rdt;
logic           ls_ack, ls_mem_ack, ls_ctl_ack;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

r5p_core #(
  .IDW  (IDW),
  .IAW  (IAW),
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
  .ls_sel  (ls_sel),
  .ls_wdt  (ls_wdt),
  .ls_rdt  (ls_rdt),
  .ls_ack  (ls_ack)
);

////////////////////////////////////////////////////////////////////////////////
// program memory
////////////////////////////////////////////////////////////////////////////////

string if_str;
always if_str = riscv_disasm(if_rdt);

mem #(
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
  .sel  ('1),
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
  .sel  ('1),
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
  .s_sel  (ls_sel),  .m_sel  ('{ls_ctl_sel, ls_mem_sel}),
  .s_adr  (ls_adr),  .m_adr  ('{ls_ctl_adr, ls_mem_adr}),
  .s_wdt  (ls_wdt),  .m_wdt  ('{ls_ctl_wdt, ls_mem_wdt}),
  .s_rdt  (ls_rdt),  .m_rdt  ('{ls_ctl_rdt, ls_mem_rdt}),
  .s_ack  (ls_ack),  .m_ack  ('{ls_ctl_ack, ls_mem_ack})
);

////////////////////////////////////////////////////////////////////////////////
// data memory
////////////////////////////////////////////////////////////////////////////////

mem #(
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
  .sel  (ls_mem_sel),
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
  .sel  (ls_sel),
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
  rvmodel_halt       <= 'x;
end else if (ls_ctl_req & ls_ctl_ack) begin
  if (ls_ctl_wen) begin
    // write access
    case (ls_ctl_adr[4-1:0])
      4'h0:  rvmodel_data_begin <= ls_ctl_wdt;
      4'h4:  rvmodel_data_end   <= ls_ctl_wdt;
      4'h8:  rvmodel_halt       <= ls_ctl_wdt[0];
      default:  ;  // do nothing
    endcase
  end
end

// controller response is immediate
assign ls_ctl_ack = 1'b1;

// finish simulation
always @(posedge clk)
if (rvmodel_halt) begin
  void'(mem_ls.write_hex("signature.txt", rvmodel_data_begin, rvmodel_data_end));
  $finish;
end

////////////////////////////////////////////////////////////////////////////////
// waveforms
////////////////////////////////////////////////////////////////////////////////

//initial begin
//  $dumpfile("rp32_tb.vcd");
//  $dumpvars(0, rp32_tb);
//end

endmodule: r5p_tb