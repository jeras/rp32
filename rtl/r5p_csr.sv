///////////////////////////////////////////////////////////////////////////////
// R5P: control/status registers
///////////////////////////////////////////////////////////////////////////////

import riscv_isa_pkg::ctl_csr_t;
import riscv_csr_pkg::*;

import r5p_pkg::*;
import r5p_csr_pkg::*;

module r5p_csr #(
  isa_t            ISA = RV32I,
  int unsigned     XLEN = 32,
  // constants ???
  logic [XLEN-1:0] MTVEC = '0  // machine trap vector
)(
  // system signals
  input  logic            clk,  // clock
  input  logic            rst,  // reset
  // CSR address map union output
  output csr_map_ut       csr_map,
  // CSR control and data input/output
  input  ctl_csr_t        csr_ctl,  // CSR instruction control structure
  input  logic [XLEN-1:0] csr_wdt,  // write data from GPR
  output logic [XLEN-1:0] csr_rdt,  // read  data to   GPR
  // trap handler
  input  ctl_priv_t       priv_i,  // privileged instruction control structure
  input  logic            trap_i,  // 
  input  logic [XLEN-1:0] cause_i,
  input  logic [XLEN-1:0] epc_i,  // PC increment
  output logic [XLEN-1:0] epc_o,  // exception program counter
  output logic [XLEN-1:0] tvec,   // trap vector
  // hardware performance monitor
  input  r5p_hpmevent_t   event_i
  // TODO: debugger, ...
);

///////////////////////////////////////////////////////////////////////////////
// CSR access details
///////////////////////////////////////////////////////////////////////////////

// current privilege level
// TODO: current level should be a register
isa_level_t level = LVL_M;

///////////////////////////////////////////////////////////////////////////////
// CSR Address Mapping Conventions
///////////////////////////////////////////////////////////////////////////////

// convention signals
logic cnv_aen;  // access enable  (depends on register address range)
logic cnv_ren;  // read   enable
logic cnv_wen;  // write  enable  (depends on register address range)

// convention access enable
//   Access is enabled if the level in the CSR address
//   is lower or equal to the current privilege level.
assign cnv_aen = csr_ctl.adr.level <= level;

// convention read/write enable
//   Read access has no additional limitations.
//   Write access is further limited to `ACCESS_RW[012]` segments of the CSR address space.
assign cnv_ren = cnv_aen;
assign cnv_wen = cnv_aen & (csr_ctl.adr.perm != ACCESS_RO3);

logic csr_ren;  // read   enable
logic csr_wen;  // write  enable  (depends on register address range)

// CSR read/write enable
// Depends on Zicsr instruction decoder and CSR Address Mapping Conventions)
assign csr_ren = csr_ctl.ren & cnv_ren;
assign csr_wen = csr_ctl.wen & cnv_wen;

// CSR address decoder
csr_dec_ut csr_dec;

// TODO: define access error conditions triggering illegal instruction

// CSR access illegal function
function logic [XLEN-1:0] csr_ill_f (
  logic [XLEN-1:0] csr_rdt
);
endfunction: csr_ill_f

///////////////////////////////////////////////////////////////////////////////
// CSR data constructs
///////////////////////////////////////////////////////////////////////////////

// CSR data mask
logic [XLEN-1:0] csr_msk;

// CSR data mask decoder
always_comb begin
  unique case (csr_ctl.msk)
    CSR_REG: csr_msk = csr_wdt;             // GPR register source 1
    CSR_IMM: csr_msk = XLEN'(csr_ctl.imm);  // 5-bit zero extended immediate
    default: csr_msk = 'x;
  endcase
end

// CSR write mask function
function logic [XLEN-1:0] csr_wdt_f (
  logic [XLEN-1:0] csr_rdt
);
  unique casez (csr_ctl.op)
    CSR_RW : csr_wdt_f =            csr_msk;  // write mask bits
    CSR_SET: csr_wdt_f = csr_rdt |  csr_msk;  // set   mask bits
    CSR_CLR: csr_wdt_f = csr_rdt & ~csr_msk;  // clear mask bits
    default: begin end
  endcase
endfunction: csr_wdt_f

///////////////////////////////////////////////////////////////////////////////
// helper functions
///////////////////////////////////////////////////////////////////////////////

// TVEC address calculator
function logic [XLEN-1:0] tvec_f (
  csr_mtvec_t  tvec,
  csr_mcause_t cause
);
  unique case (tvec.MODE)
    TVEC_MODE_DIRECT  : tvec_f = {tvec.BASE, 2'b00};
    TVEC_MODE_VECTORED: tvec_f = {tvec.BASE + 4 * cause[6-1:0], 2'b00};
    default           : tvec_f = 'x;
  endcase
endfunction: tvec_f

///////////////////////////////////////////////////////////////////////////////
// read/write access
///////////////////////////////////////////////////////////////////////////////

// CSR address decoder
assign csr_dec = csr_dec_f(csr_ctl.adr);

// read access
assign csr_rdt = csr_ren ? csr_map.a[csr_ctl.adr] : '0;

// write access (CSR operation decoder)
always_ff @(posedge clk, posedge rst)
if (rst) begin
  // NOTE: a direct union to union (or struct to struct) assignment triggered some Verilator bug
  //   csr_map <= CSR_RST;  // this is triggering a verilator bug
  for (int unsigned i=0; i<2**12; i++) begin: reset
    csr_map.a[i] <= CSR_RST.a[i];
  end: reset
  // individual registers reset values are overriden
//  csr_map.s.misa      <= csr_misa_f(ISA);
//  csr_map.s.mtvec     <= MTVEC;
end else begin

// TODO:
// mstatus
// mtval on ebreak to PC?

  // trap handler
  if (trap_i) begin
    // trap handler
    unique case (level)
      LVL_U:  begin  csr_map.s.uepc <= epc_i;  csr_map.s.ucause <= cause_i;  end  // User/Application
      LVL_S:  begin  csr_map.s.sepc <= epc_i;  csr_map.s.scause <= cause_i;  end  // Supervisor
      LVL_R:  begin                                                          end  // Reserved
      LVL_M:  begin  csr_map.s.mepc <= epc_i;  csr_map.s.mcause <= cause_i;  end  // Machine
    endcase
  end else begin
    // Zicsr access
    if (csr_wen) begin
      unique casez (csr_ctl.op)
        CSR_RW : csr_map.a[csr_ctl.adr] <=            csr_wdt;  // read/write
        CSR_SET: csr_map.a[csr_ctl.adr] <= csr_rdt |  csr_msk;  // set   masked bits
        CSR_CLR: csr_map.a[csr_ctl.adr] <= csr_rdt & ~csr_msk;  // clear masked bits
        default: begin end
      endcase
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  // machine hardware performance monitor
  ///////////////////////////////////////////////////////////////////////////////
  
  // machine cycle counter
  if (csr_wen & csr_dec.s.mcycle) begin
    csr_map.s.mcycle <= csr_wdt_f(csr_map.s.mcycle);
  end else begin
    if (~csr_map.s.mcountinhibit.CY & event_i.cycle)  csr_map.s.mcycle <= csr_map.s.mcycle + 1;
  end
  // machine instruction-retired counter
  if (csr_wen & csr_dec.s.minstret) begin
    csr_map.s.minstret <= csr_wdt_f(csr_map.s.minstret);
  end else begin
    if (~csr_map.s.mcountinhibit.IR & event_i.instret)  csr_map.s.minstret <= csr_map.s.minstret + 1;
  end
  // machine performance monitor counter
  for (int unsigned i=3; i<32; i++) begin
    if (csr_wen & csr_dec.s.mhpmcounter[i]) begin
      csr_map.s.mhpmcounter[i] <= csr_wdt_f(csr_map.s.mhpmcounter[i]);
    end else begin
      if (~csr_map.s.mcountinhibit.HPM[i] & |(XLEN'(event_i) & csr_map.s.mhpmevent[i]))  csr_map.s.mhpmcounter[i] <= csr_map.s.mhpmcounter[i] + 1;
    end
  end
end

// TVEC (trap-vector address) and EPC (machine exception program counter)
// depend on 
always_comb begin
  unique case (level)
    LVL_U:  begin  tvec = tvec_f(csr_map.s.utvec, csr_map.s.ucause);  epc_o = csr_map.s.uepc;  end  // User/Application
    LVL_S:  begin  tvec = tvec_f(csr_map.s.stvec, csr_map.s.scause);  epc_o = csr_map.s.sepc;  end  // Supervisor
    LVL_R:  begin  tvec = 'x                                       ;  epc_o = 'x            ;  end  // Reserved
    LVL_M:  begin  tvec = tvec_f(csr_map.s.mtvec, csr_map.s.mcause);  epc_o = csr_map.s.mepc;  end  // Machine
  //default:begin  tvec = 'x                                       ;  epc_o = 'x            ;  end  // Reserved
  endcase
end

// 

endmodule: r5p_csr