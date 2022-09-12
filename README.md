# R5P RISC-V processor family

Processors are named after [pet rodents](https://en.wikipedia.org/wiki/Rodents_as_pets) so that everybody can easily remember their names.

| core            | Mouse    | Gerbil   | Hamster  | Degu     | Rat | Chinchilla | description |
|-----------------|----------|----------|----------|----------|-----|------------|-------------|
| status          | v0.5     | idea     | v0.5     | v1.0     | TBD | TBD | |
| base            | RV32I(E) | RV32I(E) | RV32I(E) | RV32I(E) | TBD | TBD | Either RV32I(E) or RV64I |
| extensions      | -        |          | C        | C        | | | |
| pipeline stages | 1        | 2        | 2        | 2        | | | Multiple operations are done in a single state. |
| FSM states      | 2..4     | 3..5 TBD | 2        | 1        | | | |
| CPI             | 2..4≈3.5 |          | 2..4≈2.5 | =1       | | | |
| sys. bus ports  | 1 TCB    | 1 TCB    | 1 TCB    | 2 TCB    | | | |
| output ports    | comb.    | reg.     | reg.     | comb.    | | | Either combinational or registered. |
| language        | V-2001   | V-2001   | SV-2012  | SW-2012  | | | Either Verilog-2001 or SystemVerilog-2012/2017 |
| adders          | 1        | 1        | 1        | 2        | | |
| register file   | -        | -        | 1R1W     | 2R1W     | | | 
| shifter         |          |          |          | barrel   | | | Either multicycle or barrel shifter.
| multiplier      |          |          |          |          | | | Either multicycle or single cycle.
| opt. ASIC       |          |          |          |          | | |
| opt. FPGA LUT4  |          |          |          |          | | |
| opt. FPGA LUT6  |          |          |          |          | | |

## Instruction decoder

One of the main design aims was to create
a reusable instruction decoder written in SystemVerilog.
This means extensive use of SystemVerilog constructs:
* arrays, structures, unions, and enumerations,
* assignment patterns,
* don't care conditions and assignments in `case` statements.

Packed structures and enumerations are used to describe
instructions formats and instruction encodings.
The intention is to follow the ISA standard as literally as possible.

Long case statements and assignment patterns are used to
implement the instruction decoder.
Don't care values are used in both case statement conditions and
assignment patterns 

## Pipeline

The first processor using the reusable instruction decoder
has a **2-stage pipeline** and all instructions are executed
in a single clock cycle (**IPC=1**), without exceptions.

This is achieved without impractical solutions like asynchronous memories,
except for GPR register file, which is rather common.
Main memories are standard ASIC/FPGA block memories.

Staling during branches is avoided by placing both
an address incrementer and a branch adder between
the PC and the instruction memory address input.

As mentioned before GPR read is done asynchronously.

Staling during load instructions is avoided by
matching the synchronous read delay with a
write back delay for the remaining instruction,
for example arithmetic/logic instructions.
So all instructions write back into GPR with the same delay.
The data hazard is avoided by providing a bypass
in case the current instruction requires
the result from the previous instruction.

# Simulation

The code was developed with vanilla Verilator, my aim was not to cover the SystemVerilog standard.
The main two issue I had with Verilator were:
1. lack of support for *unpacked structures*, so I just used packed structures everywhere, which is a bit ugly,
2. X propagation is not simulated well, so I had to run regression tests with mapping X separately to 0 and 1.
The CPU is passing all **I** ISA tests, the **C** decoder is also in a good shape, but I avoided using it in FPGA synthesis.

# Synthesis

I synthesized the code in Vivado 2021.2 (Artix), Quartus 21.1 (Cyclone V), and LatticeDiamond/SynplifyPro (EPC5), I did not test any of the FPGA builds yet, the aim was to get past tool errors. Vivado and Quartus produced apparently reasonable results. Synplify was able to parse the code without significant warnings, but synthesis optimized everything out due to constant propagation. I suspect there are some issues with don't care values (X propagation), so in the next step I plan to test with Vivado Simulator and QuestaSim/ModelSim, and probably try to run some *netlist simulations*.

My main aim for `yosys` synthesis would be Sky130 PDK.
The CPU has a 2-stage pipeline and IPC=1 (all instructions execute in a single clock cycle, without exceptions).
The register file requires asynchronous reads, on FPGA I used distributed memories, so I had to use FPGA families which support this memory type (see above), Cyclone 10 and iCE40HX families do not support asynchonous read distributed memories.
For Sky130 I would use [DFFRAM](https://github.com/Cloud-V/DFFRAM), the 32x32-bit words (2R1W) register file.
Instruction and data closely coupled memories use standard ASIC/FPGA SRAM, so OpenRAM would be just fine.

# TODO

# Short

```bash

```

```bash
export VERILATOR_ROOT=/home/ijeras/VLSI/verilator
cd sim
make -f Makefile.verilator lint
make -f Makefile.verilator
```

# Requirements

The default script is using ModelSim (version from Altera/Intel) for simulation.

## Verilator

```Bash
export SYSTEMC_INCLUDE=/opt/systemc-2.3.3/include/
export SYSTEMC_LIBDIR=/opt/systemc-2.3.3/lib-linux64/
```

## Lattice diamond

Run license server
```bash
sudo /usr/local/diamond/3.12/ispfpga/bin/lin64/lmgrd -l /usr/local/diamond/3.12/license/license.log -c /usr/local/diamond/3.12/license/license.dat
```

Run Lattice Diamond
```bash
/usr/local/diamond/3.12/bin/lin64/diamond
```

## Ubuntu 18.04, `Quartus-lite-18.0.0.614-linux.tar`

I had some problems with the installer crashing at the end of the install process,
but apparently the tools were installed.

Some instructions:
http://www.bitsnbites.eu/installing-intelaltera-quartus-in-ubuntu-17-10/

After installing ModelSim, a symbolink link must be created:
```
cd $HOME/intelFPGA_lite/18.0/modelsim_ase
ln -s linux linux_rh60
```

# OVP simulator

[www.OVPworld.org](http://www.OVPworld.org) only provides a 32 bit version of OVPsim.
So 32 bit support must be installed on 64 bit systems.

```shell
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install libc6-i386
sudo apt-get install lib32stdc++6
sudo apt-get install lib32z1 lib32ncurses5 lib32bz2-1.0
sudo apt-get install gcc-multilib g++-multilib
```

To be able to download OVPsim, an account must be first created on OVPworld.org.
Apparently all OVPsim [download](http://www.ovpworld.org/dlp/) links
point to the same installer file.

Follow instructions in `Imperas_Installation_and_Getting_Started.pdf`.

The downloaded `OVPsim.*.exe` executable must have the executable flag set,
before beeing executed.

```shell
$ chmod +x OVPsim.20180716.0.Linux32.exe
$ sudo ./OVPsim.20180716.0.Linux32.exe
```

Type `yes` to accept the license,
and then `no` to be able to install into an alternative location.
This instructions are written for the the `/opt/OVPsim-20181114/` install path.

Environment variables must be set. Add the following lines to `settings.sh`.

```shell
export OVP_HOME=$HOME/Workplace/Imperas.20181114
. $OVP_HOME/bin/setup.sh
setupImperas -m32 $OVP_HOME
. $OVP_HOME/bin/switchRuntime.sh
switchRuntimeImperas
```


https://wiki.ubuntu.com/DebootstrapChroot
https://github.com/shoes/shoes3/wiki/Setup-an-schroot-build-environment
http://logan.tw/posts/2018/02/24/manage-chroot-environments-with-schroot/

```shell
# apt install debootstrap schroot
# vi /etc/schroot/chroot.d/bionic32
$ mkdir $HOME/Workplace/bionic32
sudo debootstrap --variant=buildd --arch i386 bionic $HOME/Workplace/bionic32 http://archive.ubuntu.com/ubuntu/
schroot -c bionic32 -u root
```

```
cat <<EOT >> /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ bionic main restricted
deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ bionic universe
deb http://archive.ubuntu.com/ubuntu/ bionic-updates universe
deb http://archive.ubuntu.com/ubuntu/ bionic multiverse
deb http://archive.ubuntu.com/ubuntu/ bionic-updates multiverse
deb http://security.ubuntu.com/ubuntu bionic-security main restricted
deb http://security.ubuntu.com/ubuntu bionic-security universe
deb http://security.ubuntu.com/ubuntu bionic-security multiverse
EOT
apt update
apt upgrade
apt install software-properties-common
add-apt-repository ppa:aelmahmoudy/ppa
add-apt-repository ppa:iztok.jeras/ppa
apt install gcc g++ verilator libsystemc-dev

```

```ini
[bionic32]
description=Ubuntu 18.04 (Bionic Beaver) 32-bit
directory=$HOME/Workplace/bionic32
personality=linux32
root-users=$USER
type=directory
users=$USER
```
