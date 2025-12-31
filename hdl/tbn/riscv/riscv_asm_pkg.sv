///////////////////////////////////////////////////////////////////////////////
// RISC-V dis-assembler package
///////////////////////////////////////////////////////////////////////////////
// Copyright 2022 Iztok Jeras
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////////

package riscv_asm_pkg;

import riscv_isa_pkg::*;
import riscv_priv_pkg::*;
import riscv_isa_i_pkg::*;
import riscv_isa_c_pkg::*;

import rv32_csr_pkg::*;
//import rv64_csr_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// ABI register names
///////////////////////////////////////////////////////////////////////////////

localparam string GPR_N [0:31] = '{"zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0/fp", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
                                   "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};
localparam string FPR_N [0:31] = '{"ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6", "ft7", "fs0", "fs1", "fa0", "fa1", "fa2", "fa3", "fa4", "fa5",
                                   "fa6", "fa7", "fs2", "fs3", "fs4", "fs5", "fs6", "fs7", "fs8", "fs9", "fs10", "fs11", "ft8", "ft9", "ft10", "ft11"};

function automatic string gpr_n (logic [5-1:0] gpr, bit abi=1'b0);
  gpr_n = abi ? GPR_N[gpr] : $sformatf("x%0d", gpr);
endfunction: gpr_n

///////////////////////////////////////////////////////////////////////////////
// CSR register names
///////////////////////////////////////////////////////////////////////////////

function automatic string csr_n (csr_dec_t csr, bit abi=1'b0);
  csr_n = abi ? csr.name : $sformatf("0x%3x", csr);
endfunction: csr_n

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction disassembler
///////////////////////////////////////////////////////////////////////////////

function automatic string disasm32 (isa_t isa, op32_t op, bit abi=0);

dec_t t;
t = dec32(isa, op);

// RV32 I base extension
casez (op)
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b0000_0000_0000_0000_0000_0000_0001_0011: disasm32 = $sformatf("nop");
32'b????_????_????_????_????_????_?011_0111: disasm32 = $sformatf("lui    %s, 0x%8x"     , gpr_n(t.rd , abi), t.i_u);
32'b????_????_????_????_????_????_?001_0111: disasm32 = $sformatf("auipc  %s, 0x%8x"     , gpr_n(t.rd , abi), t.i_u);
32'b????_????_????_????_????_????_?110_1111: disasm32 = $sformatf("jal    %s, 0x%6x"     , gpr_n(t.rd , abi), t.i_j);
32'b????_????_????_????_?000_????_?110_0111: disasm32 = $sformatf("jalr   %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_i, gpr_n(t.rs1, abi));
32'b????_????_????_????_?000_????_?110_0011: disasm32 = $sformatf("beq    %s, %s, 0x%4x" , gpr_n(t.rs1, abi), gpr_n(t.rs2, abi), t.i_b);
32'b????_????_????_????_?001_????_?110_0011: disasm32 = $sformatf("bne    %s, %s, 0x%4x" , gpr_n(t.rs1, abi), gpr_n(t.rs2, abi), t.i_b);
32'b????_????_????_????_?100_????_?110_0011: disasm32 = $sformatf("blt    %s, %s, 0x%4x" , gpr_n(t.rs1, abi), gpr_n(t.rs2, abi), t.i_b);
32'b????_????_????_????_?101_????_?110_0011: disasm32 = $sformatf("bge    %s, %s, 0x%4x" , gpr_n(t.rs1, abi), gpr_n(t.rs2, abi), t.i_b);
32'b????_????_????_????_?110_????_?110_0011: disasm32 = $sformatf("bltu   %s, %s, 0x%4x" , gpr_n(t.rs1, abi), gpr_n(t.rs2, abi), t.i_b);
32'b????_????_????_????_?111_????_?110_0011: disasm32 = $sformatf("bgeu   %s, %s, 0x%4x" , gpr_n(t.rs1, abi), gpr_n(t.rs2, abi), t.i_b);
32'b????_????_????_????_?000_????_?000_0011: disasm32 = $sformatf("lb     %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
32'b????_????_????_????_?001_????_?000_0011: disasm32 = $sformatf("lh     %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
32'b????_????_????_????_?010_????_?000_0011: disasm32 = $sformatf("lw     %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
32'b????_????_????_????_?011_????_?000_0011: disasm32 = $sformatf("ld     %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
32'b????_????_????_????_?100_????_?000_0011: disasm32 = $sformatf("lbu    %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
32'b????_????_????_????_?101_????_?000_0011: disasm32 = $sformatf("lhu    %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
32'b????_????_????_????_?110_????_?000_0011: disasm32 = $sformatf("lwu    %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
32'b????_????_????_????_?000_????_?010_0011: disasm32 = $sformatf("sb     %s, 0x%3x (%s)", gpr_n(t.rs2, abi), t.i_s, gpr_n(t.rs1, abi));
32'b????_????_????_????_?001_????_?010_0011: disasm32 = $sformatf("sh     %s, 0x%3x (%s)", gpr_n(t.rs2, abi), t.i_s, gpr_n(t.rs1, abi));
32'b????_????_????_????_?010_????_?010_0011: disasm32 = $sformatf("sw     %s, 0x%3x (%s)", gpr_n(t.rs2, abi), t.i_s, gpr_n(t.rs1, abi));
32'b????_????_????_????_?011_????_?010_0011: disasm32 = $sformatf("sd     %s, 0x%3x (%s)", gpr_n(t.rs2, abi), t.i_s, gpr_n(t.rs1, abi));
32'b????_????_????_????_?000_????_?001_0011: disasm32 = $sformatf("addi   %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
32'b????_????_????_????_?010_????_?001_0011: disasm32 = $sformatf("slti   %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
32'b????_????_????_????_?011_????_?001_0011: disasm32 = $sformatf("sltiu  %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
32'b????_????_????_????_?100_????_?001_0011: disasm32 = $sformatf("xori   %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
32'b????_????_????_????_?110_????_?001_0011: disasm32 = $sformatf("ori    %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
32'b????_????_????_????_?111_????_?001_0011: disasm32 = $sformatf("andi   %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
32'b0000_00??_????_????_?001_????_?001_0011: disasm32 = $sformatf("slli   %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
32'b0000_00??_????_????_?101_????_?001_0011: disasm32 = $sformatf("srli   %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
32'b0100_00??_????_????_?101_????_?001_0011: disasm32 = $sformatf("srai   %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
32'b0000_000?_????_????_?000_????_?011_0011: disasm32 = $sformatf("add    %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0100_000?_????_????_?000_????_?011_0011: disasm32 = $sformatf("sub    %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?010_????_?011_0011: disasm32 = $sformatf("slt    %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?011_????_?011_0011: disasm32 = $sformatf("sltu   %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?100_????_?011_0011: disasm32 = $sformatf("xor    %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?001_????_?011_0011: disasm32 = $sformatf("sll    %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?101_????_?011_0011: disasm32 = $sformatf("srl    %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0100_000?_????_????_?101_????_?011_0011: disasm32 = $sformatf("sra    %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?110_????_?011_0011: disasm32 = $sformatf("or     %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?111_????_?011_0011: disasm32 = $sformatf("and    %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b????_????_????_????_?000_????_?000_1111: disasm32 = $sformatf("fence  0b%4b, 0b%4b fn=0x%1x, rd=%s, rs1=%s", op[27:24], op[23:20], op[31:28], gpr_n(t.rd , abi), gpr_n(t.rs1, abi));
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b????_????_????_????_?001_????_?000_1111: disasm32 = $sformatf("fence.i");
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b????_????_????_????_?001_????_?111_0011: disasm32 = $sformatf("csrrw  %s, %s, %s"   , gpr_n(t.rd , abi), csr_n(csr_dec_t'(t.csr), abi), gpr_n(t.rs1, abi));
32'b????_????_????_????_?010_????_?111_0011: disasm32 = $sformatf("csrrs  %s, %s, %s"   , gpr_n(t.rd , abi), csr_n(csr_dec_t'(t.csr), abi), gpr_n(t.rs1, abi));
32'b????_????_????_????_?011_????_?111_0011: disasm32 = $sformatf("csrrc  %s, %s, %s"   , gpr_n(t.rd , abi), csr_n(csr_dec_t'(t.csr), abi), gpr_n(t.rs1, abi));
32'b????_????_????_????_?101_????_?111_0011: disasm32 = $sformatf("csrrwi %s, %s, 0b%5b", gpr_n(t.rd , abi), csr_n(csr_dec_t'(t.csr), abi), t.i_c);
32'b????_????_????_????_?110_????_?111_0011: disasm32 = $sformatf("csrrsi %s, %s, 0b%5b", gpr_n(t.rd , abi), csr_n(csr_dec_t'(t.csr), abi), t.i_c);
32'b????_????_????_????_?111_????_?111_0011: disasm32 = $sformatf("csrrci %s, %s, 0b%5b", gpr_n(t.rd , abi), csr_n(csr_dec_t'(t.csr), abi), t.i_c);
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b0000_0000_0000_0000_0000_0000_0111_0011: disasm32 = $sformatf("ecall");
32'b0000_0000_0001_0000_0000_0000_0111_0011: disasm32 = $sformatf("ebreak");
32'b0000_0000_0010_0000_0000_0000_0111_0011: disasm32 = $sformatf("uret");
32'b0001_0000_0010_0000_0000_0000_0111_0011: disasm32 = $sformatf("sret");
32'b0011_0000_0010_0000_0000_0000_0111_0011: disasm32 = $sformatf("mret");
32'b0001_0000_0010_0000_0000_0000_0111_0011: disasm32 = $sformatf("wfi");

//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b????_????_????_????_?000_????_?001_1011: disasm32 = $sformatf("addiw  %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
32'b0000_000?_????_????_?001_????_?001_1011: disasm32 = $sformatf("slliw  %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[5-1:0]);
32'b0000_000?_????_????_?101_????_?001_1011: disasm32 = $sformatf("srliw  %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[5-1:0]);
32'b0100_000?_????_????_?101_????_?001_1011: disasm32 = $sformatf("sraiw  %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[5-1:0]);
32'b0000_000?_????_????_?000_????_?011_1011: disasm32 = $sformatf("addw   %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0100_000?_????_????_?000_????_?011_1011: disasm32 = $sformatf("subw   %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?001_????_?011_1011: disasm32 = $sformatf("sllw   %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_000?_????_????_?101_????_?011_1011: disasm32 = $sformatf("srlw   %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0100_000?_????_????_?101_????_?011_1011: disasm32 = $sformatf("sraw   %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));

//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b0000_001?_????_????_?000_????_?011_0011: disasm32 = $sformatf("mul    %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?001_????_?011_0011: disasm32 = $sformatf("mulh   %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?010_????_?011_0011: disasm32 = $sformatf("mulhsu %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?011_????_?011_0011: disasm32 = $sformatf("mulhu  %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?100_????_?011_0011: disasm32 = $sformatf("div    %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?101_????_?011_0011: disasm32 = $sformatf("divu   %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?110_????_?011_0011: disasm32 = $sformatf("rem    %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?111_????_?011_0011: disasm32 = $sformatf("remu   %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210
32'b0000_001?_????_????_?000_????_?011_1011: disasm32 = $sformatf("mulw   %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?100_????_?011_1011: disasm32 = $sformatf("divw   %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?101_????_?011_1011: disasm32 = $sformatf("divuw  %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?110_????_?011_1011: disasm32 = $sformatf("remw   %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
32'b0000_001?_????_????_?111_????_?011_1011: disasm32 = $sformatf("remuw  %s, %s, %s", gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));

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

function automatic string disasm16 (isa_t isa, op16_t op, bit abi=0);

dec_t t;
t = dec16(isa, op);

// RV32 C base extension
if (|(isa.spec.base | (RV_32I | RV_64I | RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210
  16'b0000_0000_0000_0000: disasm16 = $sformatf("ILLEGAL");
  16'b0000_0000_000?_??00: disasm16 = $sformatf("ILLEGAL    RES");  // C.ADDI4SP, nzuimm=0, RES
  16'b000?_????_????_??00: disasm16 = $sformatf("c.addi4spn %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
  16'b010?_????_????_??00: disasm16 = $sformatf("c.lw       %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
  16'b100?_????_????_??00: disasm16 = $sformatf("ILLEGAL    Reserved");  // Reserved
  16'b110?_????_????_??00: disasm16 = $sformatf("c.sw       %s, 0x%3x (%s)", gpr_n(t.rs2, abi), t.i_s, gpr_n(t.rs1, abi));
  16'b0000_0000_0000_0001: disasm16 = $sformatf("c.nop");
  16'b000?_0000_0???_??01: disasm16 = $sformatf("c.nop      HINT");  // C.NOP, nzimm!=0, HINT
  16'b0000_????_?000_0001: disasm16 = $sformatf("c.addi     HINT");  // C.ADDI, nzimm=0, HINT
  16'b000?_????_????_??01: disasm16 = $sformatf("c.addi     %s, %s, 0x%3x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i);
  16'b001?_????_????_??01: disasm16 = $sformatf("c.jal      0x%x"                                                , t.i_j);
  16'b010?_0000_0???_??01: disasm16 = $sformatf("c.li       HINT");  // C.LI, rd=0, HINT
  16'b010?_????_????_??01: disasm16 = $sformatf("c.li       %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_i, gpr_n(t.rs1, abi));
  16'b0110_0001_0000_0001: disasm16 = $sformatf("ILLEGAL    RES");  // C.ADDI16SP, nzimm=0, RES
  16'b011?_0001_0???_??01: disasm16 = $sformatf("c.addi16sp %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_i, gpr_n(t.rs1, abi));
  16'b0110_????_?000_0001: disasm16 = $sformatf("ILLEGAL    RES");  // C.LUI, nzimm=0, RES
  16'b011?_0000_0???_??01: disasm16 = $sformatf("c.lui      HINT");
  16'b011?_????_????_??01: disasm16 = $sformatf("c.lui      %s, 0x%8x"     , gpr_n(t.rd , abi), t.i_u);
  16'b1001_00??_????_??01: disasm16 = $sformatf("ILLEGAL    NSE");  // C.SRLI, only RV32, nzuimm[5]=1, NSE
  16'b1000_00??_?000_0001: disasm16 = $sformatf("c.srli     HINT");
  16'b100?_00??_????_??01: disasm16 = $sformatf("c.srli     %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
  16'b1001_01??_?000_0001: disasm16 = $sformatf("ILLEGAL    NSE");  // C.SRAI, only RV32, nzuimm[5]=1, NSE
  16'b1000_01??_?000_0001: disasm16 = $sformatf("c.srai     HINT");
  16'b100?_01??_????_??01: disasm16 = $sformatf("c.srai     %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
  16'b100?_10??_????_??01: disasm16 = $sformatf("c.andi     %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_i, gpr_n(t.rs1, abi));
  16'b1000_11??_?00?_??01: disasm16 = $sformatf("c.sub      %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
  16'b1000_11??_?01?_??01: disasm16 = $sformatf("c.xor      %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
  16'b1000_11??_?10?_??01: disasm16 = $sformatf("c.or       %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
  16'b1000_11??_?11?_??01: disasm16 = $sformatf("c.and      %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
  16'b1001_11??_?00?_??01: disasm16 = $sformatf("ILLEGAL    RES");  // RES
  16'b1001_11??_?01?_??01: disasm16 = $sformatf("ILLEGAL    RES");  // RES
  16'b1001_11??_?10?_??01: disasm16 = $sformatf("ILLEGAL    Reserved");  // Reserved
  16'b1001_11??_?11?_??01: disasm16 = $sformatf("ILLEGAL    Reserved");  // Reserved
  16'b101?_????_????_??01: disasm16 = $sformatf("c.j        0x%x"                                                , t.i_j);
  16'b110?_????_????_??01: disasm16 = $sformatf("c.beqz     %s, %s, 0x%4x" , gpr_n(t.rs1, abi), gpr_n(t.rs2, abi), t.i_b);
  16'b111?_????_????_??01: disasm16 = $sformatf("c.bnez     %s, %s, 0x%4x" , gpr_n(t.rs1, abi), gpr_n(t.rs2, abi), t.i_b);
  16'b0001_????_????_??10: disasm16 = $sformatf("ILLEGAL    NSE");  // C.SLLI, only RV32, nzuimm[5]=1, NSE
  16'b0000_0000_0000_0010: disasm16 = $sformatf("c.slli     HINT");  // C.SLLI, nzuimm=0, rd=0, HINT
  16'b0000_????_?000_0010: disasm16 = $sformatf("c.slli     HINT");  // C.SLLI, nzuimm=0, HINT
  16'b000?_0000_0???_??10: disasm16 = $sformatf("c.slli     HINT");  // C.SLLI, rd=0, HINT
  16'b000?_????_????_??10: disasm16 = $sformatf("c.slli     %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
  16'b010?_0000_0???_??10: disasm16 = $sformatf("ILLEGAL    RES");  // C.LWSP, rd=0, RES
  16'b010?_????_????_??10: disasm16 = $sformatf("c.lwsp     %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
  16'b1000_0000_0000_0010: disasm16 = $sformatf("ILLEGAL    RES");  // C.JR, rs1=0, RES
  16'b1000_????_?000_0010: disasm16 = $sformatf("c.jr       %s", gpr_n(t.rs1, abi));
  16'b1000_????_????_??10: disasm16 = $sformatf("c.mv       %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
  16'b1001_0000_0000_0010: disasm16 = $sformatf("c.break");
  16'b1001_????_?000_0010: disasm16 = $sformatf("c.jalr     %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_i, gpr_n(t.rs1, abi));
  16'b1001_????_????_??10: disasm16 = $sformatf("c.add      %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
  16'b110?_????_????_??10: disasm16 = $sformatf("c.swsp     %s, 0x%3x (%s)", gpr_n(t.rs2, abi), t.i_s, gpr_n(t.rs1, abi));
  default: begin end
endcase end

// RV64 C base extension
if (|(isa.spec.base & (RV_64I | RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210
  16'b011?_????_????_??00: disasm16 = $sformatf("c.ld       %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
  16'b111?_????_????_??00: disasm16 = $sformatf("c.sd       %s, 0x%3x (%s)", gpr_n(t.rs2, abi), t.i_s, gpr_n(t.rs1, abi));
  16'b100?_00??_????_??01: disasm16 = $sformatf("c.srli     %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
  16'b100?_01??_????_??01: disasm16 = $sformatf("c.srai     %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
  16'b1001_11??_?00?_??01: disasm16 = $sformatf("c.subw     %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
  16'b1001_11??_?01?_??01: disasm16 = $sformatf("c.addw     %s, %s, %s"    , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), gpr_n(t.rs2, abi));
  16'b001?_0000_0???_??01: disasm16 = $sformatf("ILLEGAL    Reserved");  // C.ADDIW, rd=0, RES
  16'b001?_????_????_??01: disasm16 = $sformatf("c.addiw    %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_i, gpr_n(t.rs1, abi));
  16'b000?_????_????_??10: disasm16 = $sformatf("c.slli     %s, %s, 0x%2x" , gpr_n(t.rd , abi), gpr_n(t.rs1, abi), t.i_i[6-1:0]);
  16'b011?_0000_0???_??10: disasm16 = $sformatf("ILLEGAL    RES");  // C.LDSP, rd=0, RES
  16'b011?_????_????_??10: disasm16 = $sformatf("c.ldsp     %s, 0x%3x (%s)", gpr_n(t.rd , abi), t.i_l, gpr_n(t.rs1, abi));
  16'b111?_????_????_??10: disasm16 = $sformatf("c.sdsp     %s, 0x%3x (%s)", gpr_n(t.rs2, abi), t.i_s, gpr_n(t.rs1, abi));
  default: begin end
endcase end

endfunction: disasm16

///////////////////////////////////////////////////////////////////////////////
// instruction disassembler
///////////////////////////////////////////////////////////////////////////////

function automatic string disasm (isa_t isa, op32_t op, bit abi=0);
  case (opsiz(op[16-1:0]))
    2      : disasm = disasm16(isa, op[16-1:0], abi);  // 16-bit C standard extension
    4      : disasm = disasm32(isa, op[32-1:0], abi);  // 32-bit
    default: disasm = $sformatf("ILLEGAL: ILEN = %dB", opsiz(op[16-1:0]));
  endcase
endfunction: disasm

endpackage: riscv_asm_pkg
