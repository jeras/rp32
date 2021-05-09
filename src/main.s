    .global _start

_start:

    li x29, 6
    li x30, 3
    divu  x31, x29, x30

halt:
    li t1, 0x10000
    li t0, 1
    sw t0, 0x08(t1)

finish:
    beq t1, t1, finish
