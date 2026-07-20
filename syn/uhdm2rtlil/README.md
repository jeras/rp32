# rp32 — Yosys synthesis via UHDM/Surelog (uhdm2rtlil)

This directory adds a **Yosys synthesis flow driven by the Surelog SystemVerilog
front end** ([uhdm2rtlil](https://github.com/alainmarcel/uhdm2rtlil)), alongside
the existing `syn/` (Yosys‑slang) and `fpga/*/yosys` flows.

Surelog parses the design to UHDM and the uhdm2rtlil plugin imports it to Yosys
RTLIL (`read_sv`), so the full IEEE‑1800 SystemVerilog the rp32 cores use
(packages, structs, interfaces) is synthesisable through Yosys.

The gate‑level result is **verified by co‑simulation**: the synthesized netlist
is run against the original RTL under Verilator and the outputs are compared
every cycle — the same methodology uhdm2rtlil uses for designs the native Yosys
Verilog front end cannot parse.

## Prerequisites

* A **built** [uhdm2rtlil](https://github.com/alainmarcel/uhdm2rtlil) checkout
  (provides `out/current/bin/yosys`, `build/uhdm2rtlil.so`, and the Yosys
  `simcells.v`).  Point `UHDM2RTLIL_ROOT` at it (defaults to `~/uhdm2rtlil`):

  ```bash
  export UHDM2RTLIL_ROOT=/path/to/uhdm2rtlil
  ```

* **Verilator 5.x** in `PATH` (for the co‑simulation) — the repo's
  `submodules/verilator` build works; see `settings-verilator.sh`.

## Usage

```bash
cd syn/uhdm2rtlil

./build.sh --list             # list the catalogued designs
./build.sh mouse_soc_simple   # synthesise one design (work/<top>_uhdm.v/.json)
./cosim.sh                    # gate-level co-sim of the Mouse simple SoC
./run.sh                      # synthesise ALL designs + co-sim, print a table
```

The design catalog (cores + SoCs) lives in `designs.sh`; `build.sh <name>` picks
one.  The full SoCs need the TCB submodule:

```bash
git submodule update --init submodules/tcb
```

## Design status

`./run.sh` synthesises every design and co-simulates the ones with a
deterministic self-contained testbench:

| design              | synth | co-sim | notes |
|---------------------|:-----:|:------:|-------|
| `mouse`             | ✅ | (det.) | standalone core; only deterministic streams are equiv-able |
| `mouse_soc_simple`  | ✅ | ✅ **PASS** | complete Mouse SoC, inline RAM — 0 mismatches / 6000 cyc |
| `mouse_soc`         | ⚠️ | n/a | full Mouse SoC synthesises but is functionally stuck — the TCB **interface-config** struct refs (`sub.CFG.HSK.DLY`, `sub.MOD`) are unresolved (front-end limitation); Verilator can't build the interface RTL either, so no co-sim |
| `degu`              | ⚠️ | n/a | core synthesises with unresolved TCB interface-config reads |
| `degu_soc`          | ⚠️ | n/a | as above |
| `hamster`           | ⚠️ | n/a | core synthesises with unresolved decoder-struct reads (`idu_rdt.jmp.jmp`) |

✅ = clean; ⚠️ = produces a netlist but with unresolved struct/interface reads
(undriven wires ⇒ not functionally correct yet).  The remaining gaps are all
SystemVerilog-interface-config resolution in the UHDM front end.

## The memory‑preserving synthesis flow

A design with an initialised ROM/RAM (`$readmemh`) **must not** be run through
the plain `synth` / `synth_*` shortcut: those run `opt_mem`, which trims an
initialised memory to its "used" width and mangles the `$meminit` constant
(e.g. `0x800200B7` → garbage), so the fetched program reads back wrong and the
CPU never boots. `build.sh` therefore drives the passes explicitly:

```
read_sv → proc → flatten → memory_collect   (no opt_mem / memory -nomap)
        → opt -full → techmap → dfflegalize → abc → opt_clean
```

`flatten` **before** `memory_collect` is what lets the `$readmemh` init reach
the combinational read port.

## Files

| file            | purpose                                                          |
|-----------------|------------------------------------------------------------------|
| `designs.sh`    | design catalog: name → sources + top (cores + SoCs)             |
| `build.sh`      | synthesise one design through uhdm2rtlil (memory‑preserving flow)|
| `run.sh`        | synthesise all designs + co‑sim, print a status table           |
| `cosim.sh`      | synth + Verilator co‑simulation (RTL vs gate netlist)            |
| `cosim_tb.sv`   | testbench: RTL and gate netlist side by side, per‑cycle compare  |
| `cosim_main.cpp`| Verilator driver (reset, free‑run, exit non‑zero on mismatch)    |
| `boot.hex`      | tiny deterministic boot program (GPIO writes) for the SoC RAM    |

`work/` (netlists, logs, Verilator objects) is generated and git‑ignored.

## Notes

* The **complete Mouse SoC** co‑simulates cleanly because its boot program is
  deterministic. The **standalone `r5p_mouse` core** synthesises correctly too,
  but under *random* instruction stimulus it diverges on the design's own `'x`
  don't‑cares (illegal opcodes), so only a deterministic instruction stream is a
  meaningful equivalence check for it — use the SoC for the end‑to‑end gate check.
* This flow depends on two uhdm2rtlil front‑end fixes for the rp32 cores: comb
  `case` blocking‑read value threading, and byte‑enable (`mem[a][hi:lo] <= …`)
  memory‑write emission. Use a uhdm2rtlil build that includes them.
