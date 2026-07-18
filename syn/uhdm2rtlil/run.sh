#!/bin/bash
# ============================================================================
# rp32 — synthesise every catalogued design through uhdm2rtlil and report a
# pass/fail table; co-simulate the designs that have a deterministic testbench.
#
#   export UHDM2RTLIL_ROOT=/path/to/uhdm2rtlil
#   ./run.sh
# ============================================================================
cd "$(dirname "$0")"
export R5P_RTL="$(cd ../../hdl/rtl && pwd)"
export R5P_TCB="$(cd ../../submodules/tcb/hdl/rtl && pwd 2>/dev/null || echo /nonexistent)"
source ./designs.sh

mkdir -p work
printf '%-20s  %-10s  %s\n' DESIGN SYNTH CO-SIM
printf '%-20s  %-10s  %s\n' "------" "-----" "------"

rc_all=0
for d in $(design_list); do
    design_select "$d"
    log="work/${d}.synth.log"
    out="work/${TOP}_uhdm.v"
    rm -f "$out"
    ./build.sh "$d" >"$log" 2>&1 || true
    # A netlist is only produced when synthesis actually completed.
    if [ -s "$out" ]; then
        warn=$(grep -ic 'could not resolve\|unknown signal\|used but has no driver' "$log" || true)
        if [ "$warn" -gt 0 ]; then synth="ok(${warn}w)"; else synth="ok"; fi
    else
        synth="FAIL"; rc_all=1
    fi

    cosim="-"
    if [ "$COSIM" = "yes" ] && [ "$synth" = "ok" ]; then
        if ./cosim.sh >"work/${d}.cosim.log" 2>&1; then cosim="PASS"
        else cosim="FAIL"; rc_all=1; fi
    fi
    printf '%-20s  %-10s  %s\n' "$d" "$synth" "$cosim"
done
exit $rc_all
