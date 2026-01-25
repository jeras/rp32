    .global _start

_start:
    li x28, 0x80200000  # GPIO base address
    li x29, 0x01234567  # GPIO output
    li x30, 0xFFFFFFFF  # GPIO input/output enable (all enabled)

    sw x30, 0x0(x28)    # write GPIO output enable
    sw x30, 0x8(x28)    # write GPIO input enable
    sw x29, 0x4(x28)    # write GPIO output data
    nop
    nop
    nop
    nop
    lw x31, 0xC(x28)    # read GPIO input data

finish:
    beq x0, x0, finish  # infinite loop
