#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#if XLEN == 64
  #define ALIGNMENT 3
#else
  #define ALIGNMENT 2
#endif


//#include "riscv_test.h"

//-----------------------------------------------------------------------
// RVMODEL Macros
//-----------------------------------------------------------------------

#define RVMODEL_DATA_SECTION \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 8; .global tohost; tohost: .dword 0;                     \
        .align 8; .global fromhost; fromhost: .dword 0;                 \
        .popsection;                                                    \
        .align 8; .global begin_regstate; begin_regstate:               \
        .word 128;                                                      \
        .align 8; .global end_regstate; end_regstate:                   \
        .word 4;

// The .align 4 ensures that the signature begins at a 16-byte boundary
#define RVMODEL_DATA_BEGIN                                              \
  .align 4; .global begin_signature; begin_signature:

// The .align 4 ensures that the signature ends at a 16-byte boundary
#define RVMODEL_DATA_END                                                      \
  .align 4; .global end_signature; end_signature:  \
  RVMODEL_DATA_SECTION                                                        \

#define TESTUTIL_BASE                  0x10000
#define TESTUTIL_ADDR_BEGIN_SIGNATURE  0x00
#define TESTUTIL_ADDR_END_SIGNATURE    0x08
#define TESTUTIL_ADDR_HALT             0x10

#define RVMODEL_HALT                                                          \
        li t1, TESTUTIL_BASE;                                                 \
        /* tell simulation about location of begin_signature */               \
        la t0, begin_signature;                                               \
        sw t0, TESTUTIL_ADDR_BEGIN_SIGNATURE(t1);                             \
        /* tell simulation about location of end_signature */                 \
        la t0, end_signature;                                                 \
        sw t0, TESTUTIL_ADDR_END_SIGNATURE(t1);                               \
        /* dump signature and terminate simulation */                         \
        li t0, 1;                                                             \
        sw t0, TESTUTIL_ADDR_HALT(t1);                                        \

//RVTEST_PASS


#define RVMODEL_BOOT                                                          \
.section .text.init;                                                          \
        RVMODEL_IO_INIT

//-----------------------------------------------------------------------
// RV IO Macros (Non functional)
//-----------------------------------------------------------------------

#define RVMODEL_IO_INIT
//RVTEST_IO_WRITE_STR
#define RVMODEL_IO_WRITE_STR(_R, _STR)
//RVTEST_IO_CHECK
#define RVMODEL_IO_CHECK()
//RVTEST_IO_ASSERT_GPR_EQ
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
//RVTEST_IO_ASSERT_SFPR_EQ
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
//RVTEST_IO_ASSERT_DFPR_EQ
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#define RVMODEL_SET_MSW_INT

#define RVMODEL_CLEAR_MSW_INT

#define RVMODEL_CLEAR_MTIMER_INT

#define RVMODEL_CLEAR_MEXT_INT

#endif // _COMPLIANCE_MODEL_H

