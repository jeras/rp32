#!/usr/bin/env bash

#verilator --timing --binary --top riscv_gdb_stub riscv_gdb_stub.sv
#obj_dir/Vriscv_gdb_stub
verilator --timing --binary --top riscv_gdb_stub_tb riscv_gdb_stub_tb.sv socket_dpi_pkg.sv socket_dpi_pkg.c
#obj_dir/Vriscv_gdb_stub_tb
