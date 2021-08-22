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
  csr_adr_bit_t [3:31] mhpmevent    ;  // 0x323~0x33F // Machine performance-monitoring event selector.
  csr_adr_bit_t        mscratch     ;  // 0x340       // Scratch register for machine trap handlers.
  csr_adr_bit_t        mepc         ;  // 0x341       // Machine exception program counter.
  csr_adr_bit_t        mcause       ;  // 0x342       // Machine trap cause.
  csr_adr_bit_t        mtval        ;  // 0x343       // Machine bad address or instruction.
  csr_adr_bit_t        mip          ;  // 0x344       // Machine interrupt pending.
  csr_adr_bit_t        mtinst       ;  // 0x34A       // Machine trap instruction (transformed).
  csr_adr_bit_t        mtval2       ;  // 0x34B       // Machine bad guest physical address.
  csr_adr_bit_t [0:15] pmpcfg       ;  // 0x3A0~0x3AF // Physical memory protection configuration. (the odd ones are RV32 only)
  csr_adr_bit_t [0:63] pmpaddr      ;  // 0x3B0~0x3EF // Physical memory protection address register.
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
  csr_adr_bit_t [3:31] mhpmcounter  ;  // 0xB03       // Machine performance-monitoring counter.
  csr_adr_bit_t        mcycleh      ;  // 0xB80       // Upper 32 bits of mcycle, RV32 only.
  csr_adr_bit_t        minstreth    ;  // 0xB82       // Upper 32 bits of minstret, RV32 only.
  csr_adr_bit_t [3:31] mhpmcounterh ;  // 0xB83-0xB9F // Upper 32 bits of mhpmcounter*, RV32 only.
  csr_adr_bit_t        cycle        ;  // 0xC00       // Cycle counter for RDCYCLE instruction.
  csr_adr_bit_t        time_        ;  // 0xC01       // Timer for RDTIME instruction.
  csr_adr_bit_t        instret      ;  // 0xC02       // Instructions-retired counter for RDINSTRET instruction.
  csr_adr_bit_t [3:31] hpmcounter   ;  // 0xC03~0xC1F // Performance-monitoring counter. (3~31)
  csr_adr_bit_t        cycleh       ;  // 0xC80       // Upper 32 bits of cycle, RV32 only.
  csr_adr_bit_t        timeh        ;  // 0xC81       // Upper 32 bits of time, RV32 only.
  csr_adr_bit_t        instreth     ;  // 0xC82       // Upper 32 bits of instret, RV32 only.
  csr_adr_bit_t [3:31] hpmcounterh  ;  // 0xC83~0xC9F // Upper 32 bits of hpmcounter*, RV32 only. (3~31)
  csr_adr_bit_t        hgeip        ;  // 0xE12       // Hypervisor guest external interrupt pending.
  csr_adr_bit_t        mvendorid    ;  // 0xF11       // Vendor ID.
  csr_adr_bit_t        marchid      ;  // 0xF12       // Architecture ID.
  csr_adr_bit_t        mimpid       ;  // 0xF13       // Implementation ID.
  csr_adr_bit_t        mhartid      ;  // 0xF14       // Hardware thread ID.
} CSR_MAP_C = '0;
/* verilator lint_on LITENDIAN */

endpackage: riscv_csr_adr_map_pkg