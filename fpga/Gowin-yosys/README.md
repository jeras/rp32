

# Netlist simulation

```sh
qrun -makelib work r5p_mouse_soc_tangnano9k.slang.v -sv ../../hdl/tbn/soc/r5p_mouse_soc_tangnano9k_tb.sv  -top r5p_mouse_soc_tangnano9k_tb
qrun ../../../yosys/techlibs/gowin/cells_sim.v r5p_mouse_soc_tangnano9k.gowin.v -sv ../../hdl/tbn/soc/r5p_mouse_soc_tangnano9k_tb.sv -top r5p_mouse_soc_tangnano9k_tb -voptargs=+acc -gui

qrun -ini ~/altera_pro/25.3.1/questa_fse/questa.ini ../../../yosys/techlibs/gowin/cells_sim.v r5p_mouse_soc_tangnano9k.gowin.v -sv ../../hdl/tbn/soc/r5p_mouse_soc_tangnano9k_tb.sv -top r5p_mouse_soc_tangnano9k_tb -voptargs=+acc -gui

iverilog -g specify ../../../yosys/techlibs/gowin/cells_sim.v r5p_mouse_soc_tangnano9k.gowin.v ../../hdl/tbn/soc/r5p_mouse_soc_tangnano9k_tb.sv

cvc64 ../../../yosys/techlibs/gowin/cells_sim.v r5p_mouse_soc_tangnano9k.gowin.v -sv ../../hdl/tbn/soc/r5p_mouse_soc_tangnano9k_tb.sv -top r5p_mouse_soc_tangnano9k_tb
```

Working netlist simulation using Yosys steps:

```tcl
procs
write_verilog -norename $PRJ.proc.v
opt
write_verilog -norename $PRJ.opt.v
```

```sh
qrun r5p_degu_soc_tangnano9k.opt.v -sv ../../hdl/tbn/soc/r5p_degu_soc_tangnano9k_tb.sv -top r5p_degu_soc_tangnano9k_tb -voptargs=+acc -gui
```