#!/usr/bin/env bash

qrun -makelib work -sv riscv_gdb_stub.sv -end -voptargs=+acc -top riscv_gdb_stub
