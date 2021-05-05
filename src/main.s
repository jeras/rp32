    .global _start

_start:

ref_1:
    nop
    jal x1, halt
    li t2, 0x01234567
    nop
    jal x0, ref_1
    nop
    jalr x1, 0xc(t2)

ref_2:
    li t2, 0x89abcdef
    jalr x0, 0(x1)

ref_3:
    li x2, 0xa5a5a5a5
    nop
    jalr x0, 0(x1)

halt:
    li t1, 0x10000;
    li t0, 1;
    sw t0, 0x08(t1);

finish:
    beq t1, t1, finish
