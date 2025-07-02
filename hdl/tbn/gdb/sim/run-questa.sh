#!/usr/bin/env bash

DIR="../hdl"

SRC="$DIR/socket_dpi_pkg.c"
HDL="$DIR/socket_dpi_pkg.sv $DIR/gdb_server_stub.sv $DIR/gdb_server_stub_tb.sv"

TOP=gdb_server_stub_tb

#qrun -makelib work -end -voptargs=+acc -top $TOP -c $SRC -sv $HDL -gui
qrun -makelib work -end -voptargs=+acc -top $TOP -c $SRC -sv $HDL

