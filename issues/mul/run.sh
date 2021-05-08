verilator --cc mul.sv --exe main.cpp
make -j -C obj_dir -f Vmul.mk Vmul
obj_dir/Vmul

