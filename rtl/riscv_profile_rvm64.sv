///////////////////////////////////////////////////////////////////////////////
// RISC-V profile RVM22* for RV64
///////////////////////////////////////////////////////////////////////////////

package riscv_profile_rvm64;

///////////////////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////////////////

//  mstatus      ;  // 0x300       // Machine status register.
//  misa         ;  // 0x301       // ISA and extensions
//  mie          ;  // 0x304       // Machine interrupt-enable register.
//  mtvec        ;  // 0x305       // Machine trap-handler base address.
//  mcounteren   ;  // 0x306       // Machine counter enable.
//  mcsratch     ;  // 0x340       // Csratch register for machine trap handlers.
//  mepc         ;  // 0x341       // Machine exception program counter.
//  mcause       ;  // 0x342       // Machine trap cause.
//  mtval        ;  // 0x343       // Machine bad address or instruction.
//  mip          ;  // 0x344       // Machine interrupt pending.

// reset value

// enable read access
parameter csr_map_ut CSR_REN_S = '{
  // 0x300       // Machine status register.
  mstatus    : '{
    SD         = '1,  // 63    // SD=((FS==11) OR (XS==11)))
    wpri_62_38 = '0,  // 62:38 //
  // Endianness Control
    MBE        = '1,  // 37    // M-mode endianness
    SBE        = '1,  // 36    // S-mode endianness
  // Base ISA Control
    SXL        : '1,  // 35:34 // S-mode XLEN
    UXL        : '1,  // 33:32 // U-mode XLEN
    wpri_31_23 : '0,  // 31:23 //
  // Virtualization Support
    TSR        : '1,  // 22    // Trap SRET
    TW         : '1,  // 21    // Timeout Wait
    TVM        : '1,  // 20    // Trap Virtual Memory
  // Memory Privilige
    MXR        : '1,  // 19    // Make eXecutable Readable
    SUM        : '1,  // 18    // permit Supervisor User Memory access
    MPRV       : '1,  // 17    // Modify PRiVilege
  // Extension Context Status
    XS         : '1,  // 16:15 // user-mode extensions context status
    FS         : '1,  // 14:13 // floating-point context status
  // Privilege and Global Interrupt-Enable Stack
    MPP        : '1,  // 12:11 // machine previous privilege mode
    wpri_10_09 : '0,  // 10: 9 //
    SPP        : '1,  //  8    // supervisor previous privilege mode
    MPIE       : '1,  //  7    // machine interrupt-enable active prior to the trap
    UBE        : '1,  //  6    // U-mode endianness
    SPIE       : '1,  //  5    // supervisor interrupt-enable active prior to the trap
    wpri_04_04 : '0,  //  4    //
    MIE        : '1,  //  3    // machine global interrupt-enable
    wpri_02_02 : '0,  //  2    //
    SIE        : '1,  //  1    // supervisor global interrupt-enable
    wpri_00_00 : '0   //  0    //
  },
  // 0x301       // ISA and extensions
  misa       : '{
    MXL        : '1,  // Machine XLEN
    warl_xx_26 : '0,  // Reserved
    Extensions : {
      Z : '0,  // 25 // Reserved
      Y : '0,  // 24 // Reserved
      X : '1,  // 23 // Non-standard extensions present
      W : '0,  // 22 // Reserved
      V : '1,  // 21 // Tentatively reserved for Vector extension
      U : '1,  // 20 // User mode implemented
      T : '1,  // 19 // Tentatively reserved for Transactional Memory extension
      S : '1,  // 18 // Supervisor mode implemented
      R : '0,  // 17 // Reserved
      Q : '1,  // 16 // Quad-precision floating-point extension
      P : '1,  // 15 // Tentatively reserved for Packed-SIMD extension
      O : '0,  // 14 // Reserved
      N : '1,  // 13 // User-level interrupts supported
      M : '1,  // 12 // Integer Multiply/Divide extension
      L : '1,  // 11 // Tentatively reserved for Decimal Floating-Point extension
      K : '0,  // 10 // Reserved
      J : '1,  //  9 // Tentatively reserved for Dynamically Translated Languages extension
      I : '1,  //  8 // RV32I/64I/128I base ISA
      H : '1,  //  7 // Hypervisor extension
      G : '0,  //  6 // Reserved
      F : '1,  //  5 // Single-precision floating-point extension
      E : '1,  //  4 // RV32E base ISA
      D : '1,  //  3 // Double-precision floating-point extension
      C : '1,  //  2 // Compressed extension
      B : '1,  //  1 // Tentatively reserved for Bit-Manipulation extension
      A : '1,  //  0 // Atomic extension
    }
  },
  // 0x304       // Machine interrupt-enable register.
  mie        : '{
    Interrupts : '1,  // **:16 //
    zero_15_12 : '0,  // 15:12 //
    MEIE       : '1,  // 11    // machine-level external interrupt
    zero_10_10 : '0,  // 10    //
    SEIE       : '1,  //  9    // supervisor-level external interrupt
    zero_08_08 : '0,  //  8    //
    MTIE       : '1,  //  7    // machine-level timer interrupt
    zero_06_06 : '0,  //  6    //
    STIE       : '1,  //  5    // supervisor-level timer interrupt
    zero_04_04 : '0,  //  4    //
    MSIE       : '1,  //  3    // machine-level software interrupt
    zero_02_02 : '0,  //  2    //
    SSIE       : '1,  //  1    // supervisor-level software interrupt
    zero_00_00 : '0   //  0    //
  },
  // 0x305       // Machine trap-handler base address.
  mtvec      : '{
    BASE : '1,  // **: 2 // vector base address
    MODE : '1   //  1: 0 // vector mode
  },
    // 0x306       // Machine counter enable.
  mcounteren : '{

  },
  mcsratch   : '{},  // 0x340       // Csratch register for machine trap handlers.
  mepc       : '{},  // 0x341       // Machine exception program counter.
  mcause     : '{},  // 0x342       // Machine trap cause.
  mtval      : '{},  // 0x343       // Machine bad address or instruction.
  // 0x344       // Machine interrupt pending.
  mip        : '{
    Interrupts : '1,  // **:16 //
    zero_15_12 : '0,  // 15:12 //
    MEIP       : '1,  // 11    // machine-level external interrupt
    zero_10_10 : '0,  // 10    //
    SEIP       : '1,  //  9    // supervisor-level external interrupt
    zero_08_08 : '0,  //  8    //
    MTIP       : '1,  //  7    // machine-level timer interrupt
    zero_06_06 : '0,  //  6    //
    STIP       : '1,  //  5    // supervisor-level timer interrupt
    zero_04_04 : '0,  //  4    //
    MSIP       : '1,  //  3    // machine-level software interrupt
    zero_02_02 : '0,  //  2    //
    SSIP       : '1,  //  1    // supervisor-level software interrupt
    zero_00_00 : '0   //  0    //
  },
  default    : '0;  
};

// enable write access
parameter csr_map_ut CSR_WEN = '{

};

endpackage: riscv_profile_rvm64