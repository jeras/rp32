# import yosys commands
yosys -import

puts "================================================================================"
puts "= parsing SystemVerilog using Yosys-Slang"
puts "================================================================================"

# TODO: can PRJ be inherited from the shell script?
set PRJ "r5p_mouse_soc_simple_tangnano9k"

set PATH_R5P_RTL "../../hdl/rtl"

read_verilog -sv \
-D YOSYS_STRINGPARAM \
$PATH_R5P_RTL/mouse/r5p_mouse.sv \
$PATH_R5P_RTL/soc/r5p_mouse_soc_simple_top.sv \
$PATH_R5P_RTL/fpga/gowin/r5p_mouse_soc_simple_tangnano9k.sv

#hierarchy -top $PRJ

write_verilog $PRJ.slang.v

puts "================================================================================"
puts "= synthesis with Yosys/Apicula"
puts "================================================================================"

#synth_gowin -top ${PRJ} -json $PRJ.json


#    begin:
        read_verilog -specify -lib +/gowin/cells_sim.v
        read_verilog -specify -lib +/gowin/cells_xtra_gw1n.v
        hierarchy -check -top $PRJ
#
#    coarse:
        procs
#        flatten
        flatten -separator _
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
        memory -nomap
        opt_clean

#    map_ram:
        memory_libmap -lib +/gowin/lutrams.txt -lib +/gowin/brams.txt
        techmap -map +/gowin/lutrams_map.v -map +/gowin/brams_map.v

#    map_ffram:
        opt -fast -mux_undef -undriven -fine
        memory_map
        opt -undriven -fine

#    map_gates:
        techmap -map +/techmap.v -map +/gowin/arith_map.v
        opt -fast
#        abc -dff -D 1    (only if -retime)
        iopadmap -bits -inpad IBUF O:I -outpad OBUF I:O -toutpad TBUF ~OEN:I:O -tinoutpad IOBUF ~OEN:O:I:IO

#    map_ffs:
        opt_clean
        dfflegalize -cell \$_DFF_?_ 0 -cell \$_DFFE_?P_ 0 -cell \$_SDFF_?P?_ r -cell \$_SDFFE_?P?P_ r -cell \$_DFF_?P?_ r -cell \$_DFFE_?P?P_ r -cell \$_DLATCH_?_ x -cell \$_DLATCH_?P?_ x
        techmap -map +/gowin/cells_map.v
        techmap -map +/gowin/cells_latch.v
        opt_expr -mux_undef
        simplemap

#    map_luts:
        sort
        read_verilog -icells -lib -specify +/abc9_model.v
        abc9 -maxlut 8 -W 500
        clean

#    map_cells:
        techmap -map +/gowin/cells_map.v
        opt_lut_ins -tech gowin
#        setundef -undriven -params -zero    (only if -setundef)
        hilomap -singleton -hicell VCC V -locell GND G
#        splitnets -ports    (only if -vout)
        clean
        autoname

#    check:
        hierarchy -check
        stat
        check -noinit
        blackbox =A:whitebox

#    vout:
        write_verilog -simple-lhs -decimal -attr2comment -defparam -renameprefix gen $PRJ.netlist.v
        write_json $PRJ.json
