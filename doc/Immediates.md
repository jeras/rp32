# Immediates

Except for R-type, all instruction formats carry an immediate.

| format | sign/size | notes/usage
| I | `signed [11:0]` | `JALR`, `L*` (load), `*I` (logical/arithmetic immediate), `S*I` (shifts use a shorter 5 or 6 bit immediate)
| S | `signed [11:0]` | `S*` (store)
| B | `signed [12:0]` | `B*` (branch) - the LSB bit is constant zero
| U | `signed [31:0]` | `LUI`, `AUIPC` - the lower 12 bits are constant zero 
| J | `signed [20:0]` | `JAL` - the LSB bit is constant zero

## I-type

I-type immediates are used in the ALU.

Logical/arithmetic immediate instructions `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI` and `ANDI`


# Adders in a minimalistic implementation

A minimalistic implementation requires only 2 adders,
here they are called the PC and the ALU adder.
The PC adder is part of the IF (instruction fetch) stage
and is used to calculate the next address or the branch address.
The output of this adder is either written into the PC register,
it is stored into a link register during `JALR` jumps,
or is stored into a CSR during a trap.

The ALU adder is used for arithmetic operations,
calculation of load/store addresses and
calculation of jump address.


In a minimalistic ASIC implementation the PC adder can be further slit
into a full adder for the lower 12 bits and a half adder for the rest of the address.



In a FPGA it might be possible to use additional adders to improve timing
without affecting or with little effect on the overall logic consumption.
This depends on details of the RTL design and the design of FPGA logic cells.

For example it is possible to use a dedicated adder for load/store operations.
Such an adder could avoid the ALU path where an inverter is used to implement subtract.