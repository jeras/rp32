    .global _start

_start:
    li x28, 0x00004000  # GPIO base address
    li x29, 0x01234567  # GPIO output
    li x30, 0xFFFFFFFF  # GPIO output enable (all enabled)
    sw x29, 0x0(x28)    # write GPIO output
    sw x30, 0x4(x28)    # write GPIO output enable
    lw x31, 0x8(x28)    # read GPIO input

finish:
    beq t1, t1, finish  # infinite loop
