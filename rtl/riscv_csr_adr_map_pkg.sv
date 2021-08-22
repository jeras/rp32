////////////////////////////////////////////////////////////////////////////////
// RISC-V CSR address map package (based on privileged spec)
////////////////////////////////////////////////////////////////////////////////

package riscv_csr_adr_map_pkg;

// CSR address structure
// 'bit' type is used for this constant
typedef struct packed {
   bit [11:10] perm;
   bit [09:08] level;
   bit [07:00] addr;
} csr_adr_bit_t;

// SCR address map structure
/* verilator lint_off LITENDIAN */
localparam struct packed {
  csr_adr_bit_t        ustatus      ;  // 0x000       // User status register.
  csr_adr_bit_t        fflafs       ;  // 0x001       // Floating-Point Accrued Exceptions.
  csr_adr_bit_t        frm          ;  // 0x002       // Floating-Point Dynamic Rounding Mode.
  csr_adr_bit_t        fcsr         ;  // 0x003       // Floating-Point Control and Status Register (frm + fflags).
  csr_adr_bit_t        uie          ;  // 0x004       // User interrupt-enable register.
  csr_adr_bit_t        utvec        ;  // 0x005       // User trap handler base address.
  csr_adr_bit_t        uscratch     ;  // 0x040       // Scratch register for user trap handlers.
  csr_adr_bit_t        uepc         ;  // 0x041       // User exception program counter.
  csr_adr_bit_t        ucause       ;  // 0x042       // User trap cause.
  csr_adr_bit_t        utval        ;  // 0x043       // User bad address or instruction.
  csr_adr_bit_t        uip          ;  // 0x044       // User interrupt pending.
  csr_adr_bit_t        sstatus      ;  // 0x100       // Supervisor status register.
  csr_adr_bit_t        sedeleg      ;  // 0x102       // Supervisor exception delegation register.
  csr_adr_bit_t        sideleg      ;  // 0x103       // Supervisor interrupt delegation register.
  csr_adr_bit_t        sie          ;  // 0x104       // Supervisor interrupt-enable register.
  csr_adr_bit_t        stvec        ;  // 0x105       // Supervisor trap handler base address.
  csr_adr_bit_t        scounteren   ;  // 0x106       // Supervisor counter enable.
  csr_adr_bit_t        sscratch     ;  // 0x140       // Scratch register for supervisor trap handlers.
  csr_adr_bit_t        sepc         ;  // 0x141       // Supervisor exception program counter.
  csr_adr_bit_t        scause       ;  // 0x142       // Supervisor trap cause.
  csr_adr_bit_t        stval        ;  // 0x143       // Supervisor bad address or instruction.
  csr_adr_bit_t        sip          ;  // 0x144       // Supervisor interrupt pending.
  csr_adr_bit_t        satp         ;  // 0x180       // Supervisor address translation and protection.
  csr_adr_bit_t        vsstatus     ;  // 0x200       // Virtual supervisor status register.
  csr_adr_bit_t        vsie         ;  // 0x204       // Virtual supervisor interrupt-enable register.
  csr_adr_bit_t        vstvec       ;  // 0x205       // Virtual supervisor trap handler base address.
  csr_adr_bit_t        vsscratch    ;  // 0x240       // Virtual supervisor scratch register.
  csr_adr_bit_t        vsepc        ;  // 0x241       // Virtual supervisor exception program counter.
  csr_adr_bit_t        vscause      ;  // 0x242       // Virtual supervisor trap cause.
  csr_adr_bit_t        vstval       ;  // 0x243       // Virtual supervisor bad address or instruction.
  csr_adr_bit_t        vsip         ;  // 0x244       // Virtual supervisor interrupt pending.
  csr_adr_bit_t        vsatp        ;  // 0x280       // Virtual supervisor address translation and protection.
  csr_adr_bit_t        mstatus      ;  // 0x300       // Machine status register.
  csr_adr_bit_t        misa         ;  // 0x301       // ISA and extensions
  csr_adr_bit_t        medeleg      ;  // 0x302       // Machine exception delegation register.
  csr_adr_bit_t        mideleg      ;  // 0x303       // Machine interrupt delegation register.
  csr_adr_bit_t        mie          ;  // 0x304       // Machine interrupt-enable register.
  csr_adr_bit_t        mtvec        ;  // 0x305       // Machine trap-handler base address.
  csr_adr_bit_t        mcounteren   ;  // 0x306       // Machine counter enable.
  csr_adr_bit_t        mstatush     ;  // 0x310       // Additional machine status register, RV32 only.
  csr_adr_bit_t        mcountinhibit;  // 0x320       // Machine counter-inhibit register.
  csr_adr_bit_t [3:31] mhpmevent    ;  // 0x323:0x33F // Machine performance-monitoring event selector.
  csr_adr_bit_t        mscratch     ;  // 0x340       // Scratch register for machine trap handlers.
  csr_adr_bit_t        mepc         ;  // 0x341       // Machine exception program counter.
  csr_adr_bit_t        mcause       ;  // 0x342       // Machine trap cause.
  csr_adr_bit_t        mtval        ;  // 0x343       // Machine bad address or instruction.
  csr_adr_bit_t        mip          ;  // 0x344       // Machine interrupt pending.
  csr_adr_bit_t        mtinst       ;  // 0x34A       // Machine trap instruction (transformed).
  csr_adr_bit_t        mtval2       ;  // 0x34B       // Machine bad guest physical address.
  csr_adr_bit_t [0:15] pmpcfg       ;  // 0x3A0:0x3AF // Physical memory protection configuration. (the odd ones are RV32 only)
  csr_adr_bit_t [0:63] pmpaddr      ;  // 0x3B0:0x3EF // Physical memory protection address register.
  csr_adr_bit_t        scontext     ;  // 0x5A8       // Supervisor-mode context register.
  csr_adr_bit_t        hstatus      ;  // 0x600       // Hypervisor status register.
  csr_adr_bit_t        hedeleg      ;  // 0x602       // Hypervisor exception delegation register.
  csr_adr_bit_t        hideleg      ;  // 0x603       // Hypervisor interrupt delegation register.
  csr_adr_bit_t        hie          ;  // 0x604       // Hypervisor interrupt-enable register.
  csr_adr_bit_t        htimedelta   ;  // 0x605       // Delta for VS/VU-mode timer.
  csr_adr_bit_t        hcounteren   ;  // 0x606       // Hypervisor counter enable.
  csr_adr_bit_t        htvec        ;  // 0x607       // Hypervisor guest external interrupt-enable register.
  csr_adr_bit_t        htimedeltah  ;  // 0x615       // Upper 32 bits of htimedelta, RV32 only.
  csr_adr_bit_t        htval        ;  // 0x643       // Hypervisor bad guest physical address.
  csr_adr_bit_t        hip          ;  // 0x644       // Hypervisor interrupt pending.
  csr_adr_bit_t        hvip         ;  // 0x645       // Hypervisor virtual interrupt pending.
  csr_adr_bit_t        htinst       ;  // 0x64A       // Hypervisor trap instruction (transformed).
  csr_adr_bit_t        hgatp        ;  // 0x680       // Hypervisor guest address translation and protection.
  csr_adr_bit_t        hcontext     ;  // 0x6A8       // Hypervisor-mode context register.
  csr_adr_bit_t        tselect      ;  // 0x7A0       // Debug/Trace trigger register select.
  csr_adr_bit_t        tdata1       ;  // 0x7A1       // First Debug/Trace trigger data register.
  csr_adr_bit_t        tdata2       ;  // 0x7A2       // Second Debug/Trace trigger data register.
  csr_adr_bit_t        tdata3       ;  // 0x7A3       // Third Debug/Trace trigger data register.
  csr_adr_bit_t        mcontext     ;  // 0x7A8       // Machine-mode context register.
  csr_adr_bit_t        dcsr         ;  // 0x7B0       // Debug control and status register.
  csr_adr_bit_t        dpc          ;  // 0x7B1       // Debug PC.
  csr_adr_bit_t        dscratch0    ;  // 0x7B2       // Debug scratch register 0.
  csr_adr_bit_t        dscratch1    ;  // 0x7B3       // Debug scratch register 1.
  csr_adr_bit_t        mcycle       ;  // 0xB00       // Machine cycle counter.
  csr_adr_bit_t        minstret     ;  // 0xB02       // Machine instructions-retired counter.
  csr_adr_bit_t [3:31] mhpmcounter  ;  // 0xB03:0xB1f // Machine performance-monitoring counter.
  csr_adr_bit_t        mcycleh      ;  // 0xB80       // Upper 32 bits of mcycle, RV32 only.
  csr_adr_bit_t        minstreth    ;  // 0xB82       // Upper 32 bits of minstret, RV32 only.
  csr_adr_bit_t [3:31] mhpmcounterh ;  // 0xB83:0xB9F // Upper 32 bits of mhpmcounter*, RV32 only.
  csr_adr_bit_t        cycle        ;  // 0xC00       // Cycle counter for RDCYCLE instruction.
  csr_adr_bit_t        time_        ;  // 0xC01       // Timer for RDTIME instruction.
  csr_adr_bit_t        instret      ;  // 0xC02       // Instructions-retired counter for RDINSTRET instruction.
  csr_adr_bit_t [3:31] hpmcounter   ;  // 0xC03:0xC1F // Performance-monitoring counter. (3~31)
  csr_adr_bit_t        cycleh       ;  // 0xC80       // Upper 32 bits of cycle, RV32 only.
  csr_adr_bit_t        timeh        ;  // 0xC81       // Upper 32 bits of time, RV32 only.
  csr_adr_bit_t        instreth     ;  // 0xC82       // Upper 32 bits of instret, RV32 only.
  csr_adr_bit_t [3:31] hpmcounterh  ;  // 0xC83:0xC9F // Upper 32 bits of hpmcounter*, RV32 only. (3~31)
  csr_adr_bit_t        hgeip        ;  // 0xE12       // Hypervisor guest external interrupt pending.
  csr_adr_bit_t        mvendorid    ;  // 0xF11       // Vendor ID.
  csr_adr_bit_t        marchid      ;  // 0xF12       // Architecture ID.
  csr_adr_bit_t        mimpid       ;  // 0xF13       // Implementation ID.
  csr_adr_bit_t        mhartid      ;  // 0xF14       // Hardware thread ID.
} CSR_MAP_C = '{
  ustatus      :   12'h000,
  fflafs       :   12'h001,
  frm          :   12'h002,
  fcsr         :   12'h003,
  uie          :   12'h004,
  utvec        :   12'h005,
  uscratch     :   12'h040,
  uepc         :   12'h041,
  ucause       :   12'h042,
  utval        :   12'h043,
  uip          :   12'h044,
  sstatus      :   12'h100,
  sedeleg      :   12'h102,
  sideleg      :   12'h103,
  sie          :   12'h104,
  stvec        :   12'h105,
  scounteren   :   12'h106,
  sscratch     :   12'h140,
  sepc         :   12'h141,
  scause       :   12'h142,
  stval        :   12'h143,
  sip          :   12'h144,
  satp         :   12'h180,
  vsstatus     :   12'h200,
  vsie         :   12'h204,
  vstvec       :   12'h205,
  vsscratch    :   12'h240,
  vsepc        :   12'h241,
  vscause      :   12'h242,
  vstval       :   12'h243,
  vsip         :   12'h244,
  vsatp        :   12'h280,
  mstatus      :   12'h300,
  misa         :   12'h301,
  medeleg      :   12'h302,
  mideleg      :   12'h303,
  mie          :   12'h304,
  mtvec        :   12'h305,
  mcounteren   :   12'h306,
  mstatush     :   12'h310,
  mcountinhibit:   12'h320,
  mhpmevent    : '{                           12'h323, 12'h324, 12'h325, 12'h326, 12'h327,
                   12'h328, 12'h329, 12'h32A, 12'h32B, 12'h32C, 12'h32D, 12'h32E, 12'h32F,
                   12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337,
                   12'h338, 12'h339, 12'h33A, 12'h33B, 12'h33C, 12'h33D, 12'h33E, 12'h33F},
  mscratch     :   12'h340,
  mepc         :   12'h341,
  mcause       :   12'h342,
  mtval        :   12'h343,
  mip          :   12'h344,
  mtinst       :   12'h34A,
  mtval2       :   12'h34B,
  pmpcfg       : '{12'h3A0, 12'h3A1, 12'h3A2, 12'h3A3, 12'h3A4, 12'h3A5, 12'h3A6, 12'h3A7,
                   12'h3A8, 12'h3A9, 12'h3AA, 12'h3AB, 12'h3AC, 12'h3AD, 12'h3AE, 12'h3AF},
  pmpaddr      : '{12'h3B0, 12'h3B1, 12'h3B2, 12'h3B3, 12'h3B4, 12'h3B5, 12'h3B6, 12'h3B7,
                   12'h3B8, 12'h3B9, 12'h3BA, 12'h3BB, 12'h3BC, 12'h3BD, 12'h3BE, 12'h3BF,
                   12'h3C0, 12'h3C1, 12'h3C2, 12'h3C3, 12'h3C4, 12'h3C5, 12'h3C6, 12'h3C7,
                   12'h3C8, 12'h3C9, 12'h3CA, 12'h3CB, 12'h3CC, 12'h3CD, 12'h3CE, 12'h3CF,
                   12'h3D0, 12'h3D1, 12'h3D2, 12'h3D3, 12'h3D4, 12'h3D5, 12'h3D6, 12'h3D7,
                   12'h3D8, 12'h3D9, 12'h3DA, 12'h3DB, 12'h3DC, 12'h3DD, 12'h3DE, 12'h3DF,
                   12'h3E0, 12'h3E1, 12'h3E2, 12'h3E3, 12'h3E4, 12'h3E5, 12'h3E6, 12'h3E7,
                   12'h3E8, 12'h3E9, 12'h3EA, 12'h3EB, 12'h3EC, 12'h3ED, 12'h3EE, 12'h3EF},
  scontext     :   12'h5A8,
  hstatus      :   12'h600,
  hedeleg      :   12'h602,
  hideleg      :   12'h603,
  hie          :   12'h604,
  htimedelta   :   12'h605,
  hcounteren   :   12'h606,
  htvec        :   12'h607,
  htimedeltah  :   12'h615,
  htval        :   12'h643,
  hip          :   12'h644,
  hvip         :   12'h645,
  htinst       :   12'h64A,
  hgatp        :   12'h680,
  hcontext     :   12'h6A8,
  tselect      :   12'h7A0,
  tdata1       :   12'h7A1,
  tdata2       :   12'h7A2,
  tdata3       :   12'h7A3,
  mcontext     :   12'h7A8,
  dcsr         :   12'h7B0,
  dpc          :   12'h7B1,
  dscratch0    :   12'h7B2,
  dscratch1    :   12'h7B3,
  mcycle       :   12'hB00,
  minstret     :   12'hB02,
  mhpmcounter  : '{                           12'hB03, 12'hB04, 12'hB05, 12'hB06, 12'hB07,
                   12'hB08, 12'hB09, 12'hB0A, 12'hB0B, 12'hB0C, 12'hB0D, 12'hB0E, 12'hB0F,
                   12'hB10, 12'hB11, 12'hB12, 12'hB13, 12'hB14, 12'hB15, 12'hB16, 12'hB17,
                   12'hB18, 12'hB19, 12'hB1A, 12'hB1B, 12'hB1C, 12'hB1D, 12'hB1E, 12'hB1F},
  mcycleh      :   12'hB80,
  minstreth    :   12'hB82,
  mhpmcounterh : '{                           12'hB83, 12'hB84, 12'hB85, 12'hB86, 12'hB87,
                   12'hB88, 12'hB89, 12'hB8A, 12'hB8B, 12'hB8C, 12'hB8D, 12'hB8E, 12'hB8F,
                   12'hB90, 12'hB91, 12'hB92, 12'hB93, 12'hB94, 12'hB95, 12'hB96, 12'hB97,
                   12'hB98, 12'hB99, 12'hB9A, 12'hB9B, 12'hB9C, 12'hB9D, 12'hB9E, 12'hB9F},
  cycle        :   12'hC00,
  time_        :   12'hC01,
  instret      :   12'hC02,
  hpmcounter   : '{                           12'hC03, 12'hC04, 12'hC05, 12'hC06, 12'hC07,
                   12'hC08, 12'hC09, 12'hC0A, 12'hC0B, 12'hC0C, 12'hC0D, 12'hC0E, 12'hC0F,
                   12'hC10, 12'hC11, 12'hC12, 12'hC13, 12'hC14, 12'hC15, 12'hC16, 12'hC17,
                   12'hC18, 12'hC19, 12'hC1A, 12'hC1B, 12'hC1C, 12'hC1D, 12'hC1E, 12'hC1F},
  cycleh       :   12'hC80,
  timeh        :   12'hC81,
  instreth     :   12'hC82,
  hpmcounterh  : '{                           12'hC83, 12'hC84, 12'hC85, 12'hC86, 12'hC87,
                   12'hC88, 12'hC89, 12'hC8A, 12'hC8B, 12'hC8C, 12'hC8D, 12'hC8E, 12'hC8F,
                   12'hC90, 12'hC91, 12'hC92, 12'hC93, 12'hC94, 12'hC95, 12'hC96, 12'hC97,
                   12'hC98, 12'hC99, 12'hC9A, 12'hC9B, 12'hC9C, 12'hC9D, 12'hC9E, 12'hC9F},
  hgeip        :   12'hE12,
  mvendorid    :   12'hF11,
  marchid      :   12'hF12,
  mimpid       :   12'hF13,
  mhartid      :   12'hF14
};
/* verilator lint_on LITENDIAN */

endpackage: riscv_csr_adr_map_pkg