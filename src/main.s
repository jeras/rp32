    .global _start

_start:

    li t1, 5
    li t2, 6
    mul  t3, t1, t2
    mulh t4, t1, t2

    li t1, -5
    li t2, 6
    mul  t3, t1, t2
    mulh t4, t1, t2

    li t1, -0x20000001
    li t2, -0x20000001
    mul    t3, t1, t2
    mulhsu t4, t1, t2

halt:
    li t1, 0x10000
    li t0, 1
    sw t0, 0x08(t1)

finish:
    beq t1, t1, finish
