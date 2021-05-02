#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

// The .align 4 ensures that the signature begins at a 16-byte boundary
#define RVMODEL_DATA_BEGIN                                              \
  .align 4; .global begin_signature; begin_signature:

// The .align 4 ensures that the signature ends at a 16-byte boundary
#define RVMODEL_DATA_END                                                      \
  .align 4; .global end_signature; end_signature:

//RVMODEL_BOOT
//-----------------------------------------------------------------------
// RV Compliance Macros
//-----------------------------------------------------------------------

#define TESTUTIL_BASE 0x10000
#define TESTUTIL_ADDR_HALT             0x0
#define TESTUTIL_ADDR_BEGIN_SIGNATURE  0x4
#define TESTUTIL_ADDR_END_SIGNATURE    0x8

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

#define RVMODEL_BOOT

#endif // _COMPLIANCE_MODEL_H

//-----------------------------------------------------------------------
// RV IO Macros (Non functional)
//-----------------------------------------------------------------------

#ifndef _COMPLIANCE_IO_H
#define _COMPLIANCE_IO_H

#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_SP, _STR)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_SP, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

//-----------------------------------------------------------------------
//
//-----------------------------------------------------------------------

#define RVMODEL_SET_MSW_INT

#define RVMODEL_CLEAR_MSW_INT

#define RVMODEL_CLEAR_MTIMER_INT

#define RVMODEL_CLEAR_MEXT_INT



#endif // _COMPLIANCE_IO_H
