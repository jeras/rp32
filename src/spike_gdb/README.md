# Spike + GDB

https://github.com/riscv-software-src/riscv-isa-sim?tab=readme-ov-file#debugging-with-gdb

```sh
export PATH=/opt/riscv-isa-sim/bin/:$PATH
export PATH=/opt/riscv-gcc/bin/:$PATH
```

```sh
riscv32-unknown-elf-gcc -g -Og -o rot13-32.o -c rot13.c
riscv32-unknown-elf-gcc -g -Og -T spike.lds -nostartfiles -o rot13-32 rot13-32.o
spike --isa=rv32imafdc --rbb-port=9824 -m0x10100000:0x20000 rot13-32
```

```sh
openocd -f spike.cfg
```

```sh
riscv32-unknown-elf-gdb rot13-32
```