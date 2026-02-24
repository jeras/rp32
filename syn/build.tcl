# import yosys commands
yosys -import

puts "================================================================================"
puts "= parsing SystemVerilog using Yosys-Slang"
puts "================================================================================"

set PATH_TCB_RTL "../submodules/tcb/hdl/rtl"
set PATH_CPU_RTL "../hdl/rtl"

read_slang -D LANGUAGE_UNSUPPORTED_UNION \
$PATH_CPU_RTL/riscv/riscv_isa_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_priv_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_isa_i_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_isa_c_pkg.sv \
$PATH_CPU_RTL/riscv/rv32_csr_pkg.sv \
$PATH_CPU_RTL/riscv/rv64_csr_pkg.sv \
test.sv

#$PATH_CPU_RTL/core/r5p_gpr_2r1w.sv \
#$PATH_CPU_RTL/degu/r5p_pkg.sv \
#$PATH_CPU_RTL/degu/r5p_bru.sv \
#$PATH_CPU_RTL/degu/r5p_alu.sv \
#$PATH_CPU_RTL/degu/r5p_mdu.sv \
#$PATH_CPU_RTL/degu/r5p_lsu.sv \
#$PATH_CPU_RTL/degu/r5p_wbu.sv \
#$PATH_CPU_RTL/degu/r5p_degu_pkg.sv \
#$PATH_CPU_RTL/degu/r5p_degu.sv \

puts "================================================================================"
puts "= synthesis with Yosys"
puts "================================================================================"

hierarchy -top test

procs
opt -full

write_json test_netlist.json
write_verilog -sv test_netlist.sv
#write_rtlil test_netlist.rtlil
show

#exec netlistsvg test_netlist.json -o test_netlist.svg

delete
