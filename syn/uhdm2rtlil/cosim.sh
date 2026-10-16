#!/bin/bash
# ============================================================================
# rp32 — gate-level co-simulation: RTL vs uhdm2rtlil-synthesized netlist
# ============================================================================
#
# Synthesises an r5p_mouse SoC through uhdm2rtlil (top renamed to *_gate), then
# uses Verilator to run the original RTL and the gate netlist side by side under
# the same boot program, comparing outputs every cycle.  This is the gate-level
# equivalence check for the Yosys/UHDM flow — the same methodology uhdm2rtlil
# uses for designs the native Verilog front end can't parse (co-simulate the
# synthesized netlist against the RTL).
#
# Works for any COSIM="yes" SoC in designs.sh whose top ports match cosim_tb.sv
# (clk/rst/gpio_o/gpio_e/gpio_i/uart_txd/uart_rxd) — currently the discrete
# `mouse_soc_simple` and the TCB-interface `mouse_soc`.
#
#   export UHDM2RTLIL_ROOT=/path/to/uhdm2rtlil   # built checkout (default ~/uhdm2rtlil)
#   ./cosim.sh [design] [cycles]                 # design default: mouse_soc_simple
#
set -euo pipefail
cd "$(dirname "$0")"

ROOT="${UHDM2RTLIL_ROOT:-$HOME/uhdm2rtlil}"
SIMCELLS="$ROOT/out/current/share/yosys/simcells.v"
export R5P_RTL="$(cd ../../hdl/rtl && pwd)"
export R5P_TCB="$(cd ../../submodules/tcb/hdl/rtl && pwd 2>/dev/null || echo /nonexistent)"
source ./designs.sh

DESIGN="${1:-mouse_soc_simple}"
CYCLES="${2:-6000}"
design_select "$DESIGN"          # sets TOP and SRCS (the RTL source list)
GATE="${TOP}_gate"

command -v verilator >/dev/null || { echo "ERROR: verilator not found in PATH" >&2; exit 1; }
[ -e "$SIMCELLS" ] || { echo "ERROR: $SIMCELLS not found (build uhdm2rtlil / set UHDM2RTLIL_ROOT)" >&2; exit 1; }

# 1. synthesise the SoC to a FLAT gate netlist with the top renamed to *_gate
#    (flat, so its submodules don't collide with the RTL sources in Verilator).
echo "== [1/2] synthesising $DESIGN ($TOP) via uhdm2rtlil (-> $GATE)"
R5P_OUT="cosim_gate" R5P_RENAME="$GATE" ./build.sh "$DESIGN" >work/cosim_synth.log 2>&1 \
    || { echo "ERROR: synthesis failed; see work/cosim_synth.log" >&2; tail -20 work/cosim_synth.log; exit 1; }

# 2. build + run the Verilator co-sim (RTL + gate netlist + Yosys gate cells).
# The RTL side runs `$readmemh("mem_if.mem", ...)` relative to Vtb's cwd (here);
# the gate netlist already has the boot image baked in as memory init.  The same
# cosim_tb.sv serves every SoC — cosim.sh passes the RTL/gate module names via
# +define+ (defaults in the .sv keep it usable standalone).
echo "== [2/2] Verilator co-sim ($CYCLES cycles)"
cp -f boot.hex mem_if.mem
rm -rf work/obj_dir
verilator --cc --exe --build -j 4 \
    -Wno-fatal -Wno-WIDTH -Wno-UNUSED -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE \
    -Wno-MULTIDRIVEN -Wno-BLKANDNBLK -Wno-DECLFILENAME -Wno-PINMISSING \
    "+define+TOP_RTL=$TOP" "+define+TOP_GATE=$GATE" \
    --top-module tb --Mdir work/obj_dir \
    cosim_tb.sv \
    $SRCS \
    work/cosim_gate.v \
    "$SIMCELLS" \
    cosim_main.cpp

./work/obj_dir/Vtb "$CYCLES"
