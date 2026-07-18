#!/bin/bash
# ============================================================================
# rp32 — synthesise a design through the UHDM/Surelog front end (uhdm2rtlil)
# ============================================================================
#
# Runs the Surelog SystemVerilog front end in-process (`read_sv`, from the
# uhdm2rtlil plugin) and synthesises an rp32 design to a gate-level netlist
# under ./work/  (r5p_<top>_uhdm.v / .json).
#
# Prerequisite: a built uhdm2rtlil checkout
# (https://github.com/alainmarcel/uhdm2rtlil).  Point UHDM2RTLIL_ROOT at it
# (defaults to ~/uhdm2rtlil):
#
#   export UHDM2RTLIL_ROOT=/path/to/uhdm2rtlil
#   ./build.sh                                    # default: Mouse simple SoC
#   R5P_TOP=r5p_mouse \
#     R5P_SRCS="$PWD/../../hdl/rtl/mouse/r5p_mouse.sv" ./build.sh
#
# Environment overrides:
#   R5P_TOP    top module          (default r5p_mouse_soc_simple_top)
#   R5P_SRCS   source file list     (default: mouse core + simple SoC)
#   R5P_OUT    output basename      (default <top>_uhdm)
#   R5P_RENAME rename the netlist top to this (default: none) — used by the
#              co-sim so the gate netlist and the RTL can share a Verilator build
#
# --- memory-preserving flow -------------------------------------------------
# A design with an initialised ROM/RAM (`$readmemh`) must NOT be run through the
# plain `synth`/`synth_*` shortcut: those run `opt_mem`, which trims an
# initialised memory to its "used" width and MANGLES the `$meminit` constant
# (e.g. 0x800200B7 -> garbage), so the fetched program reads back wrong.  We
# drive the passes explicitly and keep the init:
#     read_sv -> proc -> flatten -> memory_collect  (NO opt_mem / memory -nomap)
# `flatten` before `memory_collect` is what lets the $readmemh init reach the
# combinational read port.  See the uhdm2rtlil CLAUDE.md
# "Debugging X-Propagation in the rp32 SoC" notes.
set -euo pipefail
cd "$(dirname "$0")"

R5P_RTL="$(cd ../../hdl/rtl && pwd)"
ROOT="${UHDM2RTLIL_ROOT:-$HOME/uhdm2rtlil}"
YOSYS="$ROOT/out/current/bin/yosys"
PLUGIN="$ROOT/build/uhdm2rtlil.so"

for f in "$YOSYS" "$PLUGIN"; do
    if [ ! -e "$f" ]; then
        echo "ERROR: $f not found." >&2
        echo "Set UHDM2RTLIL_ROOT to a built uhdm2rtlil checkout (currently '$ROOT')." >&2
        exit 1
    fi
done

TOP="${R5P_TOP:-r5p_mouse_soc_simple_top}"
OUT="${R5P_OUT:-${TOP}_uhdm}"
SRCS="${R5P_SRCS:-$R5P_RTL/mouse/r5p_mouse.sv $R5P_RTL/soc/r5p_mouse_soc_simple_top.sv}"

mkdir -p work
# The SoC reads its boot image via $readmemh("mem_if.mem", ...); provide it.
cp -f boot.hex work/mem_if.mem

echo "== uhdm2rtlil: $ROOT"
echo "== top:        $TOP"

( cd work && "$YOSYS" -m "$PLUGIN" -p "
    read_sv -parse -nobuiltin $SRCS
    hierarchy -check -top $TOP
    proc
    flatten
    memory_collect
    opt -full
    techmap
    opt
    dfflegalize -cell \$_DFF_P_ 0 -cell \$_DFF_PP0_ 0 -cell \$_DFF_PP1_ 0 \
                -cell \$_DFFE_PP0P_ 0 -cell \$_DFFE_PP1P_ 0
    abc -g AND,NAND,OR,NOR,XOR,XNOR,ANDNOT,ORNOT,MUX
    opt_clean
    ${R5P_RENAME:+rename $TOP $R5P_RENAME}
    stat
    write_verilog -noattr ${OUT}.v
    write_json ${OUT}.json
" )

echo "== netlist written: $(pwd)/work/${OUT}.v"
