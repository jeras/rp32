# import yosys commands
yosys -import

puts "================================================================================"
puts "= parsing SystemVerilog using Yosys-Slang"
puts "================================================================================"

# TODO: can PRJ be inherited from the shell script?
set PRJ "r5p_degu_soc_tangnano9k"

set PATH_TCB_RTL "../../submodules/tcb/hdl/rtl"
set PATH_CPU_RTL "../../hdl/rtl"

#-D LANGUAGE_UNSUPPORTED_UNION
read_slang --top $PRJ \
-D YOSYS_SLANG \
$PATH_TCB_RTL/tcb_lite_pkg.sv \
$PATH_TCB_RTL/tcb_lite_if.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_error.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_passthrough.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_register_request.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_register_response.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_register_backpressure.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_arbiter.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_multiplexer.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_decoder.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_demultiplexer.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_logsize2byteena.sv \
$PATH_TCB_RTL/dev/gpio/tcb_dev_gpio_cdc__generic.sv \
$PATH_TCB_RTL/dev/gpio/tcb_dev_gpio.sv \
$PATH_TCB_RTL/lite_dev/gpio/tcb_lite_dev_gpio.sv \
$PATH_TCB_RTL/dev/uart/tcb_dev_uart_ser.sv \
$PATH_TCB_RTL/dev/uart/tcb_dev_uart_des.sv \
$PATH_TCB_RTL/dev/uart/tcb_dev_uart_fifo.sv \
$PATH_TCB_RTL/dev/uart/tcb_dev_uart.sv \
$PATH_TCB_RTL/lite_dev/uart/tcb_lite_dev_uart.sv \
$PATH_CPU_RTL/riscv/riscv_isa_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_priv_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_isa_i_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_isa_c_pkg.sv \
$PATH_CPU_RTL/riscv/rv32_csr_pkg.sv \
$PATH_CPU_RTL/riscv/rv64_csr_pkg.sv \
$PATH_CPU_RTL/core/r5p_gpr_2r1w.sv \
$PATH_CPU_RTL/degu/r5p_pkg.sv \
$PATH_CPU_RTL/degu/r5p_bru.sv \
$PATH_CPU_RTL/degu/r5p_alu.sv \
$PATH_CPU_RTL/degu/r5p_mdu.sv \
$PATH_CPU_RTL/degu/r5p_lsu.sv \
$PATH_CPU_RTL/degu/r5p_wbu.sv \
$PATH_CPU_RTL/degu/r5p_degu_pkg.sv \
$PATH_CPU_RTL/degu/r5p_degu.sv \
$PATH_CPU_RTL/soc/r5p_soc_memory__gowin_inference.sv \
$PATH_CPU_RTL/soc/r5p_degu_soc_top.sv \
$PATH_CPU_RTL/fpga/gowin/r5p_degu_soc_tangnano9k.sv

#hierarchy -top $PRJ

puts "================================================================================"
puts "= synthesis with Yosys/Apicula"
puts "================================================================================"

#procs
#write_verilog -norename $PRJ.proc.v
#opt
#write_verilog -norename $PRJ.opt.v

#help synth_gowin

#synth_gowin -family gw1n -json $PRJ.json

#synth_gowin -noflatten -run :coarse -json $PRJ.json
#write_verilog -norename $PRJ.coarse.v
#synth_gowin -noflatten -run :map_ram -json $PRJ.json
#write_verilog -norename $PRJ.map_ram.v


#    begin:
        read_verilog -specify -lib +/gowin/cells_sim.v
        read_verilog -specify -lib +/gowin/cells_xtra_gw1n.v
        hierarchy -check -top $PRJ
#
#    coarse:
#        proc
#        flatten    (unless -noflatten)
        tribuf -logic
        deminout
        opt_expr
        opt_clean
        check
        opt -nodffe -nosdff
        fsm
        opt
        wreduce
        peepopt
        opt_clean
        share
##        techmap -map +/mul2dsp.v [...]    (unless -nodsp and if -family gw1n or gw2a)
##        techmap -map +/gowin/dsp_map.v    (unless -nodsp and if -family gw1n or gw2a)

        techmap -map +/mul2dsp.v -D DSP_A_MAXWIDTH=36 -D DSP_B_MAXWIDTH=36 -D DSP_A_MINWIDTH=22 -D DSP_B_MINWIDTH=22 -D DSP_NAME=\$__MUL36X36
		chtype -set \$mul t:\$__soft_mul
        techmap -map +/mul2dsp.v -D DSP_A_MAXWIDTH=18 -D DSP_B_MAXWIDTH=18 -D DSP_A_MINWIDTH=10 -D DSP_B_MINWIDTH=4  -D DSP_NAME=\$__MUL18X18
		chtype -set \$mul t:\$__soft_mul
        techmap -map +/mul2dsp.v -D DSP_A_MAXWIDTH=18 -D DSP_B_MAXWIDTH=18 -D DSP_A_MINWIDTH=4  -D DSP_B_MINWIDTH=10 -D DSP_NAME=\$__MUL18X18
		chtype -set \$mul t:\$__soft_mul
        techmap -map +/mul2dsp.v -D DSP_A_MAXWIDTH=9  -D DSP_B_MAXWIDTH=9  -D DSP_A_MINWIDTH=4  -D DSP_B_MINWIDTH=4  -D DSP_NAME=\$__MUL9X9
		chtype -set \$mul t:\$__soft_mul
		techmap -map +/gowin/dsp_map.v

        alumacc
        opt
#        memory -nomap
        opt_clean

#    map_ram:
#        memory_libmap -lib +/gowin/lutrams.txt -lib +/gowin/brams.txt [-no-auto-block] [-no-auto-distributed]    (-no-auto-block if -nobram, -no-auto-distributed if -nolutram)
#        techmap -map +/gowin/lutrams_map.v -map +/gowin/brams_map.v
#
#    map_ffram:
#        opt -fast -mux_undef -undriven -fine
#        memory_map
#        opt -undriven -fine
#
#    map_gates:
        techmap -map +/techmap.v -map +/gowin/arith_map.v
#        opt -fast
#        abc -dff -D 1    (only if -retime)
#        iopadmap -bits -inpad IBUF O:I -outpad OBUF I:O -toutpad TBUF ~OEN:I:O -tinoutpad IOBUF ~OEN:O:I:IO    (unless -noiopads)
#
#    map_ffs:
#        opt_clean
#        dfflegalize -cell $_DFF_?_ 0 -cell $_DFFE_?P_ 0 -cell $_SDFF_?P?_ r -cell $_SDFFE_?P?P_ r -cell $_DFF_?P?_ r -cell $_DFFE_?P?P_ r -cell $_DLATCH_?_ x -cell $_DLATCH_?P?_ x
#        techmap -map +/gowin/cells_map.v
#        techmap -map +/gowin/cells_latch.v
#        opt_expr -mux_undef
#        simplemap
#
#    map_luts:
#        sort
#        read_verilog -icells -lib -specify +/abc9_model.v
#        abc9 -maxlut 8 -W 500
#        clean
#
#    map_cells:
#        techmap -map +/gowin/cells_map.v
#        opt_lut_ins -tech gowin
#        setundef -undriven -params -zero    (only if -setundef)
#        hilomap -singleton -hicell VCC V -locell GND G
#        splitnets -ports    (only if -vout)
#        clean
        autoname
#
#    check:
#        hierarchy -check
#        stat
#        check -noinit
#        blackbox =A:whitebox
#
#    vout:
#        write_verilog -simple-lhs -decimal -attr2comment -defparam -renameprefix gen <file-name>
#        write_json <file-name>
#

write_verilog -norename $PRJ.custom.v
