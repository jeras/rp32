# RISCOF

RISC-V ISA unit testing using the RISCOF framework.

## Requirements

Follow the [RISCOF Quickstart guide](https://riscof.readthedocs.io/en/stable/installation.html)
to install a RV32 GCC, and reference simulators Spike and/or Sail.

### RISC-V GCC compiler

It can be compiled from sources, extracted from a tarball or
installed using a Linux distribution package manager.

For this instructions, GCC is expected to be installed into `/opt/riscv-gcc`.
If installed elsewhere, use a different `PATH` environment variable setting later in the instructions.

### RISC-V Spike simulator

This is currently the preferred simulator, mostly because it is easier to install than Sail.

NOTE: The current execution trace log created by the HDL simulation only matches the Spike simulator.

### RISC-V Sail simulator

Either compile from sources following the [official instructions](https://github.com/riscv/sail-riscv?tab=readme-ov-file#building-the-model),
or preferably download a precompiled release tarball.

NOTE: Support for execution trace log compatible with Sail might be added in the future.

## Setting up the environment

Setup the `python3` virtual environment and install a working version of RISCOF.

```sh
cd riscof
python3 -m venv .venv
source .venv/bin/activate
pip3 install git+https://github.com/riscv/riscof.git@d38859f
```

Setup the `PATH` environment variable to gain access to tool executables.

```sh
../settings-questa.sh
../settings-vivado.sh
export PATH=/opt/riscv-isa-sim/bin/:$PATH
export PATH=/opt/riscv-gcc/bin/:$PATH
export PATH=`git rev-parse --show-toplevel`/submodules/sail-riscv/build/c_emulator/:$PATH
```

To exit the virtual environment:

```sh
deactivate
```

To reenter an existing virtual environment, just redo the activation:

```sh
source .venv/bin/activate
```

In a reactivated virtual environment the `PATH`
environmental variable updates must be rerun.

## Running RISCOF tests

To run the tests inside the virtual environment execute:

```sh
riscof run --config=config-mouse.ini --suite=../submodules/riscv-arch-test/riscv-test-suite/ --env=../submodules/riscv-arch-test/riscv-test-suite/env
```

Currently only `mouse` and `degu` CPUs are available for testing.

## Implementation details



## Debugging

