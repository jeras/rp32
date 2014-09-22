#!/bin/sh

export MODELSIM_BIN="$HOME/altera/14.0/modelsim_ase/bin"

# cleanup
rm -f code_ref.dis
rm -f sode_dut.dis

$MODELSIM_BIN/vlib work
$MODELSIM_BIN/vlog riscv_asm.sv riscv_asm_tb.sv
$MODELSIM_BIN/vsim -c -do 'run -all;quit' riscv_asm_tb
