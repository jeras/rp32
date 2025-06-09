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
(gdb) target remote port_gdb
```

"qSupported:multiprocess+;swbreak+;hwbreak+;qRelocInsn+;fork-events+;vfork-events+;exec-events+;vContSupported+;QThreadEvents+;QThreadOptions+;no-resumed+;memory-tagging+"


# References

https://medium.com/@tatsuo.nomura/implement-gdb-remote-debug-protocol-stub-from-scratch-2-5e3025f0e987