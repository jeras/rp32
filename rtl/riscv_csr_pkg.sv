////////////////////////////////////////////////////////////////////////////////
// RISC-V CSR package
////////////////////////////////////////////////////////////////////////////////

package riscv_csr_pkg;

import riscv_isa_pkg::*;

localparam int unsigned  XLEN = 64;
localparam int unsigned MXLEN = XLEN;
localparam int unsigned SXLEN = XLEN;
localparam int unsigned UXLEN = XLEN;

///////////////////////////////////////////////////////////////////////////////
// CSR address
///////////////////////////////////////////////////////////////////////////////

// NOTE: this is defined in riscv_csr_pkg

////////////////////////////////////////////////////////////////////////////////
// Machine-Level CSRs
////////////////////////////////////////////////////////////////////////////////

// XLEN enumeration
typedef enum logic [1:0] {
  XLEN_RES = 2'd0,  // XLEN = Reserved
  XLEN_32  = 2'd1,  // XLEN = 32
  XLEN_64  = 2'd2,  // XLEN = 64
  XLEN_128 = 2'd3   // XLEN = 128
} csr_xlen_t;

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

// Machine ISA Register
typedef struct packed {
  csr_xlen_t         MXL       ;  // Machine XLEN
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
} csr_misa_t;

function csr_misa_t csr_misa_f (isa_t isa);
  // base ISA
  case (isa.spec.base)
    RV_32E : csr_misa_f.MXL = XLEN_32;
    RV_32I : csr_misa_f.MXL = XLEN_32;
    RV_64I : csr_misa_f.MXL = XLEN_64;
    RV_128I: csr_misa_f.MXL = XLEN_128;
    default: csr_misa_f.MXL = XLEN_RES;
  endcase
  // extensions
  begin
  //csr_misa_f.Extensions.Z = isa.spec.ext.Z;
  //csr_misa_f.Extensions.Y = isa.spec.ext.Y;
  //csr_misa_f.Extensions.X = isa.spec.ext.X;
  //csr_misa_f.Extensions.W = isa.spec.ext.W;
    csr_misa_f.Extensions.V = isa.spec.ext.V;
    csr_misa_f.Extensions.U = isa.priv.U;
    csr_misa_f.Extensions.T = isa.spec.ext.T;
    csr_misa_f.Extensions.S = isa.spec.ext.S;
  //csr_misa_f.Extensions.R = isa.spec.ext.R;
    csr_misa_f.Extensions.Q = isa.spec.ext.Q;
    csr_misa_f.Extensions.P = isa.spec.ext.P;
  //csr_misa_f.Extensions.O = isa.spec.ext.O;
    csr_misa_f.Extensions.N = isa.spec.ext.N;
    csr_misa_f.Extensions.M = isa.spec.ext.M;
    csr_misa_f.Extensions.L = isa.spec.ext.L;
  //csr_misa_f.Extensions.K = isa.spec.ext.K;
    csr_misa_f.Extensions.J = isa.spec.ext.J;
    csr_misa_f.Extensions.I = '1;
    csr_misa_f.Extensions.H = isa.spec.ext.H;
  //csr_misa_f.Extensions.G = isa.spec.ext.G;
    csr_misa_f.Extensions.F = isa.spec.ext.F;
    csr_misa_f.Extensions.E = isa.spec.base.E;
    csr_misa_f.Extensions.D = isa.spec.ext.D;
    csr_misa_f.Extensions.C = isa.spec.ext.C;
    csr_misa_f.Extensions.B = isa.spec.ext.B;
    csr_misa_f.Extensions.A = isa.spec.ext.A;
  end
endfunction: csr_misa_f

// Machine Vendor ID Register
typedef struct packed {
  logic [MXLEN-1:32] zero;    // **:32 //
  logic    [32-1:07] Bank;    // 31:07 //
  logic    [   6:00] Offset;  //
} csr_mvendorid_t;

// Machine Architecture ID Register
typedef struct packed {
  logic [MXLEN-1-1:0] Architecture_ID;  // MSB is 1'b0 for open source projects
} csr_marchid_t;

// Machine Implementation ID Register
typedef struct packed {
  logic [MXLEN-1-1:0] Implementation_ID;
} csr_mimpid_t;

// Hart ID Register
typedef struct packed {
  logic [MXLEN-1-1:0] Hart_ID;  //
} csr_mhartid_t;

// Machine Status Register
typedef struct packed {
  logic         SD        ;  // 63    // SD=((FS==11) OR (XS==11)))
  logic [62:38] wpri_62_38;  // 62:38 //
  // Endianness Control
  csr_endian_t  MBE       ;  // 37    // M-mode endianness
  csr_endian_t  SBE       ;  // 36    // S-mode endianness
  // Base ISA Control
  csr_xlen_t    SXL       ;  // 35:34 // S-mode XLEN
  csr_xlen_t    UXL       ;  // 33:32 // U-mode XLEN
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
} csr_mstatus_rv64_t;

// Machine Status Register (low)
typedef struct packed {
  logic         SD        ;  // 31    // SD=((FS==11) OR (XS==11)))
  logic [30:23] wpri_30_23;  // 20:23 //
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
} csr_mstatus_rv32_t;

// Machine Status Register (high)
typedef struct packed {
  logic [31:06] wpri_31_06;  // 31:06 //
  // Endianness Control
  csr_endian_t  MBE       ;  //  5    // M-mode endianness
  csr_endian_t  SBE       ;  //  4    // S-mode endianness
  logic [03:00] wpri_03_00;  //  3: 0 //
} csr_mstatush_rv32_t;

// Encoding of mtvec MODE field
typedef enum logic [1:0] {
  MODE_DIRECT   = 2'b00,  // All exceptions set pc to BASE.
  MODE_VECTORED = 2'b01,  // Asynchronous interrupts set pc to BASE+4×cause.
  MODE_RES_2    = 2'b10,  // Reserved
  MODE_RES_3    = 2'b11   // Machine
} csr_vector_t;

// Machine Trap-Vector Base-Address Register
typedef struct packed {
  logic [MXLEN-1:2] BASE;  // **: 2 // vector base address
  csr_vector_t      MODE;  //  1: 0 // vector mode
} csr_mtvec_t;

// Machine Exception Delegation Register 'medeleg'
typedef struct packed {
  logic [MXLEN-1:0] Synchronous_Exceptions;  //
} csr_medeleg_t;

// Machine Interrupt Delegation Register 'mideleg'
typedef struct packed {
  logic [MXLEN-1:0] Interrupts;  //
} csr_mideleg_t;

// Machine Interrupt Pending Register
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

// Machine Interrupt Pending Register
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

// Hardware Performance Monitor
typedef logic    [64-1:0] csr_mhpmcounter_t;
typedef logic [MXLEN-1:0] csr_mhpmevent_t;

// Machine Counter-Enable Register
typedef struct packed {
  logic [MXLEN-1:32] zero_63_32;  // **:32 //
  logic      [31:03] HPM       ;  // 31:03 // hpmcounter[*]
  logic              IR        ;  //  2    // instret
  logic              TM        ;  //  1    // time
  logic              CY        ;  //  0    // cycle
} csr_mcounteren_t;

// Machine Counter-Inhibit Register
typedef struct packed {
  logic [MXLEN-1:32] zero_63_32;  // **:32 //
  logic      [31:03] HPM       ;  // 31:03 // hpmcounter[*]
  logic              IR        ;  //  2    // instret
  logic              zero_01_01;  //  1    // time (always 1'b0)
  logic              CY        ;  //  0    // cycle
} csr_mcountinhibit_t;

// Machine Scratch Register
typedef struct packed {
  logic [MXLEN-1:0] scratch;  //
} csr_mscratch_t;

// Machine Exception Program Counter
typedef struct packed {
  logic [MXLEN-1:1] epc       ;  //
  logic             zero_00_00;  // always 1'b0
} csr_mepc_t;
// NOTE: if IALIGN=32, then 2 LSB bits are 1'b0

// Machine Cause Register
typedef struct packed {
  logic             Interrupt     ;  // set if the trap was caused by an interrupt
  logic [MXLEN-2:0] Exception_Code;  // code identifying the last exception or interrupt
} csr_mcause_t;

// Machine cause register (mcause) values after trap
typedef enum csr_mcause_t {
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
} csr_cause_t;

// Machine Trap Value Register
typedef struct packed {
  logic [MXLEN-1:0] mtval;  //
} csr_mtval_t;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/*
//
typedef struct packed {
  logic [] ;  //
} csr__t;
*/

///////////////////////////////////////////////////////////////////////////////
// address map
///////////////////////////////////////////////////////////////////////////////

/* verilator lint_off LITENDIAN */
// SCR address map structure
typedef struct packed {
  // User Trap Setup
  logic                   [XLEN-1:0] ustatus      ;  // 0x000       // User status register.
  // User Floating-Point CSRs
  logic                   [XLEN-1:0] fflafs       ;  // 0x001       // Floating-Point Accrued Exceptions.
  logic                   [XLEN-1:0] frm          ;  // 0x002       // Floating-Point Dynamic Rounding Mode.
  logic                   [XLEN-1:0] fcsr         ;  // 0x003       // Floating-Point Control and Status Register (frm + fflags).
  // User Trap Setup (continued)
  logic                   [XLEN-1:0] uie          ;  // 0x004       // User interrupt-enable register.
  logic                   [XLEN-1:0] utvec        ;  // 0x005       // User trap handler base address.
  logic [12'h006:12'h03f] [XLEN-1:0] res_006_03f  ;
  // User Trap Handling
  logic                   [XLEN-1:0] uscratch     ;  // 0x040       // Scratch register for user trap handlers.
  logic                   [XLEN-1:0] uepc         ;  // 0x041       // User exception program counter.
  logic                   [XLEN-1:0] ucause       ;  // 0x042       // User trap cause.
  logic                   [XLEN-1:0] utval        ;  // 0x043       // User bad address or instruction.
  logic                   [XLEN-1:0] uip          ;  // 0x044       // User interrupt pending.
  logic [12'h045:12'h0ff] [XLEN-1:0] res_045_0ff  ;

  // Supervisor Trap Setup
  logic                   [XLEN-1:0] sstatus      ;  // 0x100       // Supervisor status register.
  logic [12'h101:12'h101] [XLEN-1:0] res_101_101  ;
  logic                   [XLEN-1:0] sedeleg      ;  // 0x102       // Supervisor exception delegation register.
  logic                   [XLEN-1:0] sideleg      ;  // 0x103       // Supervisor interrupt delegation register.
  logic                   [XLEN-1:0] sie          ;  // 0x104       // Supervisor interrupt-enable register.
  logic                   [XLEN-1:0] stvec        ;  // 0x105       // Supervisor trap handler base address.
  logic                   [XLEN-1:0] scounteren   ;  // 0x106       // Supervisor counter enable.
  logic [12'h107:12'h13f] [XLEN-1:0] res_107_13f  ;
  // Supervisor Trap Handling
  logic                   [XLEN-1:0] sscratch     ;  // 0x140       // Scratch register for supervisor trap handlers.
  logic                   [XLEN-1:0] sepc         ;  // 0x141       // Supervisor exception program counter.
  logic                   [XLEN-1:0] scause       ;  // 0x142       // Supervisor trap cause.
  logic                   [XLEN-1:0] stval        ;  // 0x143       // Supervisor bad address or instruction.
  logic                   [XLEN-1:0] sip          ;  // 0x144       // Supervisor interrupt pending.
  logic [12'h145:12'h17f] [XLEN-1:0] res_145_17f  ;
  // Supervisor Protection and Translation
  logic                   [XLEN-1:0] satp         ;  // 0x180       // Supervisor address translation and protection.
  logic [12'h181:12'h1ff] [XLEN-1:0] res_181_1ff  ;

  // Virtual Supervisor Registers
  logic                   [XLEN-1:0] vsstatus     ;  // 0x200       // Virtual supervisor status register.
  logic [12'h201:12'h203] [XLEN-1:0] res_201_203  ;
  logic                   [XLEN-1:0] vsie         ;  // 0x204       // Virtual supervisor interrupt-enable register.
  logic                   [XLEN-1:0] vstvec       ;  // 0x205       // Virtual supervisor trap handler base address.
  logic [12'h206:12'h23f] [XLEN-1:0] res_206_23f  ;
  logic                   [XLEN-1:0] vsscratch    ;  // 0x240       // Virtual supervisor scratch register.
  logic                   [XLEN-1:0] vsepc        ;  // 0x241       // Virtual supervisor exception program counter.
  logic                   [XLEN-1:0] vscause      ;  // 0x242       // Virtual supervisor trap cause.
  logic                   [XLEN-1:0] vstval       ;  // 0x243       // Virtual supervisor bad address or instruction.
  logic                   [XLEN-1:0] vsip         ;  // 0x244       // Virtual supervisor interrupt pending.
  logic [12'h245:12'h27f] [XLEN-1:0] res_245_27f  ;
  logic                   [XLEN-1:0] vsatp        ;  // 0x280       // Virtual supervisor address translation and protection.
  logic [12'h281:12'h2ff] [XLEN-1:0] res_281_2ff  ;

  // Machine Trap Setup
  csr_mstatus_rv64_t                 mstatus      ;  // 0x300       // Machine status register.
  csr_misa_t                         misa         ;  // 0x301       // ISA and extensions
  logic                   [XLEN-1:0] medeleg      ;  // 0x302       // Machine exception delegation register.
  logic                   [XLEN-1:0] mideleg      ;  // 0x303       // Machine interrupt delegation register.
  csr_mie_t                          mie          ;  // 0x304       // Machine interrupt-enable register.
  csr_mtvec_t                        mtvec        ;  // 0x305       // Machine trap-handler base address.
  csr_mcounteren_t                   mcounteren   ;  // 0x306       // Machine counter enable.
  logic [12'h307:12'h30f] [XLEN-1:0] res_307_30f  ;
  logic                   [XLEN-1:0] mstatush     ;  // 0x310       // Additional machine status register, RV32 only.
  logic [12'h311:12'h31f] [XLEN-1:0] res_311_31f  ;
  // Machine Counter Setup
  csr_mcountinhibit_t                mcountinhibit; // 0x320       // Machine counter-inhibit register.
  logic [12'h321:12'h322] [XLEN-1:0] res_321_322  ;
  logic [12'h003:12'h01f] [XLEN-1:0] mhpmevent    ;  // 0x323~0x33F // Machine performance-monitoring event selector.
  // Machine Trap Handling
  csr_mscratch_t                     mscratch     ;  // 0x340       // Scratch register for machine trap handlers.
  csr_mepc_t                         mepc         ;  // 0x341       // Machine exception program counter.
  csr_mcause_t                       mcause       ;  // 0x342       // Machine trap cause.
  csr_mtval_t                        mtval        ;  // 0x343       // Machine bad address or instruction.
  csr_mip_t                          mip          ;  // 0x344       // Machine interrupt pending.
  logic [12'h345:12'h349] [XLEN-1:0] res_345_349  ;
  logic                   [XLEN-1:0] mtinst       ;  // 0x34A       // Machine trap instruction (transformed).
  logic                   [XLEN-1:0] mtval2       ;  // 0x34B       // Machine bad guest physical address.
  logic [12'h34c:12'h39f] [XLEN-1:0] res_34c_39f  ;
  // Machine Memory Protection
  logic [12'h000:12'h00f] [XLEN-1:0] pmpcfg       ;  // 0x3A0~0x3AF // Physical memory protection configuration. (the odd ones are RV32 only)
  logic [12'h000:12'h03f] [XLEN-1:0] pmpaddr      ;  // 0x3B0~0x3EF // Physical memory protection address register.
  logic [12'h3f0:12'h5a7] [XLEN-1:0] res_3f0_5a7  ;

  // Debug/Trace Registers
  logic                   [XLEN-1:0] scontext     ;  // 0x5A8       // Supervisor-mode context register.
  logic [12'h5a9:12'h5ff] [XLEN-1:0] res_5a9_5ff  ;

  // Hypervisor Trap Setup
  logic                   [XLEN-1:0] hstatus      ;  // 0x600       // Hypervisor status register.
  logic [12'h601:12'h601] [XLEN-1:0] res_601_601  ;
  logic                   [XLEN-1:0] hedeleg      ;  // 0x602       // Hypervisor exception delegation register.
  logic                   [XLEN-1:0] hideleg      ;  // 0x603       // Hypervisor interrupt delegation register.
  logic                   [XLEN-1:0] hie          ;  // 0x604       // Hypervisor interrupt-enable register.
  // Hypervisor Counter/Timer Virtualization Registers
  logic                   [XLEN-1:0] htimedelta   ;  // 0x605       // Delta for VS/VU-mode timer.
  // Hypervisor Trap Setup (continued)
  logic                   [XLEN-1:0] hcounteren   ;  // 0x606       // Hypervisor counter enable.
  logic                   [XLEN-1:0] htvec        ;  // 0x607       // Hypervisor guest external interrupt-enable register.
  logic [12'h608:12'h614] [XLEN-1:0] res_608_614  ;
  // Hypervisor Counter/Timer Virtualization Registers (continued)
  logic                   [XLEN-1:0] htimedeltah  ;  // 0x615       // Upper 32 bits of htimedelta, RV32 only.
  logic [12'h616:12'h642] [XLEN-1:0] res_616_642  ;

  // Hypervisor Trap Handling
  logic                   [XLEN-1:0] htval        ;  // 0x643       // Hypervisor bad guest physical address.
  logic                   [XLEN-1:0] hip          ;  // 0x644       // Hypervisor interrupt pending.
  logic                   [XLEN-1:0] hvip         ;  // 0x645       // Hypervisor virtual interrupt pending.
  logic [12'h646:12'h649] [XLEN-1:0] res_646_649  ;
  logic                   [XLEN-1:0] htinst       ;  // 0x64A       // Hypervisor trap instruction (transformed).
  logic [12'h64b:12'h67f] [XLEN-1:0] res_64b_67f  ;
  // Hypervisor Protection and Translation
  logic                   [XLEN-1:0] hgatp        ;  // 0x680       // Hypervisor guest address translation and protection.
  logic [12'h681:12'h6a7] [XLEN-1:0] res_681_6a7  ;
  // Debug/Trace Registers
  logic                   [XLEN-1:0] hcontext     ;  // 0x6A8       // Hypervisor-mode context register.
  logic [12'h6a9:12'h79f] [XLEN-1:0] res_6a9_79f  ;

  // Debug/Trace Registers (shared with Debug Mode)
  logic                   [XLEN-1:0] tselect      ;  // 0x7A0       // Debug/Trace trigger register select.
  logic                   [XLEN-1:0] tdata1       ;  // 0x7A1       // First Debug/Trace trigger data register.
  logic                   [XLEN-1:0] tdata2       ;  // 0x7A2       // Second Debug/Trace trigger data register.
  logic                   [XLEN-1:0] tdata3       ;  // 0x7A3       // Third Debug/Trace trigger data register.
  logic [12'h7a4:12'h7a7] [XLEN-1:0] res_7a4_7a7  ;
  logic                   [XLEN-1:0] mcontext     ;  // 0x7A8       // Machine-mode context register.
  logic [12'h7a9:12'h7af] [XLEN-1:0] res_7a9_7af  ;
  // Debug Mode Registers
  logic                   [XLEN-1:0] dcsr         ;  // 0x7B0       // Debug control and status register.
  logic                   [XLEN-1:0] dpc          ;  // 0x7B1       // Debug PC.
  logic                   [XLEN-1:0] dscratch0    ;  // 0x7B2       // Debug scratch register 0.
  logic                   [XLEN-1:0] dscratch1    ;  // 0x7B3       // Debug scratch register 1.
  logic [12'h7b4:12'haff] [XLEN-1:0] res_7b4_aff  ;
  // Machine Counter/Timers
  logic                   [XLEN-1:0] mcycle       ;  // 0xB00       // Machine cycle counter.
  logic [12'hb01:12'hb01] [XLEN-1:0] res_b01_b01  ;
  logic                   [XLEN-1:0] minstret     ;  // 0xB02       // Machine instructions-retired counter.
  logic [12'h003:12'h01f] [XLEN-1:0] mhpmcounter  ;  // 0xB03       // Machine performance-monitoring counter.
  logic [12'hb20:12'hb7f] [XLEN-1:0] res_b20_b7f  ;
  logic                   [XLEN-1:0] mcycleh      ;  // 0xB80       // Upper 32 bits of mcycle, RV32 only.
  logic [12'hb81:12'hb81] [XLEN-1:0] res_b81_b81  ;
  logic                   [XLEN-1:0] minstreth    ;  // 0xB82       // Upper 32 bits of minstret, RV32 only.
  logic [12'h003:12'h01f] [XLEN-1:0] mhpmcounterh ;  // 0xB83-0xB9F // Upper 32 bits of mhpmcounter*, RV32 only.
  logic [12'hba0:12'hbff] [XLEN-1:0] res_ba0_bff  ;
  // User Counter/Timers
  logic                   [XLEN-1:0] cycle        ;  // 0xC00       // Cycle counter for RDCYCLE instruction.
  logic                   [XLEN-1:0] time_        ;  // 0xC01       // Timer for RDTIME instruction.
  logic                   [XLEN-1:0] instret      ;  // 0xC02       // Instructions-retired counter for RDINSTRET instruction.
  logic [12'h003:12'h01f] [XLEN-1:0] hpmcounter   ;  // 0xC03~0xC1F // Performance-monitoring counter. (3~31)
  logic [12'hc20:12'hc7f] [XLEN-1:0] res_c20_c7f  ;
  logic                   [XLEN-1:0] cycleh       ;  // 0xC80       // Upper 32 bits of cycle, RV32 only.
  logic                   [XLEN-1:0] timeh        ;  // 0xC81       // Upper 32 bits of time, RV32 only.
  logic                   [XLEN-1:0] instreth     ;  // 0xC82       // Upper 32 bits of instret, RV32 only.
  logic [12'h003:12'h01f] [XLEN-1:0] hpmcounterh  ;  // 0xC83~0xC9F // Upper 32 bits of hpmcounter*, RV32 only. (3~31)
  logic [12'hca0:12'he11] [XLEN-1:0] res_ca0_e11  ;
  // Hypervisor Trap Handling (continued)
  logic                   [XLEN-1:0] hgeip        ;  // 0xE12       // Hypervisor guest external interrupt pending.
  logic [12'he13:12'hf10] [XLEN-1:0] res_e13_f10  ;
  // Machine Information Registers
  logic                   [XLEN-1:0] mvendorid    ;  // 0xF11       // Vendor ID.
  logic                   [XLEN-1:0] marchid      ;  // 0xF12       // Architecture ID.
  logic                   [XLEN-1:0] mimpid       ;  // 0xF13       // Implementation ID.
  logic                   [XLEN-1:0] mhartid      ;  // 0xF14       // Hardware thread ID.
  logic [12'hf15:12'hfff] [XLEN-1:0] res_f15_fff  ;
} csr_map_st;
/* verilator lint_on LITENDIAN */

// SCR address map array
/* verilator lint_off LITENDIAN */
typedef logic [0:2**12-1][XLEN-1:0] csr_map_at;
/* verilator lint_on LITENDIAN */

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
`define WERE '0  // 0 - (WERE) Write Error, Read Error (NOTE: not a neme from the specification)
                 //            non-existent CSR, access shall raise an illegal instruction exception

parameter csr_map_st CSR_MAP_WR = '{
  // 0x300       // Machine status register.
  mstatus    : '{
    SD         : `WARL,  // 63    // SD=((FS==11) OR (XS==11)))
    wpri_62_38 : `WPRI,  // 62:38 //
    // Endianness Control
    MBE        : `WLRL,  // 37    // M-mode endianness
    SBE        : `WLRL,  // 36    // S-mode endianness
    // Base ISA Control
    SXL        : `WLRL,  // 35:34 // S-mode XLEN
    UXL        : `WLRL,  // 33:32 // U-mode XLEN
    wpri_31_23 : `WPRI,  // 31:23 //
    // Virtualization Support
    TSR        : `WLRL,  // 22    // Trap SRET
    TW         : `WLRL,  // 21    // Timeout Wait
    TVM        : `WLRL,  // 20    // Trap Virtual Memory
    // Memory Privilige
    MXR        : `WLRL,  // 19    // Make eXecutable Readable
    SUM        : `WLRL,  // 18    // permit Supervisor User Memory access
    MPRV       : `WLRL,  // 17    // Modify PRiVilege
    // Extension Context Status
    XS         : `WLRL,  // 16:15 // user-mode extensions context status
    FS         : `WLRL,  // 14:13 // floating-point context status
    // Privilege and Global Interrupt-Enable Stack
    MPP        : `WLRL,  // 12:11 // machine previous privilege mode
    wpri_10_09 : `WPRI,  // 10: 9 //
    SPP        : `WLRL,  //  8    // supervisor previous privilege mode
    MPIE       : `WLRL,  //  7    // machine interrupt-enable active prior to the trap
    UBE        : `WLRL,  //  6    // U-mode endianness
    SPIE       : `WLRL,  //  5    // supervisor interrupt-enable active prior to the trap
    wpri_04_04 : `WPRI,  //  4    //
    MIE        : `WLRL,  //  3    // machine global interrupt-enable
    wpri_02_02 : `WPRI,  //  2    //
    SIE        : `WLRL,  //  1    // supervisor global interrupt-enable
    wpri_00_00 : `WPRI   //  0    //
  },
  // 0x301       // ISA and extensions
  misa       : '{
    MXL        : `WARL,  // Machine XLEN
    warl_xx_26 : `WARL,  // Reserved
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
    BASE : `WARL,  // **: 2 // vector base address
    MODE : `WARL   //  1: 0 // vector mode
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
  /* verilator lint_off WIDTHCONCAT */
  default    : '0
  /* verilator lint_on WIDTHCONCAT */
};

endpackage: riscv_csr_pkg