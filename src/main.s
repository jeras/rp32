    .global _start

_start:

    li t0, 0x00001000

    andi t1, t1, 0
    addi t1, t1, 0x48  # H
    sw t1, 0(t0)

    andi t1, t1, 0
    addi t1, t1, 0x65  # e
    sw t1, 0(t0)

    andi t1, t1, 0
    addi t1, t1, 0x6c  # l
    sw t1, 0(t0)

    andi t1, t1, 0
    addi t1, t1, 0x6c  # l
    sw t1, 0(t0)

    andi t1, t1, 0
    addi t1, t1, 0x6f  # o
    sw t1, 0(t0)

    andi t1, t1, 0
    addi t1, t1, 0x0a  # \n
    sw t1, 0(t0)

    nop

    fence
    li t0, 0x00000000  # pointer
    li t1, 0x00000000  # value
    li t2, 0x00000003  # counter
write:
    sw t1, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 1
    addi t2, t2, -1
    bnez t2, write   # branch non equal zero

    fence
    li t0, 0x00000000  # pointer
    li t1, 0x00000000  # value
    li t2, 0x00000003  # counter
read:
    lw t1, 0(t0)
    addi t0, t0, 4
    addi t2, t2, -1
    bnez t2, read   # branch non equal zero

test_write:
    fence
    li t0, 0x00000000  # pointer
    li t1, 0x76543210  # value

    sb t1, 0(t0)
    sb t1, 1(t0)
    sb t1, 2(t0)
    sb t1, 3(t0)

    sh t1, 0(t0)
    sh t1, 1(t0)
    sh t1, 2(t0)
    sh t1, 3(t0)

    sw t1, 0(t0)
    sw t1, 1(t0)
    sw t1, 2(t0)
    sw t1, 3(t0)

test_read:
    fence
    li t0, 0x00000000  # pointer
    li t1, 0x76543210  # value
    sw t1, 0(t0)

    lb t2, 0(t0)
    lb t2, 1(t0)
    lb t2, 2(t0)
    lb t2, 3(t0)

    lh t2, 0(t0)
    lh t2, 1(t0)
    lh t2, 2(t0)
    lh t2, 3(t0)

    lw t2, 0(t0)
    lw t2, 1(t0)
    lw t2, 2(t0)
    lw t2, 3(t0)

finish:
    beq t1, t1, finish
