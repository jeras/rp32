# Simulator quirks

The HDL code for RTL and testbench can handle simulator quirks by using the following define macros
(based on VHDL standard conditional analysis identifiers).

* `TOOL_TYPE` can be of value `"SIMULATION"`, `"SYNTHESIS"`, `"FORMAL"`,
* `TOOL_VENDOR` for example `"Siemens"`, `"Veripool"`, ...
* `TOOL_NAME` for example `"questa"`, `"verilator"`, ...

TODO: use sed to extract edition/version from stdout string

`TOOL_EDITION` := "$(shell qrun -version)"
`TOOL_VERSION` := "$(shell qrun -version)"

## Questa `X` propagation

Questa is pripagating `X` to all result bit if addition operands contain `X` at any bit position.

## Vivado simulator $plusargs

Vivado simulator is not parsing `$plusargs` if the code is:

```SystemVerilog
$value$plusargs("begin_signature=%0h", begin_signature)
```

It works well with:

```SystemVerilog
$value$plusargs("begin_signature=%h", begin_signature)
```
