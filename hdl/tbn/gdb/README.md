# GDB stub

This is a GDB stub written in SystemVerilog.

```bash
# create a FIFO (named pipe) file
rm gdb_stub
mkfifo gdb_stub

```

```
/opt/riscv-gcc/bin/riscv32-unknown-elf-gdb


(gdb) target remote gdb_stub
```