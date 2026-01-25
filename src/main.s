    .global _start

_start:

gpio:
    li x28, 0x80010000  # GPIO base address
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

# 37.037ns period is 27MHz (Tang Nano 9k)
# 27MHz/115200Hz   = 234
# 27MHz/115200Hz/2 = 117

uart:
    li x28, 0x80010040  # UART base address
    li x29, 234         # UART baudrate
    li x30, 117         # UART baudrate sample
    li x27, 0x2A        # asterisc character 0x2A='*'

    sw x29, 0x08(x28)   # TX baudrate
    sw x29, 0x28(x28)   # RX baudrate
    sw x30, 0x2C(x28)   # RX baudrate sample
    nop
    nop
    sb x27, 0x00(x28)   # TX data

finish:
    beq x0, x0, finish  # infinite loop
