////////////////////////////////////////////////////////////////////////////////
// RISC-V CSR package (based on privileged spec)
////////////////////////////////////////////////////////////////////////////////
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

package rv64_csr_pkg;

import riscv_isa_pkg::*;

localparam int unsigned  XLEN = 64;
localparam int unsigned MXLEN = XLEN;
localparam int unsigned SXLEN = XLEN;
localparam int unsigned UXLEN = XLEN;

typedef logic  [XLEN-1:0] logic_xlen_t;
typedef logic [MXLEN-1:0] logic_mxlen_t;
typedef logic [SXLEN-1:0] logic_sxlen_t;
typedef logic [UXLEN-1:0] logic_uxlen_t;

///////////////////////////////////////////////////////////////////////////////
// CSR address
///////////////////////////////////////////////////////////////////////////////

// NOTE: this is defined in riscv_isa_pkg

////////////////////////////////////////////////////////////////////////////////
// common definitions
////////////////////////////////////////////////////////////////////////////////

// XLEN enumeration
typedef enum logic [1:0] {
  XLEN_RES = 2'd0,  // XLEN = Reserved
  XLEN_32  = 2'd1,  // XLEN = 32
  XLEN_64  = 2'd2,  // XLEN = 64
  XLEN_128 = 2'd3   // XLEN = 128
} csr_xlen_et;

// endian mode
typedef enum logic {
  ENDIAN_LITTLE = 1'b0,  // little-endian
  ENDIAN_BIG    = 1'b1   // big-endian
} csr_endian_t;

// context status
typedef enum logic [1:0] { // FS meaning // XS Meaning
  CONTEXT_OFF     = 2'b00,  // Off       // All off
  CONTEXT_INITIAL = 2'b01,  // Initial   // None dirty or clean, some on
  CONTEXT_CLEAN   = 2'b10,  // Clean     // None dirty, some clean
  CONTEXT_DIRTY   = 2'b11   // Dirty     // Some dirty
} csr_context_t;

// Encoding of *tvec MODE field
typedef enum logic [1:0] {
  TVEC_MODE_DIRECT   = 2'b00,  // All exceptions set pc to BASE.
  TVEC_MODE_VECTORED = 2'b01,  // Asynchronous interrupts set pc to BASE+4×cause.
  TVEC_MODE_RES_2    = 2'b10,  // Reserved
  TVEC_MODE_RES_3    = 2'b11   // Machine
} csr_vector_t;

////////////////////////////////////////////////////////////////////////////////
// [Machine/Supervisor/Virtual Supervisor/Hypervisor]-Level CSRs
////////////////////////////////////////////////////////////////////////////////

// [Machine] ISA Register
typedef struct packed {
  csr_xlen_et        MXL       ;  // Machine XLEN
  logic [MXLEN-3:26] warl_xx_26;  // Reserved
  struct packed {
    logic Z;  // 25 // Reserved
    logic Y;  // 24 // Reserved
    logic X;  // 23 // Non-standard extensions present
    logic W;  // 22 // Reserved
    logic V;  // 21 // Tentatively reserved for Vector extension
    logic U;  // 20 // User mode implemented
    logic T;  // 19 // Tentatively reserved for Transactional Memory extension
    logic S;  // 18 // Supervisor mode implemented
    logic R;  // 17 // Reserved
    logic Q;  // 16 // Quad-precision floating-point extension
    logic P;  // 15 // Tentatively reserved for Packed-SIMD extension
    logic O;  // 14 // Reserved
    logic N;  // 13 // User-level interrupts supported
    logic M;  // 12 // Integer Multiply/Divide extension
    logic L;  // 11 // Tentatively reserved for Decimal Floating-Point extension
    logic K;  // 10 // Reserved
    logic J;  //  9 // Tentatively reserved for Dynamically Translated Languages extension
    logic I;  //  8 // RV32I/64I/128I base ISA
    logic H;  //  7 // Hypervisor extension
    logic G;  //  6 // Reserved
    logic F;  //  5 // Single-precision floating-point extension
    logic E;  //  4 // RV32E base ISA
    logic D;  //  3 // Double-precision floating-point extension
    logic C;  //  2 // Compressed extension
    logic B;  //  1 // Tentatively reserved for Bit-Manipulation extension
    logic A;  //  0 // Atomic extension
  } Extensions;
} csr_isa_t;

function automatic csr_isa_t csr_isa_f (isa_t isa);
  // base ISA
  case (isa.spec.base)
    RV_32E : csr_isa_f.MXL = XLEN_32;
    RV_32I : csr_isa_f.MXL = XLEN_32;
    RV_64I : csr_isa_f.MXL = XLEN_64;
    RV_128I: csr_isa_f.MXL = XLEN_128;
    default: csr_isa_f.MXL = XLEN_RES;
  endcase
  // extensions
  begin
  //csr_isa_f.Extensions.Z = isa.spec.ext.Z;
  //csr_isa_f.Extensions.Y = isa.spec.ext.Y;
  //csr_isa_f.Extensions.X = isa.spec.ext.X;
  //csr_isa_f.Extensions.W = isa.spec.ext.W;
    csr_isa_f.Extensions.V = isa.spec.ext.V;
    csr_isa_f.Extensions.U = isa.priv.U;
    csr_isa_f.Extensions.T = isa.spec.ext.T;
    csr_isa_f.Extensions.S = isa.spec.ext.S;
  //csr_isa_f.Extensions.R = isa.spec.ext.R;
    csr_isa_f.Extensions.Q = isa.spec.ext.Q;
    csr_isa_f.Extensions.P = isa.spec.ext.P;
  //csr_isa_f.Extensions.O = isa.spec.ext.O;
    csr_isa_f.Extensions.N = isa.spec.ext.N;
    csr_isa_f.Extensions.M = isa.spec.ext.M;
    csr_isa_f.Extensions.L = isa.spec.ext.L;
  //csr_isa_f.Extensions.K = isa.spec.ext.K;
    csr_isa_f.Extensions.J = isa.spec.ext.J;
    csr_isa_f.Extensions.I = '1;
    csr_isa_f.Extensions.H = isa.spec.ext.H;
  //csr_isa_f.Extensions.G = isa.spec.ext.G;
    csr_isa_f.Extensions.F = isa.spec.ext.F;
    csr_isa_f.Extensions.E = isa.spec.base.E;
    csr_isa_f.Extensions.D = isa.spec.ext.D;
    csr_isa_f.Extensions.C = isa.spec.ext.C;
    csr_isa_f.Extensions.B = isa.spec.ext.B;
    csr_isa_f.Extensions.A = isa.spec.ext.A;
  end
endfunction: csr_isa_f

// [Machine] Vendor ID Register
typedef struct packed {
  logic [MXLEN-1:32] zero;    // **:32 //
  logic    [32-1:07] Bank;    // 31:07 //
  logic    [   6:00] Offset;  // 06:00 //
} csr_vendorid_t;

// [Machine] Architecture ID Register
typedef struct packed {
  logic [MXLEN-1:0] Architecture_ID;  // MSB is 1'b0 for open source projects
} csr_archid_t;

// [Machine] Implementation ID Register
typedef struct packed {
  logic [MXLEN-1:0] Implementation_ID;
} csr_impid_t;

// [Machine] Hart ID Register
typedef struct packed {
  logic [MXLEN-1:0] Hart_ID;  //
} csr_hartid_t;

// [Machine] Status Register
typedef struct packed {
  logic         SD        ;  // 63    // SD=((FS==11) OR (XS==11)))
  logic [62:38] wpri_62_38;  // 62:38 //
  // Endianness Control
  csr_endian_t  MBE       ;  // 37    // M-mode endianness
  csr_endian_t  SBE       ;  // 36    // S-mode endianness
  // Base ISA Control
  csr_xlen_et   SXL       ;  // 35:34 // S-mode XLEN
  csr_xlen_et   UXL       ;  // 33:32 // U-mode XLEN
  logic [31:23] wpri_31_23;  // 31:23 //
  // Virtualization Support
  logic         TSR       ;  // 22    // Trap SRET
  logic         TW        ;  // 21    // Timeout Wait
  logic         TVM       ;  // 20    // Trap Virtual Memory
  // Memory Privilige
  logic         MXR       ;  // 19    // Make eXecutable Readable
  logic         SUM       ;  // 18    // permit Supervisor User Memory access
  logic         MPRV      ;  // 17    // Modify PRiVilege
  // Extension Context Status
  csr_context_t XS        ;  // 16:15 // user-mode extensions context status
  csr_context_t FS        ;  // 14:13 // floating-point context status
  // Privilege and Global Interrupt-Enable Stack
  isa_level_t   MPP       ;  // 12:11 // machine previous privilege mode
  logic [10:09] wpri_10_09;  // 10: 9 //
  logic         SPP       ;  //  8    // supervisor previous privilege mode
  logic         MPIE      ;  //  7    // machine interrupt-enable active prior to the trap
  csr_endian_t  UBE       ;  //  6    // U-mode endianness
  logic         SPIE      ;  //  5    // supervisor interrupt-enable active prior to the trap
  logic [04:04] wpri_04_04;  //  4    //
  logic         MIE       ;  //  3    // machine global interrupt-enable
  logic [02:02] wpri_02_02;  //  2    //
  logic         SIE       ;  //  1    // supervisor global interrupt-enable
  logic [00:00] wpri_00_00;  //  0    //
} csr_status_t;

// [Machine/Supervisor] Trap-Vector Base-Address Register
typedef struct packed {
  logic [XLEN-1:2] BASE;  // **: 2 // vector base address
  csr_vector_t     MODE;  //  1: 0 // vector mode
} csr_tvec_t;

// [Machine/Supervisor/Hypervisor] Exception Delegation Register
typedef struct packed {
  logic [XLEN-1:0] Synchronous_Exceptions;
} csr_edeleg_t;

// [Machine/Supervisor/Hypervisor] Interrupt Delegation Register
typedef struct packed {
  logic [XLEN-1:0] Interrupts;
} csr_ideleg_t;

// Machine Interrupt-Pending Register
typedef struct packed {
  logic [MXLEN-1:16] Interrupts;  // **:16 //
  logic      [15:12] zero_15_12;  // 15:12 //
  logic              MEIP      ;  // 11    // machine-level external interrupt
  logic      [10:10] zero_10_10;  // 10    //
  logic              SEIP      ;  //  9    // supervisor-level external interrupt
  logic      [08:08] zero_08_08;  //  8    //
  logic              MTIP      ;  //  7    // machine-level timer interrupt
  logic      [06:06] zero_06_06;  //  6    //
  logic              STIP      ;  //  5    // supervisor-level timer interrupt
  logic      [04:04] zero_04_04;  //  4    //
  logic              MSIP      ;  //  3    // machine-level software interrupt
  logic      [02:02] zero_02_02;  //  2    //
  logic              SSIP      ;  //  1    // supervisor-level software interrupt
  logic      [00:00] zero_00_00;  //  0    //
} csr_mip_t;

// Supervisor Interrupt Pending Register
typedef struct packed {
  logic [SXLEN-1:16] Interrupts;  // **:16 //
  logic      [15:10] zero_15_10;  // 15:12 //
  logic              SEIP      ;  //  9    // supervisor-level external interrupt
  logic      [08:06] zero_08_06;  //  8    //
  logic              STIP      ;  //  5    // supervisor-level timer interrupt
  logic      [04:02] zero_04_02;  //  4    //
  logic              SSIP      ;  //  1    // supervisor-level software interrupt
  logic      [00:00] zero_00_00;  //  0    //
} csr_sip_t;

// Machine Interrupt-Enable Register
typedef struct packed {
  logic [MXLEN-1:16] Interrupts;  // **:16 //
  logic      [15:12] zero_15_12;  // 15:12 //
  logic              MEIE      ;  // 11    // machine-level external interrupt
  logic      [10:10] zero_10_10;  // 10    //
  logic              SEIE      ;  //  9    // supervisor-level external interrupt
  logic      [08:08] zero_08_08;  //  8    //
  logic              MTIE      ;  //  7    // machine-level timer interrupt
  logic      [06:06] zero_06_06;  //  6    //
  logic              STIE      ;  //  5    // supervisor-level timer interrupt
  logic      [04:04] zero_04_04;  //  4    //
  logic              MSIE      ;  //  3    // machine-level software interrupt
  logic      [02:02] zero_02_02;  //  2    //
  logic              SSIE      ;  //  1    // supervisor-level software interrupt
  logic      [00:00] zero_00_00;  //  0    //
} csr_mie_t;

// Supervisor Interrupt Pending Register
typedef struct packed {
  logic [SXLEN-1:16] Interrupts;  // **:16 //
  logic      [15:10] zero_15_10;  // 15:12 //
  logic              SEIE      ;  //  9    // supervisor-level external interrupt
  logic      [08:06] zero_08_06;  //  8    //
  logic              STIE      ;  //  5    // supervisor-level timer interrupt
  logic      [04:02] zero_04_02;  //  4    //
  logic              SSIE      ;  //  1    // supervisor-level software interrupt
  logic      [00:00] zero_00_00;  //  0    //
} csr_sie_t;

// [Machine/User] Hardware Performance Monitor
typedef logic [XLEN-1:0] csr_hpmcounter_t;
typedef logic [XLEN-1:0] csr_hpmevent_t;

// [Machine/Supervisor/Hypervisor] Counter-Enable Register
typedef struct packed {
  logic [XLEN-1:32] zero_63_32;  // **:32 //
  logic     [31:03] HPM       ;  // 31:03 // hpmcounter[*]
  logic             IR        ;  //  2    // instret
  logic             TM        ;  //  1    // time
  logic             CY        ;  //  0    // cycle
} csr_counteren_t;

// [Machine] Counter-Inhibit Register
typedef struct packed {
  logic [XLEN-1:32] zero_63_32;  // **:32 //
  logic     [31:03] HPM       ;  // 31:03 // hpmcounter[*]
  logic             IR        ;  //  2    // instret
  logic             zero_01_01;  //  1    // time (always 1'b0)
  logic             CY        ;  //  0    // cycle
} csr_countinhibit_t;

// [Machine/Supervisor/Virtual Supervisor] Scratch Register
typedef struct packed {
  logic [MXLEN-1:0] scratch;  //
} csr_scratch_t;

// [Machine/Supervisor/Virtual Supervisor] Exception Program Counter
typedef struct packed {
  logic [MXLEN-1:1] epc       ;  //
  logic             zero_00_00;  // always 1'b0
} csr_epc_t;
// NOTE: if IALIGN=32, then 2 LSB bits are 1'b0

// [Machine/Supervisor/Virtual Supervisor] Cause Register
typedef struct packed {
  logic             Interrupt     ;  // set if the trap was caused by an interrupt
  logic [MXLEN-2:0] Exception_Code;  // code identifying the last exception or interrupt
} csr_cause_t;

// Cause register (csr_cause_t) values after trap
typedef enum logic [$bits(csr_cause_t)-1:0] {
  // Interrupts
  CAUSE_IRQ_RSV_0            = {1'b1, (MXLEN-1-6)'(0), 6'd00},  // Reserved
  CAUSE_IRQ_SW_S             = {1'b1, (MXLEN-1-6)'(0), 6'd01},  // Supervisor software interrupt
  CAUSE_IRQ_RSV_2            = {1'b1, (MXLEN-1-6)'(0), 6'd02},  // Reserved
  CAUSE_IRQ_SW_M             = {1'b1, (MXLEN-1-6)'(0), 6'd03},  // Machine software interrupt
  CAUSE_IRQ_RSV_4            = {1'b1, (MXLEN-1-6)'(0), 6'd04},  // Reserved
  CAUSE_IRQ_TM_S             = {1'b1, (MXLEN-1-6)'(0), 6'd05},  // Supervisor timer interrupt
  CAUSE_IRQ_RSV_6            = {1'b1, (MXLEN-1-6)'(0), 6'd06},  // Reserved
  CAUSE_IRQ_TM_M             = {1'b1, (MXLEN-1-6)'(0), 6'd07},  // Machine timer interrupt
  CAUSE_IRQ_RSV_8            = {1'b1, (MXLEN-1-6)'(0), 6'd08},  // Reserved
  CAUSE_IRQ_EXT_S            = {1'b1, (MXLEN-1-6)'(0), 6'd09},  // Supervisor external interrupt
  CAUSE_IRQ_RSV_10           = {1'b1, (MXLEN-1-6)'(0), 6'd10},  // Reserved
  CAUSE_IRQ_EXT_M            = {1'b1, (MXLEN-1-6)'(0), 6'd11},  // Machine external interrupt
  CAUSE_IRQ_RSV_12           = {1'b1, (MXLEN-1-6)'(0), 6'd12},  // Reserved
  CAUSE_IRQ_RSV_13           = {1'b1, (MXLEN-1-6)'(0), 6'd13},  // Reserved
  CAUSE_IRQ_RSV_14           = {1'b1, (MXLEN-1-6)'(0), 6'd14},  // Reserved
  CAUSE_IRQ_RSV_15           = {1'b1, (MXLEN-1-6)'(0), 6'd15},  // Reserved
//                             {1'b1, (MXLEN-1-6)'(0),  >=16},  // Designated for platform use
  // Exceptions
  CAUSE_EXC_IFU_MISALIGNED   = {1'b0, (MXLEN-1-6)'(0), 6'd00},  // Instruction address misaligned
  CAUSE_EXC_IFU_FAULT        = {1'b0, (MXLEN-1-6)'(0), 6'd01},  // Instruction access fault
  CAUSE_EXC_IFU_ILLEGAL      = {1'b0, (MXLEN-1-6)'(0), 6'd02},  // Illegal instruction
  CAUSE_EXC_OP_EBREAK        = {1'b0, (MXLEN-1-6)'(0), 6'd03},  // Breakpoint
  CAUSE_EXC_LOAD_MISALIGNED  = {1'b0, (MXLEN-1-6)'(0), 6'd04},  // Load address misaligned
  CAUSE_EXC_LOAD_FAULT       = {1'b0, (MXLEN-1-6)'(0), 6'd05},  // Load access fault
  CAUSE_EXC_STORE_MISALIGNED = {1'b0, (MXLEN-1-6)'(0), 6'd06},  // Store/AMO address misaligned
  CAUSE_EXC_STORE_FAULT      = {1'b0, (MXLEN-1-6)'(0), 6'd07},  // Store/AMO access fault
  CAUSE_EXC_OP_UCALL         = {1'b0, (MXLEN-1-6)'(0), 6'd08},  // Environment call from U-mode
  CAUSE_EXC_OP_SCALL         = {1'b0, (MXLEN-1-6)'(0), 6'd09},  // Environment call from S-mode
  CAUSE_EXC_OP_RSV           = {1'b0, (MXLEN-1-6)'(0), 6'd10},  // Reserved
  CAUSE_EXC_OP_MCALL         = {1'b0, (MXLEN-1-6)'(0), 6'd11},  // Environment call from M-mode
  CAUSE_EXC_MMU_INST_FAULT   = {1'b0, (MXLEN-1-6)'(0), 6'd12},  // Instruction page fault
  CAUSE_EXC_MMU_LOAD_FAULT   = {1'b0, (MXLEN-1-6)'(0), 6'd13},  // Load page fault
  CAUSE_EXC_MMU_RSV          = {1'b0, (MXLEN-1-6)'(0), 6'd14},  // Reserved
  CAUSE_EXC_MMU_STORE_FAULT  = {1'b0, (MXLEN-1-6)'(0), 6'd15}   // Store/AMO page fault
//CAUSE_EXC_16_23            = {1'b0, (MXLEN-1-6)'(0), 6'd??},  // Reserved
//CAUSE_EXC_24_31            = {1'b0, (MXLEN-1-6)'(0), 6'd??},  // Designated for custom use
//CAUSE_EXC_32_47            = {1'b0, (MXLEN-1-6)'(0), 6'd??},  // Reserved
//CAUSE_EXC_48_63            = {1'b0, (MXLEN-1-6)'(0), 6'd??},  // Designated for custom use
//CAUSE_EXC_**_64            = {1'b0, (MXLEN-1-6)'(0), 6'd??},  // Reserved
} csr_cause_et;

// [Machine/Supervisor/Virtual Supervisor/Hypervisor] Trap Value Register
typedef struct packed {
  logic [MXLEN-1:0] tval;  //
} csr_tval_t;

// Encoding of address matching mode field in PMP configuration registers
typedef enum logic [1:0] {
  PMP_A_OFF   = 2'd0,  // Null region (disabled)
  PMP_A_TOR   = 2'd1,  // Top of range
  PMP_A_NA4   = 2'd2,  // Naturally aligned four-byte region
  PMP_A_NAPOT = 2'd3   // Naturally aligned power-of-two region, ≥8 bytes
} csr_pmp_a_t;

// PMP configuration register format
typedef struct packed {
  logic       L;         // 7   // 
  logic [1:0] zero_6_5;  // 6:5 // instruction execution
  csr_pmp_a_t A;         // 4:3 // instruction execution  
  logic       X;         // 2   // instruction execution
  logic       W;         // 1   // write
  logic       R;         // 0   // read
} csr_pmp_cfg_t;

///////////////////////////////////////////////////////////////////////////////
// CSR address map
///////////////////////////////////////////////////////////////////////////////

// SCR address map structure
// verilator lint_off LITENDIAN
typedef struct packed {
  logic_xlen_t       [12'h000:12'h000] res_000_000  ;
  logic_xlen_t                         fflafs       ;  // 0x001       // Floating-Point Accrued Exceptions.
  logic_xlen_t                         frm          ;  // 0x002       // Floating-Point Dynamic Rounding Mode.
  logic_xlen_t                         fcsr         ;  // 0x003       // Floating-Point Control and Status Register (frm + fflags).
  logic_xlen_t       [12'h004:12'h0ff] res_004_0ff  ;
  logic_xlen_t                         sstatus      ;  // 0x100       // Supervisor status register.
  logic_xlen_t       [12'h101:12'h101] res_101_101  ;
  csr_edeleg_t                         sedeleg      ;  // 0x102       // Supervisor exception delegation register.
  csr_ideleg_t                         sideleg      ;  // 0x103       // Supervisor interrupt delegation register.
  csr_sie_t                            sie          ;  // 0x104       // Supervisor interrupt-enable register.
  csr_tvec_t                           stvec        ;  // 0x105       // Supervisor trap handler base address.
  csr_counteren_t                      scounteren   ;  // 0x106       // Supervisor counter enable.
  logic_xlen_t       [12'h107:12'h13f] res_107_13f  ;
  csr_scratch_t                        sscratch     ;  // 0x140       // Supervisor scratch register for supervisor trap handlers.
  csr_epc_t                                       sepc         ;  // 0x141       // Supervisor exception program counter.
  csr_cause_t                                     scause       ;  // 0x142       // Supervisor trap cause.
  csr_tval_t                           stval        ;  // 0x143       // Supervisor bad address or instruction.
  logic_xlen_t                         sip          ;  // 0x144       // Supervisor interrupt pending.
  logic_xlen_t       [12'h145:12'h17f] res_145_17f  ;
  logic_xlen_t                         satp         ;  // 0x180       // Supervisor address translation and protection.
  logic_xlen_t       [12'h181:12'h1ff] res_181_1ff  ;
  logic_xlen_t                         vsstatus     ;  // 0x200       // Virtual supervisor status register.
  logic_xlen_t       [12'h201:12'h203] res_201_203  ;
  csr_sie_t                            vsie         ;  // 0x204       // Virtual supervisor interrupt-enable register.
  csr_tvec_t                           vstvec       ;  // 0x205       // Virtual supervisor trap handler base address.
  logic_xlen_t       [12'h206:12'h23f] res_206_23f  ;
  csr_scratch_t                        vsscratch    ;  // 0x240       // Virtual supervisor scratch register.
  csr_epc_t                            vsepc        ;  // 0x241       // Virtual supervisor exception program counter.
  csr_cause_t                          vscause      ;  // 0x242       // Virtual supervisor trap cause.
  csr_tval_t                           vstval       ;  // 0x243       // Virtual supervisor bad address or instruction.
  logic_xlen_t                         vsip         ;  // 0x244       // Virtual supervisor interrupt pending.
  logic_xlen_t       [12'h245:12'h27f] res_245_27f  ;
  logic_xlen_t                         vsatp        ;  // 0x280       // Virtual supervisor address translation and protection.
  logic_xlen_t       [12'h281:12'h2ff] res_281_2ff  ;
  csr_status_t                         mstatus      ;  // 0x300       // Machine status register.
  csr_isa_t                            misa         ;  // 0x301       // ISA and extensions
  csr_edeleg_t                         medeleg      ;  // 0x302       // Machine exception delegation register.
  csr_ideleg_t                         mideleg      ;  // 0x303       // Machine interrupt delegation register.
  csr_mie_t                            mie          ;  // 0x304       // Machine interrupt-enable register.
  csr_tvec_t                           mtvec        ;  // 0x305       // Machine trap-handler base address.
  csr_counteren_t                      mcounteren   ;  // 0x306       // Machine counter enable.
  logic_xlen_t       [12'h307:12'h31f] res_307_31f  ;
  csr_countinhibit_t                   mcountinhibit;  // 0x320       // Machine counter-inhibit register.
  logic_xlen_t       [12'h321:12'h322] res_321_322  ;
  csr_hpmevent_t     [12'h003:12'h01f] mhpmevent    ;  // 0x323:0x33F // Machine performance-monitoring event selector.
  csr_scratch_t                        mscratch     ;  // 0x340       // Machine scratch register for machine trap handlers.
  csr_epc_t                            mepc         ;  // 0x341       // Machine exception program counter.
  csr_cause_t                          mcause       ;  // 0x342       // Machine trap cause.
  csr_tval_t                           mtval        ;  // 0x343       // Machine bad address or instruction.
  csr_mip_t                            mip          ;  // 0x344       // Machine interrupt pending.
  logic_xlen_t       [12'h345:12'h349] res_345_349  ;
  logic_xlen_t                         mtinst       ;  // 0x34A       // Machine trap instruction (transformed).
  csr_tval_t                           mtval2       ;  // 0x34B       // Machine bad guest physical address.
  logic_xlen_t       [12'h34c:12'h39f] res_34c_39f  ;
  logic_xlen_t       [12'h000:12'h00f] pmpcfg       ;  // 0x3A0:0x3AF // Physical memory protection configuration. (the odd ones are RV32 only)
  logic_xlen_t       [12'h000:12'h03f] pmpaddr      ;  // 0x3B0:0x3EF // Physical memory protection address register.
  logic_xlen_t       [12'h3f0:12'h5a7] res_3f0_5a7  ;
  logic_xlen_t                         scontext     ;  // 0x5A8       // Supervisor-mode context register.
  logic_xlen_t       [12'h5a9:12'h5ff] res_5a9_5ff  ;
  logic_xlen_t                         hstatus      ;  // 0x600       // Hypervisor status register.
  logic_xlen_t       [12'h601:12'h601] res_601_601  ;
  csr_edeleg_t                         hedeleg      ;  // 0x602       // Hypervisor exception delegation register.
  csr_ideleg_t                         hideleg      ;  // 0x603       // Hypervisor interrupt delegation register.
  logic_xlen_t                         hie          ;  // 0x604       // Hypervisor interrupt-enable register.
  logic_xlen_t                         htimedelta   ;  // 0x605       // Delta for VS/VU-mode timer.
  csr_counteren_t                      hcounteren   ;  // 0x606       // Hypervisor counter enable.
  logic_xlen_t                         htvec        ;  // 0x607       // Hypervisor guest external interrupt-enable register.
  logic_xlen_t       [12'h608:12'h642] res_608_642  ;
  csr_tval_t                           htval        ;  // 0x643       // Hypervisor bad guest physical address.
  logic_xlen_t                         hip          ;  // 0x644       // Hypervisor interrupt pending.
  logic_xlen_t                         hvip         ;  // 0x645       // Hypervisor virtual interrupt pending.
  logic_xlen_t       [12'h646:12'h649] res_646_649  ;
  logic_xlen_t                         htinst       ;  // 0x64A       // Hypervisor trap instruction (transformed).
  logic_xlen_t       [12'h64b:12'h67f] res_64b_67f  ;
  logic_xlen_t                         hgatp        ;  // 0x680       // Hypervisor guest address translation and protection.
  logic_xlen_t       [12'h681:12'h6a7] res_681_6a7  ;
  logic_xlen_t                         hcontext     ;  // 0x6A8       // Hypervisor-mode context register.
  logic_xlen_t       [12'h6a9:12'h79f] res_6a9_79f  ;
  logic_xlen_t                         tselect      ;  // 0x7A0       // Debug/Trace trigger register select.
  logic_xlen_t                         tdata1       ;  // 0x7A1       // First Debug/Trace trigger data register.
  logic_xlen_t                         tdata2       ;  // 0x7A2       // Second Debug/Trace trigger data register.
  logic_xlen_t                         tdata3       ;  // 0x7A3       // Third Debug/Trace trigger data register.
  logic_xlen_t       [12'h7a4:12'h7a7] res_7a4_7a7  ;
  logic_xlen_t                         mcontext     ;  // 0x7A8       // Machine-mode context register.
  logic_xlen_t       [12'h7a9:12'h7af] res_7a9_7af  ;
  logic_xlen_t                         dcsr         ;  // 0x7B0       // Debug control and status register.
  logic_xlen_t                         dpc          ;  // 0x7B1       // Debug PC.
  logic_xlen_t                         dscratch0    ;  // 0x7B2       // Debug scratch register 0.
  logic_xlen_t                         dscratch1    ;  // 0x7B3       // Debug scratch register 1.
  logic_xlen_t       [12'h7b4:12'haff] res_7b4_aff  ;
  logic_xlen_t                         mcycle       ;  // 0xB00       // Machine cycle counter.
  logic_xlen_t       [12'hb01:12'hb01] res_b01_b01  ;
  logic_xlen_t                         minstret     ;  // 0xB02       // Machine instructions-retired counter.
  csr_hpmcounter_t   [12'h003:12'h01f] mhpmcounter  ;  // 0xB03:0xB1F // Machine performance-monitoring counter. (3~31)
  logic_xlen_t       [12'hb20:12'hbff] res_b20_bff  ;
  logic_xlen_t                         cycle        ;  // 0xC00       // Cycle counter for RDCYCLE instruction.
  logic_xlen_t                         time_        ;  // 0xC01       // Timer for RDTIME instruction.
  logic_xlen_t                         instret      ;  // 0xC02       // Instructions-retired counter for RDINSTRET instruction.
  csr_hpmcounter_t   [12'h003:12'h01f] hpmcounter   ;  // 0xC03:0xC1F // Performance-monitoring counter. (3~31)
  logic_xlen_t       [12'hc20:12'he11] res_c20_e11  ;
  logic_xlen_t                         hgeip        ;  // 0xE12       // Hypervisor guest external interrupt pending.
  logic_xlen_t       [12'he13:12'hf10] res_e13_f10  ;
  csr_vendorid_t                       mvendorid    ;  // 0xF11       // Vendor ID.
  csr_archid_t                         marchid      ;  // 0xF12       // Architecture ID.
  csr_impid_t                          mimpid       ;  // 0xF13       // Implementation ID.
  csr_hartid_t                         mhartid      ;  // 0xF14       // Hardware thread ID.
  logic_xlen_t       [12'hf15:12'hfff] res_f15_fff  ;
} csr_map_st;
// verilator lint_on LITENDIAN

// SCR address map array
// verilator lint_off LITENDIAN
typedef logic [12'h000:12'hfff][XLEN-1:0] csr_map_at;
// verilator lint_on LITENDIAN

// SCR address map union
typedef union packed {
  csr_map_st s;  // structure
  csr_map_at a;  // array
} csr_map_ut;

///////////////////////////////////////////////////////////////////////////////
// Access types
///////////////////////////////////////////////////////////////////////////////

// 4-state data type is used to encode access types
`define WPRI 'x  // x - (WPRI) Reserved Writes Preserve Values, Reads Ignore Values (should be wired to 0)
`define WLRL '1  // 1 - (WLRL) Write/Read Only Legal Values
`define WARL 'z  // z - (WARL) Write Any Values, Reads Legal Values (?)
`define WERE '0  // 0 - (WERE) Write Error, Read Error (NOTE: not a name from the specification)
                 //            non-existent CSR, access shall raise an illegal instruction exception

/*
localparam csr_map_st CSR_MAP_WR = '{
  // 0x300       // Machine status register.
  mstatus    : '{
    SD         :                `WARL ,  // 63    // SD=((FS==11) OR (XS==11)))
    wpri_62_38 :                `WPRI ,  // 62:38 //
    // Endianness Control
    MBE        : csr_endian_t '(`WLRL),  // 37    // M-mode endianness
    SBE        : csr_endian_t '(`WLRL),  // 36    // S-mode endianness
    // Base ISA Control
    SXL        : csr_xlen_et  '(`WLRL),  // 35:34 // S-mode XLEN
    UXL        : csr_xlen_et  '(`WLRL),  // 33:32 // U-mode XLEN
    wpri_31_23 :                `WPRI ,  // 31:23 //
    // Virtualization Support
    TSR        :                `WLRL ,  // 22    // Trap SRET
    TW         :                `WLRL ,  // 21    // Timeout Wait
    TVM        :                `WLRL ,  // 20    // Trap Virtual Memory
    // Memory Privilige
    MXR        :                `WLRL ,  // 19    // Make eXecutable Readable
    SUM        :                `WLRL ,  // 18    // permit Supervisor User Memory access
    MPRV       :                `WLRL ,  // 17    // Modify PRiVilege
    // Extension Context Status
    XS         : csr_context_t'(`WLRL),  // 16:15 // user-mode extensions context status
    FS         : csr_context_t'(`WLRL),  // 14:13 // floating-point context status
    // Privilege and Global Interrupt-Enable Stack
    MPP        : isa_level_t  '(`WLRL),  // 12:11 // machine previous privilege mode
    wpri_10_09 :                `WPRI ,  // 10: 9 //
    SPP        :                `WLRL ,  //  8    // supervisor previous privilege mode
    MPIE       :                `WLRL ,  //  7    // machine interrupt-enable active prior to the trap
    UBE        : csr_endian_t '(`WLRL),  //  6    // U-mode endianness
    SPIE       :                `WLRL ,  //  5    // supervisor interrupt-enable active prior to the trap
    wpri_04_04 :                `WPRI ,  //  4    //
    MIE        :                `WLRL ,  //  3    // machine global interrupt-enable
    wpri_02_02 :                `WPRI ,  //  2    //
    SIE        :                `WLRL ,  //  1    // supervisor global interrupt-enable
    wpri_00_00 :                `WPRI    //  0    //
  },
  // 0x301       // ISA and extensions
  misa       : '{
    MXL        : csr_xlen_et  '(`WARL),  // Machine XLEN
    warl_xx_26 :                `WARL ,  // Reserved
    Extensions : '{
      Z : `WARL,  // 25 // Reserved
      Y : `WARL,  // 24 // Reserved
      X : `WARL,  // 23 // Non-standard extensions present
      W : `WARL,  // 22 // Reserved
      V : `WARL,  // 21 // Tentatively reserved for Vector extension
      U : `WARL,  // 20 // User mode implemented
      T : `WARL,  // 19 // Tentatively reserved for Transactional Memory extension
      S : `WARL,  // 18 // Supervisor mode implemented
      R : `WARL,  // 17 // Reserved
      Q : `WARL,  // 16 // Quad-precision floating-point extension
      P : `WARL,  // 15 // Tentatively reserved for Packed-SIMD extension
      O : `WARL,  // 14 // Reserved
      N : `WARL,  // 13 // User-level interrupts supported
      M : `WARL,  // 12 // Integer Multiply/Divide extension
      L : `WARL,  // 11 // Tentatively reserved for Decimal Floating-Point extension
      K : `WARL,  // 10 // Reserved
      J : `WARL,  //  9 // Tentatively reserved for Dynamically Translated Languages extension
      I : `WARL,  //  8 // RV32I/64I/128I base ISA
      H : `WARL,  //  7 // Hypervisor extension
      G : `WARL,  //  6 // Reserved
      F : `WARL,  //  5 // Single-precision floating-point extension
      E : `WARL,  //  4 // RV32E base ISA
      D : `WARL,  //  3 // Double-precision floating-point extension
      C : `WARL,  //  2 // Compressed extension
      B : `WARL,  //  1 // Tentatively reserved for Bit-Manipulation extension
      A : `WARL   //  0 // Atomic extension
    }
  },
  // 0x304       // Machine interrupt-enable register.
  mie        : '{
    Interrupts : `WARL,  // **:16 //
    zero_15_12 : `WARL,  // 15:12 //
    MEIE       : `WARL,  // 11    // machine-level external interrupt
    zero_10_10 : `WARL,  // 10    //
    SEIE       : `WARL,  //  9    // supervisor-level external interrupt
    zero_08_08 : `WARL,  //  8    //
    MTIE       : `WARL,  //  7    // machine-level timer interrupt
    zero_06_06 : `WARL,  //  6    //
    STIE       : `WARL,  //  5    // supervisor-level timer interrupt
    zero_04_04 : `WARL,  //  4    //
    MSIE       : `WARL,  //  3    // machine-level software interrupt
    zero_02_02 : `WARL,  //  2    //
    SSIE       : `WARL,  //  1    // supervisor-level software interrupt
    zero_00_00 : `WARL   //  0    //
  },
  // 0x305       // Machine trap-handler base address.
  mtvec      : '{
    BASE :               `WARL ,  // **: 2 // vector base address
    MODE : csr_vector_t'(`WARL)   //  1: 0 // vector mode
  },
  // 0x306       // Machine counter enable.
  mcounteren : '{
    zero_63_32 : `WPRI,  // **:32 //
    HPM        : `WARL,  // 31:03 // hpmcounter[*]
    IR         : `WARL,  //  2    // instret
    TM         : `WARL,  //  1    // time
    CY         : `WARL   //  0    // cycle
  },
  // 0x320       // Machine counter-inhibit register.
  mcountinhibit : '{
    zero_63_32 : `WPRI,  // **:32 //
    HPM        : `WARL,  // 31:03 // hpmcounter[*]
    IR         : `WARL,  //  2    // instret
    zero_01_01 : `WARL,  //  1    // time (always 1'b0)
    CY         : `WARL   //  0    // cycle
  },
  // 0x340       // Scratch register for machine trap handlers.
  mscratch   : '{
    scratch : `WLRL   //
  },
  // 0x341       // Machine exception program counter.
  mepc       : '{
    epc        : `WARL,  // exception program counter
    zero_00_00 : `WARL   // always '0
  },
  // 0x342       // Machine trap cause.
  mcause     : '{
    Interrupt      : `WLRL,  // set if the trap was caused by an interrupt
    Exception_Code : `WLRL   // code identifying the last exception or interrupt
  },
  // 0x343       // Machine bad address or instruction.
  mtval      : '{
    mtval : `WARL
  },
  // 0x344       // Machine interrupt pending.
  mip        : '{
    Interrupts : `WARL,  // **:16 //
    zero_15_12 : `WARL,  // 15:12 //
    MEIP       : `WARL,  // 11    // machine-level external interrupt
    zero_10_10 : `WARL,  // 10    //
    SEIP       : `WARL,  //  9    // supervisor-level external interrupt
    zero_08_08 : `WARL,  //  8    //
    MTIP       : `WARL,  //  7    // machine-level timer interrupt
    zero_06_06 : `WARL,  //  6    //
    STIP       : `WARL,  //  5    // supervisor-level timer interrupt
    zero_04_04 : `WARL,  //  4    //
    MSIP       : `WARL,  //  3    // machine-level software interrupt
    zero_02_02 : `WARL,  //  2    //
    SSIP       : `WARL,  //  1    // supervisor-level software interrupt
    zero_00_00 : `WARL   //  0    //
  },
  // verilator lint_off WIDTHCONCAT
  // TODO
  default    : '0
  // verilator lint_on WIDTHCONCAT
};
*/

///////////////////////////////////////////////////////////////////////////////
// CSR address decoder enumeration
///////////////////////////////////////////////////////////////////////////////

typedef enum bit [12-1:0] {
  csr__res           [12'h000:12'h000] = 12'h000,
  csr__fflafs                          = 12'h001,  // Floating-Point Accrued Exceptions.
  csr__frm                             = 12'h002,  // Floating-Point Dynamic Rounding Mode.
  csr__fcsr                            = 12'h003,  // Floating-Point Control and Status Register (frm + fflags).
  csr__res           [12'h004:12'h0ff] = 12'h004,
  csr__sstatus                         = 12'h100,  // Supervisor status register.
  csr__res           [12'h101:12'h101] = 12'h101,
  csr__sedeleg                         = 12'h102,  // Supervisor exception delegation register.
  csr__sideleg                         = 12'h103,  // Supervisor interrupt delegation register.
  csr__sie                             = 12'h104,  // Supervisor interrupt-enable register.
  csr__stvec                           = 12'h105,  // Supervisor trap handler base address.
  csr__scounteren                      = 12'h106,  // Supervisor counter enable.
  csr__res           [12'h107:12'h13f] = 12'h107,
  csr__sscratch                        = 12'h140,  // Scratch register for supervisor trap handlers.
  csr__sepc                            = 12'h141,  // Supervisor exception program counter.
  csr__scause                          = 12'h142,  // Supervisor trap cause.
  csr__stval                           = 12'h143,  // Supervisor bad address or instruction.
  csr__sip                             = 12'h144,  // Supervisor interrupt pending.
  csr__res           [12'h145:12'h17f] = 12'h145,
  csr__satp                            = 12'h180,  // Supervisor address translation and protection.
  csr__res           [12'h181:12'h1ff] = 12'h181,
  csr__vsstatus                        = 12'h200,  // Virtual supervisor status register.
  csr__res           [12'h201:12'h203] = 12'h201,
  csr__vsie                            = 12'h204,  // Virtual supervisor interrupt-enable register.
  csr__vstvec                          = 12'h205,  // Virtual supervisor trap handler base address.
  csr__res           [12'h206:12'h23f] = 12'h206,
  csr__vsscratch                       = 12'h240,  // Virtual supervisor scratch register.
  csr__vsepc                           = 12'h241,  // Virtual supervisor exception program counter.
  csr__vscause                         = 12'h242,  // Virtual supervisor trap cause.
  csr__vstval                          = 12'h243,  // Virtual supervisor bad address or instruction.
  csr__vsip                            = 12'h244,  // Virtual supervisor interrupt pending.
  csr__res           [12'h245:12'h27f] = 12'h245,
  csr__vsatp                           = 12'h280,  // Virtual supervisor address translation and protection.
  csr__res           [12'h281:12'h2ff] = 12'h281,
  csr__mstatus                         = 12'h300,  // Machine status register.
  csr__misa                            = 12'h301,  // ISA and extensions
  csr__medeleg                         = 12'h302,  // Machine exception delegation register.
  csr__mideleg                         = 12'h303,  // Machine interrupt delegation register.
  csr__mie                             = 12'h304,  // Machine interrupt-enable register.
  csr__mtvec                           = 12'h305,  // Machine trap-handler base address.
  csr__mcounteren                      = 12'h306,  // Machine counter enable.
  csr__res           [12'h307:12'h31f] = 12'h307,
  csr__mcountinhibit                   = 12'h320,  // Machine counter-inhibit register.
  csr__res           [12'h321:12'h322] = 12'h321,
  csr__mhpmevent     [12'h003:12'h01f] = 12'h323,  // Machine performance-monitoring event selector.
  csr__mscratch                        = 12'h340,  // Scratch register for machine trap handlers.
  csr__mepc                            = 12'h341,  // Machine exception program counter.
  csr__mcause                          = 12'h342,  // Machine trap cause.
  csr__mtval                           = 12'h343,  // Machine bad address or instruction.
  csr__mip                             = 12'h344,  // Machine interrupt pending.
  csr__res           [12'h345:12'h349] = 12'h345,
  csr__mtinst                          = 12'h34a,  // Machine trap instruction (transformed).
  csr__mtval2                          = 12'h34b,  // Machine bad guest physical address.
  csr__res           [12'h34c:12'h39f] = 12'h34c,
  csr__pmpcfg        [12'h000:12'h00f] = 12'h3a0,  // Physical memory protection configuration. (the odd ones are RV32 only)
  csr__pmpaddr       [12'h000:12'h03f] = 12'h3b0,  // Physical memory protection address register.
  csr__res           [12'h3f0:12'h5a7] = 12'h3f0,
  csr__scontext                        = 12'h5a8,  // Supervisor-mode context register.
  csr__res           [12'h5a9:12'h5ff] = 12'h5a9,
  csr__hstatus                         = 12'h600,  // Hypervisor status register.
  csr__res           [12'h601:12'h601] = 12'h601,
  csr__hedeleg                         = 12'h602,  // Hypervisor exception delegation register.
  csr__hideleg                         = 12'h603,  // Hypervisor interrupt delegation register.
  csr__hie                             = 12'h604,  // Hypervisor interrupt-enable register.
  csr__htimedelta                      = 12'h605,  // Delta for VS/VU-mode timer.
  csr__hcounteren                      = 12'h606,  // Hypervisor counter enable.
  csr__htvec                           = 12'h607,  // Hypervisor guest external interrupt-enable register.
  csr__res           [12'h608:12'h614] = 12'h608,
  csr__htimedeltah                     = 12'h615,  // Upper 32 bits of htimedelta, RV32 only.
  csr__res           [12'h616:12'h642] = 12'h616,
  csr__htval                           = 12'h643,  // Hypervisor bad guest physical address.
  csr__hip                             = 12'h644,  // Hypervisor interrupt pending.
  csr__hvip                            = 12'h645,  // Hypervisor virtual interrupt pending.
  csr__res           [12'h646:12'h649] = 12'h646,
  csr__htinst                          = 12'h64a,  // Hypervisor trap instruction (transformed).
  csr__res           [12'h64b:12'h67f] = 12'h64b,
  csr__hgatp                           = 12'h680,  // Hypervisor guest address translation and protection.
  csr__res           [12'h681:12'h6a7] = 12'h681,
  csr__hcontext                        = 12'h6a8,  // Hypervisor-mode context register.
  csr__res           [12'h6a9:12'h79f] = 12'h6a9,
  csr__tselect                         = 12'h7a0,  // Debug/Trace trigger register select.
  csr__tdata1                          = 12'h7a1,  // First Debug/Trace trigger data register.
  csr__tdata2                          = 12'h7a2,  // Second Debug/Trace trigger data register.
  csr__tdata3                          = 12'h7a3,  // Third Debug/Trace trigger data register.
  csr__res           [12'h7a4:12'h7a7] = 12'h7a4,
  csr__mcontext                        = 12'h7a8,  // Machine-mode context register.
  csr__res           [12'h7a9:12'h7af] = 12'h7a9,
  csr__dcsr                            = 12'h7b0,  // Debug control and status register.
  csr__dpc                             = 12'h7b1,  // Debug PC.
  csr__dscratch0                       = 12'h7b2,  // Debug scratch register 0.
  csr__dscratch1                       = 12'h7b3,  // Debug scratch register 1.
  csr__res           [12'h7b4:12'haff] = 12'h7b4,
  csr__mcycle                          = 12'hb00,  // Machine cycle counter.
  csr__res           [12'hb01:12'hb01] = 12'hb01,
  csr__minstret                        = 12'hb02,  // Machine instructions-retired counter.
  csr__mhpmcounter   [12'h003:12'h01f] = 12'hb03,  // Machine performance-monitoring counter.
  csr__res           [12'hb20:12'hbff] = 12'hb20,
  csr__cycle                           = 12'hc00,  // Cycle counter for RDCYCLE instruction.
  csr__time_                           = 12'hc01,  // Timer for RDTIME instruction.
  csr__instret                         = 12'hc02,  // Instructions-retired counter for RDINSTRET instruction.
  csr__hpmcounter    [12'h003:12'h01f] = 12'hc03,  // Performance-monitoring counter. (3~31)
  csr__res           [12'hc20:12'he11] = 12'hc20,
  csr__hgeip                           = 12'he12,  // Hypervisor guest external interrupt pending.
  csr__res           [12'he13:12'hf10] = 12'he13,
  csr__mvendorid                       = 12'hf11,  // Vendor ID.
  csr__marchid                         = 12'hf12,  // Architecture ID.
  csr__mimpid                          = 12'hf13,  // Implementation ID.
  csr__mhartid                         = 12'hf14,  // Hardware thread ID.
  csr__res           [12'hf15:12'hfff] = 12'hf15
} csr_dec_t;

endpackage: rv64_csr_pkg
