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

    li t0, 0x00000000  # pointer
    li t1, 0x00000000  # value
    li t2, 0x00000003  # counter

write:
    sw t1, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 1
    addi t2, t2, -1
    bnez t2, write   # branch non equal zero

    li t0, 0x00000000  # pointer
    li t1, 0x00000000  # value
    li t2, 0x00000003  # counter

read:
    lw t1, 0(t0)
    addi t0, t0, 4
    addi t2, t2, -1
    bnez t2, read   # branch non equal zero

finish:
    beq t1, t1, finish
