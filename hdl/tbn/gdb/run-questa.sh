#!/usr/bin/env bash

#qrun -makelib work -sv riscv_gdb_stub.sv -end -voptargs=+acc -top riscv_gdb_stub
qrun -makelib work -end -voptargs=+acc -top riscv_gdb_stub_tb -64 \
-sv socket_dpi_pkg.sv -c socket_dpi_pkg.c -sv riscv_gdb_stub_tb.sv

