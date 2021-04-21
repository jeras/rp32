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

finish:
    beq t1, t1, finish
