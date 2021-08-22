///////////////////////////////////////////////////////////////////////////////
// control/status registers
///////////////////////////////////////////////////////////////////////////////

import riscv_isa_pkg::ctl_csr_t;
import riscv_csr_pkg::*;
import riscv_csr_adr_map_pkg::*;

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
  output logic [XLEN-1:0] tvec    // trap vector
  // TODO: debugger, ...
);

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

logic            csr_aen;  // access enable (depends on register address range)
logic            csr_ren;  // read enable
logic            csr_wen;  // write enable
logic [XLEN-1:0] csr_msk;  // mask data

// current privilege level
isa_level_t level = LVL_M;

// CSR mask decoder
always_comb begin
  unique case (csr_ctl.msk)
    CSR_REG: csr_msk = csr_wdt;             // GPR register source 1
    CSR_IMM: csr_msk = XLEN'(csr_ctl.imm);  // 5-bit zero extended immediate
    default: csr_msk = 'x;
  endcase
end

// read/write access permissions
assign csr_aen = csr_ctl.adr.level <= level;
assign csr_ren = csr_aen & csr_ctl.ren;
assign csr_wen = csr_aen & csr_ctl.wen & (csr_ctl.adr.perm != ACCESS_RO3);

// TODO: define access error conditions triggering illegal instruction


// read access
assign csr_rdt = csr_ren ? csr_map.a[csr_ctl.adr] : '0;

// write access (CSR operation decoder)
always_ff @(posedge clk, posedge rst)
if (rst) begin
  // TODO: use a better default
  for (int unsigned i=1; i<2**12; i++) begin: reset
    csr_map.a[i] <= '{default: '0};
  end: reset
  // individual registers reset values are overriden
  csr_map.s.misa      <= csr_misa_f(ISA);
  csr_map.s.mvendorid <= '0;
  csr_map.s.marchid   <= '0;
  csr_map.s.mimpid    <= '0;
  csr_map.s.mtvec     <= MTVEC;
  csr_map.s.medeleg   <= '0;
  csr_map.s.mideleg   <= '0;
//  csr_map.s.m   <= '0;
//  csr_map.s.m   <= '0;
//  csr_map.s.m   <= '0;
//  csr_map.s.m   <= '0;
//  csr_map.s.m   <= '0;
//  csr_map.s.m   <= '0;
//  csr_map.s.m   <= '0;
end else begin

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

  // hardware performance monitor


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