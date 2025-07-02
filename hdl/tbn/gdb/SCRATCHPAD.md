# Scratchpad

```sh
sudo apt install socat
```

This is a GDB stub written in SystemVerilog.

```bash
# create a FIFO (named pipe) file
rm gdb_stub
mkfifo gdb_stub

socat pty,rawer,echo=0,link=port_gdb pty,rawer,echo=0,link=port_stub

```

```
/opt/riscv-gcc/bin/riscv32-unknown-elf-gdb

source riscv_gdb_stub.cmd

(gdb) set logging enabled on
(gdb) set debug remote 1
(gdb) set arch riscv:rv32
(gdb) target remote riscv_gdb_stub
(gdb) set riscv numeric-register-names on
(gdb) info registers
(gdb) i r
(gdb) file ../../../riscof/riscof_work/rv32i_m/I/src/add-01.S/dut/dut.elf
(gdb) load
```

Manipulating registers:

```gdb
set $pc = 0x0000ff4C
```

Manipulating memory locations:

```gdb
set {int}0x0 = 0x01234567

```

Insert breakpoint:

```gdb
hbreak *0x80000030
info break
c
```

37085c7d
1308b8dd
93587800
93579801
b3e8f800
13d97800
93d79801
3369f900
93597900
93579901
b3e9f900
13da7900
93d79901
336afa00
935a7a00
93579a01
b3eafa00
13db7a00
93d79a01
336bfb00
935b7b00
93579b01
b3ebfb00
13dc7b00
93d79b01
336cfc00
935c7c00
93579c01

Verilator issue
length, *, return code
ask about str = {str, ...}



(gdb) show remote memory-read-packet-size
(gdb) show remote memory-write-packet-size


Flushing STDOUT in Questa does not help.
$fflush(32'h8000_0001);

```
    typedef byte unsigned bytes[];
    string str_hello = "Hello worls!";
    byte tmp_hello [12] = '{8'h48, 8'h65, 8'h6C, 8'h6C, 8'h6F, 8'h20, 8'h77, 8'h6F, 8'h72, 8'h6C, 8'h64, 8'h21};
    string str;
    byte unsigned tmp [];

    tmp = bytes'(str_hello);

    $display("DEBUG: tmp = %p", tmp);
    $display("DEBUG: tmp = %s", tmp);
    $display("DEBUG: tmp = %02h", tmp);
    $display("DEBUG: tmp = %0d", tmp);

    str = string'(tmp_hello);

    $display("DEBUG: str = %p"  , str);
    $display("DEBUG: str = %s"  , str);
    $display("DEBUG: str = %02h", str);
    $display("DEBUG: str = %0d" , str);
```

# Notes

```
./run-verilator.sh
%Error: riscv_gdb_stub_tb.sv:86:33: syntax error, unexpected ',', expecting IDENTIFIER-for-type
   86 |       code = $fread(buffer, fd, , 1);
      |                                 ^
        ... See the manual at https://verilator.org/verilator_doc.html?v=5.037 for more assistance.
%Error: Exiting due to 1 error(s)
./run-verilator.sh: line 6: obj_dir/Vriscv_gdb_stub_tb: No such file or directory
```


Questa GCC issue:
https://www.reddit.com/r/FPGA/comments/nfkuq6/modelsim_fatal_vsim3828_could_not_link_vsim_auto/

12898971238912389712783490823_abcdef689_02348923
12898971_23891238_97127834_90823_abcdef689_02348923