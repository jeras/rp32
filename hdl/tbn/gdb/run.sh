#!/usr/bin/env bash

verilator --timing --binary --top riscv_gdb_stub riscv_gdb_stub.sv
obj_dir/Vriscv_gdb_stub

#qrun -makelib work -sv riscv_gdb_stub.sv -end -voptargs=+acc -top riscv_gdb_stub
