# GDB stub

This is a GDB stub written in SystemVerilog.

```bash
# create a FIFO (named pipe) file
rm gdb_stub
mkfifo gdb_stub

socat pty,rawer,echo=0,link=port_gdb pty,rawer,echo=0,link=port_stub

```

```
/opt/riscv-gcc/bin/riscv32-unknown-elf-gdb

(gdb) set logging enabled on
(gdb) set debug remote 1
(gdb) set arch riscv:rv32
(gdb) target remote port_gdb
(gdb) info registers
(gdb) i r
(gdb) file ../../../riscof/riscof_work/rv32i_m/I/src/add-01.S/dut/dut.elf
(gdb) load
```

Additional `maintenance` commands can be found here:

https://sourceware.org/gdb/current/onlinedocs/gdb.html/Maintenance-Commands.html


00000000
00000000
00000000
00000000

00000000
00000000
00000000
00000000

00000000
00000000
00000000
00000000

00000000
00000000
00000000
00000000

00000000
00000000
00000000
00000000

00000000
00000000
00000000
00000000

00000000
00000000
00000000
00000000

00000000
00000000
00000000
00000000

00000000


# References

https://medium.com/@tatsuo.nomura/implement-gdb-remote-debug-protocol-stub-from-scratch-2-5e3025f0e987
