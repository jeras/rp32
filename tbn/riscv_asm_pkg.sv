///////////////////////////////////////////////////////////////////////////////
// RISC-V assembler package
///////////////////////////////////////////////////////////////////////////////

package riscv_asm_pkg;

import riscv_isa_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// ABI register names
///////////////////////////////////////////////////////////////////////////////

localparam string REG_X [0:31] = '{"zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0/fp", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
                                   "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};
localparam string REG_F [0:31] = '{"ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6", "ft7", "fs0", "fs1", "fa0", "fa1", "fa2", "fa3", "fa4", "fa5",
                                   "fa6", "fa7", "fs2", "fs3", "fs4", "fs5", "fs6", "fs7", "fs8", "fs9", "fs10", "fs11", "ft8", "ft9", "ft10", "ft11"};

function string reg_x (logic [5-1:0] r, bit abi=1'b0);
  reg_x = abi ? REG_X[r] : $sformatf("x%0d", r);
//  reg_x = $sformatf("x%0d", r);
endfunction: reg_x

///////////////////////////////////////////////////////////////////////////////
// CSR register names
///////////////////////////////////////////////////////////////////////////////

typedef string srting_array_t [];

// function creating a dynamic array of strings, a concatenation of string and index
function srting_array_t str_n (logic [12-1:0] l, logic [12-1:0] r, string str_i);
  if (l>r) begin
    // MSB to LSB (decrementing order)
    str_n = new[l-r+1];
    for (logic [12-1:0] i=l; i>=r; i--)
      str_n[i] = $sformatf("%s[%d]", str_i, i);
  end else begin
    // LSB to MSB (incrementing order)
    str_n = new[r-l+1];
    for (logic [12-1:0] i=l; i<=r; i++)
      str_n[i] = $sformatf("%s[%d]", str_i, i);
  end
endfunction: str_n

/*
localparam string CSR [12'h000:12'hfff] = {
                         "ustatus",
                         "fflafs",
                         "frm",
                         "fcsr",
                         "uie",
                         "utvec",
  str_n(12'h006,12'h03f, "res_006_03f"),
                         "uscratch",
                         "uepc",
                         "ucause",
                         "utval",
                         "uip",
  str_n(12'h045,12'h0ff, "res_045_0ff"),
                         "sstatus",
  str_n(12'h101,12'h101, "res_101_101"),
                         "sedeleg",
                         "sideleg",
                         "sie",
                         "stvec",
                         "scounteren",
  str_n(12'h107,12'h13f, "res_107_13f"),
                         "sscratch",
                         "sepc",
                         "scause",
                         "stval",
                         "sip",
  str_n(12'h145,12'h17f, "res_145_17f"),
                         "satp",
  str_n(12'h181,12'h1ff, "res_181_1ff"),
                         "vsstatus",
  str_n(12'h201,12'h203, "res_201_203"),
                         "vsie",
                         "vstvec",
  str_n(12'h206,12'h23f, "res_206_23f"),
                         "vsscratch",
                         "vsepc",
                         "vscause",
                         "vstval",
                         "vsip",
  str_n(12'h27f,12'h245, "res_245_27f"),
                         "vsatp",
  str_n(12'h2ff,12'h281, "res_281_2ff"),
                         "mstatus",
                         "misa",
                         "medeleg",
                         "mideleg",
                         "mie",
                         "mtvec",
                         "mcounteren",
  str_n(12'h30f,12'h307, "res_307_30f"),
                         "mstatush",
  str_n(12'h31f,12'h311, "res_311_31f"),

                         "mcountinhibit",
  str_n(12'h321,12'h322, "res_321_322"),
  str_n(12'h003,12'h01f, "mhpmevent"),
                         "mscratch",
                         "mepc",
                         "mcause",
                         "mtval",
                         "mip",
  str_n(12'h345,12'h349, "res_345_349"),
                         "mtinst",
                         "mtval2",
  str_n(12'h34c,12'h39f, "res_34c_39f"),
  str_n(12'h000,12'h00f, "pmpcfg"),
  str_n(12'h000,12'h03f, "pmpaddr"),
  str_n(12'h3f0,12'h5a7, "res_3f0_5a7"),
                         "scontext",
  str_n(12'h5a9,12'h5ff, "res_5a9_5ff"),
                         "hstatus",
  str_n(12'h601,12'h601, "res_601_601"),
                         "hedeleg",
                         "hideleg",
                         "hie",
                         "htimedelta",
                         "hcounteren",
                         "htvec",
  str_n(12'h608,12'h614, "res_608_614"),
                         "htimedeltah",
  str_n(12'h616,12'h642, "res_616_642"),
                         "htval",
                         "hip",
                         "hvip",
  str_n(12'h646,12'h649, "res_646_649"),
                         "htinst",
  str_n(12'h64b,12'h67f, "res_64b_67f"),
                         "hgatp",
  str_n(12'h681,12'h6a7, "res_681_6a7"),
                         "hcontext",
  str_n(12'h6a9,12'h79f, "res_6a9_79f"),
                         "tselect",
                         "tdata1",
                         "tdata2",
                         "tdata3",
  str_n(12'h7a4,12'h7a7, "res_7a4_7a7"),
                         "mcontext",
  str_n(12'h7a9,12'h7af, "res_7a9_7af"),
                         "dcsr",
                         "dpc",
                         "dscratch0",
                         "dscratch1",
  str_n(12'h7b4,12'haff, "res_7b4_aff"),
                         "mcycle",
  str_n(12'hb01,12'hb01, "res_b01_b01"),
                         "minstret",
  str_n(12'h003,12'h01f, "mhpmcounter"),
  str_n(12'hb20,12'hb7f, "res_b20_b7f"),
                         "mcycleh",
  str_n(12'hb81,12'hb81, "res_b81_b81"),
                         "minstreth",
  str_n(12'h003,12'h01f, "mhpmcounterh"),
  str_n(12'hba0,12'hbff, "res_ba0_bff"),
                         "cycle",
                         "time_",
                         "instret",
  str_n(12'h003,12'h01f, "hpmcounter"),
  str_n(12'hc20,12'hc7f, "res_c20_c7f"),
                         "cycleh",
                         "timeh",
                         "instreth",
  str_n(12'h003,12'h01f, "hpmcounterh"),
  str_n(12'hca0,12'he11, "res_ca0_e11"),
                         "hgeip",
  str_n(12'he13,12'hf10, "res_e13_f10"),
                         "mvendorid",
                         "marchid",
                         "mimpid",
                         "mhartid",
  str_n(12'hf15,12'hfff, "res_f15_fff")
};
*/
///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction disassembler
///////////////////////////////////////////////////////////////////////////////

function string disasm32 (isa_t isa, op32_t op, bit abi=1);

ctl_t t;
t = dec32(isa, op);

casez (op)
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b0000_0000_0000_0000_0000_0000_0001_0011: disasm32 = $sformatf("nop");
32'b????_????_????_????_????_????_?011_0111: disasm32 = $sformatf("lui    %s, 0x%08x"     , reg_x(t.gpr.a.rd , abi), t.imm);
32'b????_????_????_????_????_????_?001_0111: disasm32 = $sformatf("auipc  %s, 0x%08x"     , reg_x(t.gpr.a.rd , abi), t.imm);
32'b????_????_????_????_????_????_?110_1111: disasm32 = $sformatf("jal    %s, 0x%06x"     , reg_x(t.gpr.a.rd , abi), t.imm);
32'b????_????_????_????_?000_????_?110_0111: disasm32 = $sformatf("jalr   %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?000_????_?110_0011: disasm32 = $sformatf("beq    %s, %s, 0x%04x" , reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi), t.imm);
32'b????_????_????_????_?001_????_?110_0011: disasm32 = $sformatf("bne    %s, %s, 0x%04x" , reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi), t.imm);
32'b????_????_????_????_?100_????_?110_0011: disasm32 = $sformatf("blt    %s, %s, 0x%04x" , reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi), t.imm);
32'b????_????_????_????_?101_????_?110_0011: disasm32 = $sformatf("bge    %s, %s, 0x%04x" , reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi), t.imm);
32'b????_????_????_????_?110_????_?110_0011: disasm32 = $sformatf("bltu   %s, %s, 0x%04x" , reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi), t.imm);
32'b????_????_????_????_?111_????_?110_0011: disasm32 = $sformatf("bgeu   %s, %s, 0x%04x" , reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi), t.imm);
32'b????_????_????_????_?000_????_?000_0011: disasm32 = $sformatf("lb     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?001_????_?000_0011: disasm32 = $sformatf("lh     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?010_????_?000_0011: disasm32 = $sformatf("lw     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?011_????_?000_0011: disasm32 = $sformatf("ld     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?100_????_?000_0011: disasm32 = $sformatf("lbu    %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?101_????_?000_0011: disasm32 = $sformatf("lhu    %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?110_????_?000_0011: disasm32 = $sformatf("lwu    %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?000_????_?010_0011: disasm32 = $sformatf("sb     %s, 0x%03x (%s)", reg_x(t.gpr.a.rs2, abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?001_????_?010_0011: disasm32 = $sformatf("sh     %s, 0x%03x (%s)", reg_x(t.gpr.a.rs2, abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?010_????_?010_0011: disasm32 = $sformatf("sw     %s, 0x%03x (%s)", reg_x(t.gpr.a.rs2, abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?011_????_?010_0011: disasm32 = $sformatf("sd     %s, 0x%03x (%s)", reg_x(t.gpr.a.rs2, abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?000_????_?001_0011: disasm32 = $sformatf("addi   %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?010_????_?001_0011: disasm32 = $sformatf("slti   %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?011_????_?001_0011: disasm32 = $sformatf("sltiu  %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?100_????_?001_0011: disasm32 = $sformatf("xori   %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?110_????_?001_0011: disasm32 = $sformatf("ori    %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?111_????_?001_0011: disasm32 = $sformatf("andi   %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
32'b0000_00??_????_????_?001_????_?001_0011: disasm32 = $sformatf("slli   %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
32'b0000_00??_????_????_?101_????_?001_0011: disasm32 = $sformatf("srli   %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
32'b0100_00??_????_????_?101_????_?001_0011: disasm32 = $sformatf("srai   %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
32'b0000_000?_????_????_?000_????_?011_0011: disasm32 = $sformatf("add    %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0100_000?_????_????_?000_????_?011_0011: disasm32 = $sformatf("sub    %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?010_????_?011_0011: disasm32 = $sformatf("slt    %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?011_????_?011_0011: disasm32 = $sformatf("sltu   %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?100_????_?011_0011: disasm32 = $sformatf("xor    %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?001_????_?011_0011: disasm32 = $sformatf("sll    %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?101_????_?011_0011: disasm32 = $sformatf("srl    %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0100_000?_????_????_?101_????_?011_0011: disasm32 = $sformatf("sra    %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?110_????_?011_0011: disasm32 = $sformatf("or     %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?111_????_?011_0011: disasm32 = $sformatf("and    %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b????_????_????_????_?000_????_?000_1111: disasm32 = $sformatf("fence  0b%04b, 0b%04b fn=0x%01x, rd=%s, rs1=%s", op[27:24], op[23:20], op[31:28], reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi));
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b????_????_????_????_?001_????_?000_1111: disasm32 = $sformatf("fence.i");
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b????_????_????_????_?001_????_?111_0011: disasm32 = $sformatf("csrrw  %s, 0x%03x, %s"    , reg_x(t.gpr.a.rd , abi), t.csr.adr, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?010_????_?111_0011: disasm32 = $sformatf("csrrs  %s, 0x%03x, %s"    , reg_x(t.gpr.a.rd , abi), t.csr.adr, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?011_????_?111_0011: disasm32 = $sformatf("csrrc  %s, 0x%03x, %s"    , reg_x(t.gpr.a.rd , abi), t.csr.adr, reg_x(t.gpr.a.rs1, abi));
32'b????_????_????_????_?101_????_?111_0011: disasm32 = $sformatf("csrrwi %s, 0x%03x, 0b%05b", reg_x(t.gpr.a.rd , abi), t.csr.adr, t.csr.imm);
32'b????_????_????_????_?110_????_?111_0011: disasm32 = $sformatf("csrrsi %s, 0x%03x, 0b%05b", reg_x(t.gpr.a.rd , abi), t.csr.adr, t.csr.imm);
32'b????_????_????_????_?111_????_?111_0011: disasm32 = $sformatf("csrrci %s, 0x%03x, 0b%05b", reg_x(t.gpr.a.rd , abi), t.csr.adr, t.csr.imm);
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b0000_0000_0000_0000_0000_0000_0111_0011: disasm32 = $sformatf("ecall");
32'b0000_0000_0001_0000_0000_0000_0111_0011: disasm32 = $sformatf("ebreak");
32'b1000_0000_0000_0000_0000_0000_0111_0011: disasm32 = $sformatf("eret");
32'b0001_0000_0010_0000_0000_0000_0111_0011: disasm32 = $sformatf("wfi");

//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b????_????_????_????_?000_????_?001_1011: disasm32 = $sformatf("addiw  %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), imm32(op, T_I), reg_x(t.gpr.a.rs1, abi));
32'b0000_000?_????_????_?001_????_?001_1011: disasm32 = $sformatf("slliw  %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm[5-1:0]);
32'b0000_000?_????_????_?101_????_?001_1011: disasm32 = $sformatf("srliw  %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm[5-1:0]);
32'b0100_000?_????_????_?101_????_?001_1011: disasm32 = $sformatf("sraiw  %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm[5-1:0]);
32'b0000_000?_????_????_?000_????_?011_1011: disasm32 = $sformatf("addw   %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0100_000?_????_????_?000_????_?011_1011: disasm32 = $sformatf("subw   %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?001_????_?011_1011: disasm32 = $sformatf("sllw   %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_000?_????_????_?101_????_?011_1011: disasm32 = $sformatf("srlw   %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0100_000?_????_????_?101_????_?011_1011: disasm32 = $sformatf("sraw   %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));

//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b0000_001?_????_????_?000_????_?011_0011: disasm32 = $sformatf("mul    %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?001_????_?011_0011: disasm32 = $sformatf("mulh   %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?010_????_?011_0011: disasm32 = $sformatf("mulhsu %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?011_????_?011_0011: disasm32 = $sformatf("mulhu  %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?100_????_?011_0011: disasm32 = $sformatf("div    %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?101_????_?011_0011: disasm32 = $sformatf("divu   %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?110_????_?011_0011: disasm32 = $sformatf("rem    %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?111_????_?011_0011: disasm32 = $sformatf("remu   %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b0000_001?_????_????_?000_????_?011_1011: disasm32 = $sformatf("mulw   %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?100_????_?011_1011: disasm32 = $sformatf("divw   %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?101_????_?011_1011: disasm32 = $sformatf("divuw  %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?110_????_?011_1011: disasm32 = $sformatf("remw   %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
32'b0000_001?_????_????_?111_????_?011_1011: disasm32 = $sformatf("remuw  %s, %s, %s", reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));

//  32'b0000_0???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amoadd.w          ", TYPE_32_R};
//  32'b0010_0???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amoxor.w          ", TYPE_32_R};
//  32'b0100_0???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amoor.w           ", TYPE_32_R};
//  32'b0110_0???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amoand.w          ", TYPE_32_R};
//  32'b1000_0???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amomin.w          ", TYPE_32_R};
//  32'b1010_0???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amomax.w          ", TYPE_32_R};
//  32'b1100_0???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amominu.w         ", TYPE_32_R};
//  32'b1110_0???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amomaxu.w         ", TYPE_32_R};
//  32'b0000_1???_????_????_?010_????_?010_1111: disasm32 = $sformatf("amoswap.w         ", TYPE_32_R};
//  32'b0001_0??0_0000_????_?010_????_?010_1111: disasm32 = $sformatf("lr.w              ", TYPE_32_R};
//  32'b0001_1???_????_????_?010_????_?010_1111: disasm32 = $sformatf("sc.w              ", TYPE_32_R};
//  32'b0000_0???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amoadd.d          ", TYPE_32_R};
//  32'b0010_0???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amoxor.d          ", TYPE_32_R};
//  32'b0100_0???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amoor.d           ", TYPE_32_R};
//  32'b0110_0???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amoand.d          ", TYPE_32_R};
//  32'b1000_0???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amomin.d          ", TYPE_32_R};
//  32'b1010_0???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amomax.d          ", TYPE_32_R};
//  32'b1100_0???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amominu.d         ", TYPE_32_R};
//  32'b1110_0???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amomaxu.d         ", TYPE_32_R};
//  32'b0000_1???_????_????_?011_????_?010_1111: disasm32 = $sformatf("amoswap.d         ", TYPE_32_R};
//  32'b0001_0??0_0000_????_?011_????_?010_1111: disasm32 = $sformatf("lr.d              ", TYPE_32_R};
//  32'b0001_1???_????_????_?011_????_?010_1111: disasm32 = $sformatf("sc.d              ", TYPE_32_R};

default: disasm32 = $sformatf("ILLEGAL");
endcase
endfunction: disasm32

///////////////////////////////////////////////////////////////////////////////
// 16-bit instruction disassembler
///////////////////////////////////////////////////////////////////////////////

function string disasm16 (isa_t isa, op16_t op, bit abi=0);

ctl_t t;
t = dec16(isa, op);

// RV32 I base extension
if (|(isa.spec.base | (RV_32I | RV_64I | RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210
  16'b0000_0000_0000_0000: disasm16 = $sformatf("ILLEGAL");
  16'b0000_0000_000?_??00: disasm16 = $sformatf("ILLEGAL    RES");  // C.ADDI4SP, nzuimm=0, RES
  16'b000?_????_????_??00: disasm16 = $sformatf("c.addi4spn %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b010?_????_????_??00: disasm16 = $sformatf("c.lw       %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b100?_????_????_??00: disasm16 = $sformatf("ILLEGAL    Reserved");  // Reserved
  16'b110?_????_????_??00: disasm16 = $sformatf("c.sw       %s, 0x%03x (%s)", reg_x(t.gpr.a.rs2, abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b0000_0000_0000_0001: disasm16 = $sformatf("c.nop");
  16'b000?_0000_0???_??01: disasm16 = $sformatf("c.nop      HINT");  // C.NOP, nzimm!=0, HINT
  16'b0000_????_?000_0001: disasm16 = $sformatf("c.addi     HINT");  // C.ADDI, nzimm=0, HINT
  16'b000?_????_????_??01: disasm16 = $sformatf("c.addi     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b001?_????_????_??01: disasm16 = $sformatf("ILLEGAL");  // C.JAL, only RV32, NOTE: there are no restriction on immediate value
  16'b010?_0000_0???_??01: disasm16 = $sformatf("c.li       HINT");  // C.LI, rd=0, HINT
  16'b010?_????_????_??01: disasm16 = $sformatf("c.li       %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b0110_0001_0000_0001: disasm16 = $sformatf("ILLEGAL    RES");  // C.ADDI16SP, nzimm=0, RES
  16'b011?_0001_0???_??01: disasm16 = $sformatf("c.addi16sp %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b0110_????_?000_0001: disasm16 = $sformatf("ILLEGAL    RES");  // C.LUI, nzimm=0, RES
  16'b011?_0000_0???_??01: disasm16 = $sformatf("c.lui      HINT");
  16'b011?_????_????_??01: disasm16 = $sformatf("c.lui      %s, 0x%08x"       , reg_x(t.gpr.a.rd , abi), t.imm);
  16'b1001_00??_????_??01: disasm16 = $sformatf("ILLEGAL    NSE");  // C.SRLI, only RV32, nzuimm[5]=1, NSE
  16'b1000_00??_?000_0001: disasm16 = $sformatf("c.srli     HINT");
  16'b100?_00??_????_??01: disasm16 = $sformatf("c.srli     %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
  16'b1001_01??_?000_0001: disasm16 = $sformatf("ILLEGAL    NSE");  // C.SRAI, only RV32, nzuimm[5]=1, NSE
  16'b1000_01??_?000_0001: disasm16 = $sformatf("c.srai     HINT");
  16'b100?_01??_????_??01: disasm16 = $sformatf("c.srai     %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
  16'b100?_10??_????_??01: disasm16 = $sformatf("c.andi     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b1000_11??_?00?_??01: disasm16 = $sformatf("c.sub      %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
  16'b1000_11??_?01?_??01: disasm16 = $sformatf("c.xor      %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
  16'b1000_11??_?10?_??01: disasm16 = $sformatf("c.or       %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
  16'b1000_11??_?11?_??01: disasm16 = $sformatf("c.and      %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
  16'b1001_11??_?00?_??01: disasm16 = $sformatf("ILLEGAL    RES");  // RES
  16'b1001_11??_?01?_??01: disasm16 = $sformatf("ILLEGAL    RES");  // RES
  16'b1001_11??_?10?_??01: disasm16 = $sformatf("ILLEGAL    Reserved");  // Reserved
  16'b1001_11??_?11?_??01: disasm16 = $sformatf("ILLEGAL    Reserved");  // Reserved
  16'b101?_????_????_??01: disasm16 = $sformatf("c.j        0x%x"                                                             , t.imm);
  16'b110?_????_????_??01: disasm16 = $sformatf("c.beqz     %s, %s, 0x%04x" , reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi), t.imm);
  16'b111?_????_????_??01: disasm16 = $sformatf("c.bnez     %s, %s, 0x%04x" , reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi), t.imm);
  16'b0001_????_????_??10: disasm16 = $sformatf("ILLEGAL    NSE");  // C.SLLI, only RV32, nzuimm[5]=1, NSE
  16'b0000_0000_0000_0010: disasm16 = $sformatf("c.slli     HINT");  // C.SLLI, nzuimm=0, rd=0, HINT
  16'b0000_????_?000_0010: disasm16 = $sformatf("c.slli     HINT");  // C.SLLI, nzuimm=0, HINT
  16'b000?_0000_0???_??10: disasm16 = $sformatf("c.slli     HINT");  // C.SLLI, rd=0, HINT
  16'b000?_????_????_??10: disasm16 = $sformatf("c.slli     %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
  16'b010?_0000_0???_??10: disasm16 = $sformatf("ILLEGAL    RES");  // C.LWSP, rd=0, RES
  16'b010?_????_????_??10: disasm16 = $sformatf("c.lwsp     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b1000_0000_0000_0010: disasm16 = $sformatf("ILLEGAL    RES");  // C.JR, rs1=0, RES
  16'b1000_????_?000_0010: disasm16 = $sformatf("c.jr       %s", reg_x(t.gpr.a.rs1, abi));
  16'b1000_????_????_??10: disasm16 = $sformatf("c.mv       %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
  16'b1001_0000_0000_0010: disasm16 = $sformatf("c.break");
  16'b1001_????_?000_0010: disasm16 = $sformatf("c.jalr     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b1001_????_????_??10: disasm16 = $sformatf("c.add      %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
  16'b110?_????_????_??10: disasm16 = $sformatf("c.swsp     %s, 0x%03x (%s)", reg_x(t.gpr.a.rs2, abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  default: begin end
endcase end

// RV64 I base extension
if (|(isa.spec.base & (RV_64I | RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210
  16'b011?_????_????_??00: disasm16 = $sformatf("c.ld       %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b111?_????_????_??00: disasm16 = $sformatf("c.sd       %s, 0x%03x (%s)", reg_x(t.gpr.a.rs2, abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b100?_00??_????_??01: disasm16 = $sformatf("c.srli     %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
  16'b100?_01??_????_??01: disasm16 = $sformatf("c.srai     %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
  16'b1001_11??_?00?_??01: disasm16 = $sformatf("c.subw     %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
  16'b1001_11??_?01?_??01: disasm16 = $sformatf("c.addw     %s, %s, %s"     , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), reg_x(t.gpr.a.rs2, abi));
  16'b001?_0000_0???_??01: disasm16 = $sformatf("ILLEGAL    Reserved");  // C.ADDIW, rd=0, RES
  16'b001?_????_????_??01: disasm16 = $sformatf("c.addiw    %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b000?_????_????_??10: disasm16 = $sformatf("c.slli     %s, %s, 0x%02x" , reg_x(t.gpr.a.rd , abi), reg_x(t.gpr.a.rs1, abi), t.imm);
  16'b011?_0000_0???_??10: disasm16 = $sformatf("ILLEGAL    RES");  // C.LDSP, rd=0, RES
  16'b011?_????_????_??10: disasm16 = $sformatf("c.ldsp     %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  16'b111?_????_????_??10: disasm16 = $sformatf("c.sdsp     %s, 0x%03x (%s)", reg_x(t.gpr.a.rs2, abi), t.imm, reg_x(t.gpr.a.rs1, abi));
  default: begin end
endcase end

//$sformatf("c.jal    %s, 0x%06x"     , reg_x(t.gpr.a.rd , abi), t.imm);
//$sformatf("c.jalr   %s, 0x%03x (%s)", reg_x(t.gpr.a.rd , abi), t.imm, reg_x(t.gpr.a.rs1, abi));

endfunction: disasm16

///////////////////////////////////////////////////////////////////////////////
// instruction disassembler
///////////////////////////////////////////////////////////////////////////////

function string disasm (isa_t isa, op32_t op, bit abi=0);
  case (opsiz(op[16-1:0]))
    2      : disasm = disasm16(isa, op[16-1:0]);  // 16-bit C standard extension
    4      : disasm = disasm32(isa, op[32-1:0]);  // 32-bit
    default: disasm = $sformatf("ILLEGAL: ILEN = %dB", opsiz(op[16-1:0]));
  endcase
endfunction: disasm

endpackage: riscv_asm_pkg