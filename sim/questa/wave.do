onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /r5p_mouse_riscv_tb/dut/clk
add wave -noupdate /r5p_mouse_riscv_tb/dut/rst
add wave -noupdate /r5p_mouse_riscv_tb/dut/ctl_fsm
add wave -noupdate /r5p_mouse_riscv_tb/dut/ctl_pha
add wave -noupdate -divider {New Divider}
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/mal
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/sub_req_wdt
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/sub_rsp_rdt
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/man_req_wdt
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/man_rsp_rdt
add wave -noupdate -radix binary /r5p_mouse_riscv_tb/tcb_cnv/req_ben
add wave -noupdate -radix binary /r5p_mouse_riscv_tb/tcb_cnv/rsp_ben
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/rsp_uns
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/req_sel
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/rsp_sel
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/siz
add wave -noupdate /r5p_mouse_riscv_tb/tcb_cnv/adr
add wave -noupdate -divider {New Divider}
add wave -noupdate /r5p_mouse_riscv_tb/tcb/clk
add wave -noupdate /r5p_mouse_riscv_tb/tcb/rst
add wave -noupdate /r5p_mouse_riscv_tb/tcb/vld
add wave -noupdate /r5p_mouse_riscv_tb/tcb/rdy
add wave -noupdate -expand /r5p_mouse_riscv_tb/tcb/req
add wave -noupdate /r5p_mouse_riscv_tb/tcb/rsp
add wave -noupdate /r5p_mouse_riscv_tb/tcb/trn
add wave -noupdate /r5p_mouse_riscv_tb/tcb/stl
add wave -noupdate /r5p_mouse_riscv_tb/tcb/idl
add wave -noupdate /r5p_mouse_riscv_tb/tcb/req_ren
add wave -noupdate /r5p_mouse_riscv_tb/tcb/dly
add wave -noupdate /r5p_mouse_riscv_tb/tcb/req_ben
add wave -noupdate -divider {New Divider}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/clk}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/rst}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/vld}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/rdy}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/req}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/rsp}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/trn}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/stl}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/idl}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/req_ren}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/dly}
add wave -noupdate {/r5p_mouse_riscv_tb/tcb_mem[0]/req_ben}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10770 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 352
configure wave -valuecolwidth 227
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {10477 ns} {10906 ns}
