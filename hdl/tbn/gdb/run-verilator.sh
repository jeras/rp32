#!/usr/bin/env bash

verilator --timing --binary --top riscv_gdb_stub riscv_gdb_stub.sv
obj_dir/Vriscv_gdb_stub
