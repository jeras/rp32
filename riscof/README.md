```sh
python3 -m venv .venv
source .venv/bin/activate
pip3 install git+https://github.com/riscv/riscof.git@d38859f
riscof setup --dutname=mouse --refname=spike
```
