```sh
python3 -m venv .venv
source .venv/bin/activate
export LM_LICENSE_FILE=$HOME/intelFPGA_pro/License.dat
export PATH=$HOME/intelFPGA_pro/24.3.1/questa_fse/bin/:$PATH
export PATH=/opt/riscv-isa-sim/bin/:$PATH
export PATH=/opt/riscv-gcc/bin/:$PATH
export PATH=`git rev-parse --show-toplevel`/submodules/sail-riscv/build/c_emulator/:$PATH
pip3 install git+https://github.com/riscv/riscof.git@d38859f
#pip3 install -e ../submodules/riscof
riscof setup --dutname=mouse
riscof validateyaml --config=config.ini
riscof testlist --config=config.ini --suite=../submodules/riscv-arch-test/riscv-test-suite/ --env=../submodules/riscv-arch-test/riscv-test-suite/env
riscof run --config=config.ini --suite=../submodules/riscv-arch-test/riscv-test-suite/ --env=../submodules/riscv-arch-test/riscv-test-suite/env

```


Spike generating a signature:
https://github.com/riscv-software-src/riscv-isa-sim/issues/1037

```
spike --isa=RV32I -l --log-commits --instructions 8 ref.elf
```

```
/opt/riscv-gcc/bin/riscv32-unknown-elf-objdump ../dut/dut.elf -t |grep _signature
/opt/riscv-gcc/bin/riscv32-unknown-elf-objdump ../dut/dut.elf -t |grep tohost
/opt/riscv-gcc/bin/riscv32-unknown-elf-objdump ../dut/dut.elf -t |grep fromhost
```
