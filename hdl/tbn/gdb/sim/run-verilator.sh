#!/usr/bin/env bash

DIR="../hdl"

SRC="$DIR/socket_dpi_pkg.c"
HDL="$DIR/socket_dpi_pkg.sv $DIR/gdb_server_stub.sv $DIR/gdb_server_stub_tb.sv"

TOP=gdb_server_stub_tb

verilator --timing --binary --top $TOP $SRC $HDL
obj_dir/V$TOP
