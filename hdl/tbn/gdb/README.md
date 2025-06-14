# GDB stub

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

(gdb) set logging enabled on
(gdb) set debug remote 1
(gdb) set arch riscv:rv32
(gdb) target remote port_gdb
(gdb) set riscv numeric-register-names on
(gdb) info registers
(gdb) i r
(gdb) file ../../../riscof/riscof_work/rv32i_m/I/src/add-01.S/dut/dut.elf
(gdb) load
```

```
set $pc = 0x0000ff4C
```

Additional `maintenance` commands can be found here:

https://sourceware.org/gdb/current/onlinedocs/gdb.html/Maintenance-Commands.html

# References

https://medium.com/@tatsuo.nomura/implement-gdb-remote-debug-protocol-stub-from-scratch-2-5e3025f0e987


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