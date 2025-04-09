onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/mal
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/sub_req_wdt
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/sub_rsp_rdt
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/man_req_wdt
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/man_rsp_rdt
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/req_ben
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/rsp_ben
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/rsp_uns
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/sel_req_wdt
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/sel_req_rdt
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/sel_rsp_rdt
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/siz
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu_cnv/adr
add wave -noupdate -divider {New Divider}
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/PHY
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/PHY_BEN
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/PHY_SIZ
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/clk
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/rst
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/vld
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/rdy
add wave -noupdate -expand /r5p_degu_riscv_tb/tcb_ifu/req
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/rsp
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/trn
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/stl
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/idl
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/req_ren
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/dly
add wave -noupdate /r5p_degu_riscv_tb/tcb_ifu/req_ben
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/PHY}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/PHY_BEN}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/PHY_SIZ}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/clk}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/rst}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/vld}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/rdy}
add wave -noupdate -expand {/r5p_degu_riscv_tb/tcb_mem[0]/req}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/rsp}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/trn}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/stl}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/idl}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/req_ren}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/dly}
add wave -noupdate {/r5p_degu_riscv_tb/tcb_mem[0]/req_ben}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2170 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 267
configure wave -valuecolwidth 100
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
WaveRestoreZoom {1939 ns} {2401 ns}
