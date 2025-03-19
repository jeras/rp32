```sh
python3 -m venv .venv
source .venv/bin/activate
export LM_LICENSE_FILE=$HOME/intelFPGA_pro/License.dat
export PATH="$HOME/intelFPGA_pro/24.3.1/questa_fse/bin:$PATH"
export PATH=/opt/riscv-isa-sim/bin/:$PATH
export PATH=/opt/riscv-gcc/bin/:$PATH
pip3 install git+https://github.com/riscv/riscof.git@d38859f
#pip3 install -e ../submodules/riscof
#riscof setup --dutname=mouse --refname=spike
riscof validateyaml --config=config.ini
riscof testlist --config=config.ini --suite=../submodules/riscv-arch-test/riscv-test-suite/ --env=../submodules/riscv-arch-test/riscv-test-suite/env
riscof run --config=config.ini --suite=../submodules/riscv-arch-test/riscv-test-suite/ --env=../submodules/riscv-arch-test/riscv-test-suite/env

```
