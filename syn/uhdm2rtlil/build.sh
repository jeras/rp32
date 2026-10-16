#!/bin/bash
# ============================================================================
# rp32 — synthesise a design through the UHDM/Surelog front end (uhdm2rtlil)
# ============================================================================
#
# Runs the Surelog SystemVerilog front end in-process (`read_sv`, from the
# uhdm2rtlil plugin) and synthesises an rp32 design to a gate-level netlist
# under ./work/  (<top>_uhdm.v / .json).
#
#   export UHDM2RTLIL_ROOT=/path/to/uhdm2rtlil   # built checkout (default ~/uhdm2rtlil)
#   ./build.sh [design]        # design from designs.sh (default mouse_soc_simple)
#   ./build.sh --list          # list known designs
#
# See designs.sh for the design catalog (cores + SoCs).  R5P_RENAME renames the
# netlist top (used by cosim.sh so RTL and gate can share a Verilator build).
#
# --- memory-preserving flow -------------------------------------------------
# A design with an initialised ROM/RAM (`$readmemh`) must NOT be run through the
# plain `synth`/`synth_*` shortcut: those run `opt_mem`, which trims an
# initialised memory to its "used" width and MANGLES the `$meminit` constant
# (0x800200B7 -> garbage) and maps the RAM to hundreds of thousands of FFs.  We
# drive the passes explicitly and keep the init:
#     read_sv -> proc -> flatten -> memory_collect  (NO opt_mem / memory -nomap)
# `flatten` before `memory_collect` lets the $readmemh init reach the read port.
set -euo pipefail
cd "$(dirname "$0")"

export R5P_RTL="$(cd ../../hdl/rtl && pwd)"
export R5P_TCB="$(cd ../../submodules/tcb/hdl/rtl && pwd 2>/dev/null || echo /nonexistent)"
source ./designs.sh

if [ "${1:-}" = "--list" ]; then design_list; exit 0; fi

DESIGN="${1:-mouse_soc_simple}"
design_select "$DESIGN"
OUT="${R5P_OUT:-${TOP}_uhdm}"

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
if [ ! -d "$R5P_TCB" ]; then
    echo "NOTE: TCB submodule not initialised (needed for degu/full SoCs):" >&2
    echo "      git submodule update --init submodules/tcb" >&2
fi

mkdir -p work
# SoCs read their boot image via $readmemh("mem_if.mem", ...); provide it.
cp -f boot.hex work/mem_if.mem

echo "== uhdm2rtlil: $ROOT"
echo "== design:     $DESIGN  (top $TOP)"

( cd work && "$YOSYS" -m "$PLUGIN" -p "
    read_sv -parse -nobuiltin -top $TOP $SRCS
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
