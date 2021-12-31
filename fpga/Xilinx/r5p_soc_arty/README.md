
```
ERROR: [VRFC 10-2649] an enum variable may only be assigned the same enum typed variable or one of its values [/home/ijeras/VLSI/rp32/hdl/rtl/riscv/riscv_csr_pkg.sv:785]
ERROR: [XSIM 43-3137] "/home/ijeras/VLSI/rp32/hdl/rtl/riscv/riscv_isa_pkg.sv" Line 546. Constant value or constant expression must be used for initialization.
```

```Tcl
set_msg_config -id "VRFC 10-3447" -new_severity "WARNING"
set_msg_config -id "VRFC 10-2649" -new_severity "WARNING"
set_msg_config -id "XSIM 43-3137" -new_severity "WARNING"
```
