# R5P-1MEM processor

The main feature of this processor is storing GPR
in the same memory as instructions and data,
instead of having a dedicated register file.

This approach can be used in small FPGA to avoid the overhead,
when the GPR register file would consume less than the entire memory block size.

On ASIC this enables the creation of a processor
around a single single-port memory.
Thus having the smallest possible memory cell for GPR.

This approach looses some of the RISC architecture advantages,
when there is a fast GPR register file compared to a slower memory.
The advantage of simultaneous 2R1W GPR and memory access is also lost.

There is still some advantage when the GPR, the stack
and the current code section are in a fast SRAM,
while the rest are accesses to a
high latency and/or low data rate memory or periheral.
Examples of such memories can be an XIP SPI Flash
or a SDRAM/DDR/... memory controller.

Performance aside, this processor can still take full advantage
of the RISC-V toolchain compared to a fully custom solution.

## Instruction execution phases

Phases have a similar meaning as pipeline stages,
but the the word stage is not used,
since there is no pipelining parallelism.

For a simplified overview, there are 4 phases,
not all 4 phases are needed in each instruction.

| phase     | address      | read data   | data buffer | write data     | description |
|-----------|--------------|-------------|-------------|----------------|-------------|
| fe        | PC           |             |             |                | instruction fetch |
| rs1/wb    | rs1 addr.    | instr. op.  |             |       ALU data | read register source 1 or upper immediate write-back |
| rs2/ld,ex | rs2/ld addr. | rs1 data    | instr. op.  |                | read register source 2 or memory load, execute |
| st/wb,ex  | st/rd addr.  | rs2/ld data | rs1 data    | st/ld/ALU data | store or write-back destination register, execute |

The buffer contains a copy of the read data bus on the previous cycle.

If the GPR register file is stored at the end of the address space,
than the address of a register `gpr[4:0]` would be `{{XLEN-5{1'b1}}, gpr[4:0]}`.

In case the same ALU is used for R-type and LOAD/STORE operations,
there is not much advantage to having an address bus of less than XLEN.

The PC adder for increments and branches can be shorter to save logic.
The PC is unsigned extended to XLEN for the address bus.

### Instruction fetch phase

The PC value is on the memory address bus,
so in the next phase the memory read data bus will have the instruction opcode,
and one phase further the instruction opcode will be stored in the data buffer.

All instructions require this phase.

For the last, 4-th phase there is no need to store the entire instruction,
so a smaller dedicated set of registers could be used.

### Read register source 1 phase

The GPR register source 1 (`rs1`) address
is available by decoding the instruction opcode
on the *read data bus* and placed on the memory address bus.
In the next phase the memory read data bus will have the `rs1` contents,
and one phase further the `rs1` contents will be stored in the data buffer.

### Read register source 2 phase

The GPR register source 2 (`rs2`) address
is available by decoding the instruction opcode
from the *data buffer* and placed on the memory address bus.
In the next phase the memory read data bus will have the `rs2` contents.

### Store or write-back phase

The last phase of executing each instruction is execution and
either a memory store or a GPR destination register (`rd`) write-back.
Either memory or `rd` address are placed on the address bus
and simultaneously `rs1` from the buffer or the ALU result
for write-back are placed on the data bus.

## Instruction formats

### R-type

Arithmetic (`ADD`, `SUB`) and logical (`OR`, `AND`, `XOR`) operations.

| cycle     | address      | read data   | data buffer | rd addr. | write data | description |
|-----------|--------------|-------------|-------------|----------|------------|-------------|
| fe        | PC           |             |             |          |            | instruction fetch |
| rs1       | rs1 addr.    | instr. op.  |             |          |            | read register source 1 |
| rs2       | rs2 addr.    | rs1 data    | instr. op.  | rd addr. |            | read register source 2 |
| wb,ex     | rd  addr.    | rs2 data    | rs1 data    | rd addr. | ALU data   | execute and write-back |

In the last phase, the ALU is used for summation or a logical operation
between `rs1` data (in the data buffer) and `rs2` (on the read data bus).
The ALU output is placed on the write data bus for write-back.

The `rd` address must be stored in a dedicated register,
since the data buffer looses the instruction opcode
in the previous phase.

### I-type

| phase     | address      | read data   | data buffer | rd addr. | write data | description |
|-----------|--------------|-------------|-------------|----------|------------|-------------|
| fe        | PC           |             |             |          |            | instruction fetch |
| rs1       | rs1 addr.    | instr. op.  |             |          |            | read register source 1 |
| wb,ex     | rd  addr.    | rs2 data    | rs1 data    | rd addr. | ALU result | execute and write-back |

For I-type instructions there is no need to read `rs2` contents,
so this phase can be skipped.

In the last phase, the ALU is used for summation or a logical operation
between `rs1` data (on the read data bus) and an immediate
(from the instruction opcode inside the data buffer).
The ALU output is placed on the write data bus for write-back.

The `rd` address is decoded from the instruction opcode inside the data buffer.
NOTE: a better alternative is to use the same dedicated register as for R-type.

### L-type (I-type load)

| phase     | address      | read data   | data buffer | rd addr. | write data  | description |
|-----------|--------------|-------------|-------------|----------|-------------|-------------|
| fe        | PC           |             |             |          |             | instruction fetch |
| rs1       | rs1 addr.    | instr. op.  |             |          |             | read register source 1 |
| ld,ex     | ALU result   | rs1 data    | instr. op.  | rd addr. |             | execute and load |
| wb        | rd  addr.    | mem. data   | rs1 data    | rd addr. | read data   | write-back |

For I-type instructions there is no need to read `rs2` contents,
so this phase can be skipped.

In the execute and load phase,
the ALU is used to calculate the memory load address from
`rs1` data (on the read data bus) and an immediate
(from the instruction opcode inside the data buffer).

In the last phase the read data bus value is copied
to the write data bus for write-back.
The `rd` address must be stored in a dedicated register,
since the data buffer looses the instruction opcode
in the previous phase.

### S-type

| phase     | address      | read data   | data buffer | write data     | description |
|-----------|--------------|-------------|-------------|----------------|-------------|
| fe        | PC           |             |             |                | instruction fetch |
| rs1       | rs1 addr.    | instr. op.  |             |                | read register source 1 |
| rs2,ex    | rs2 addr.    | rs1 data    | instr. op.  |                | read register source 2 and execute |
| st        | data buffer  | rs2 data    | ALU result  | read data      | store to memory |

The execute phase is the same as in the L-type,
the calculated ALU output is the store address and
is placed into the data buffer, to be used in the next phase.

In the last phase, read data is copied to write data and
written to memory at the address calculated in the previous phase.

### B-type

| cycle     | address      | read data   | data buffer | rd addr. | write data | description |
|-----------|--------------|-------------|-------------|----------|------------|-------------|
| fe        | PC           |             |             |          |            | instruction fetch |
| rs1       | rs1 addr.    | instr. op.  |             |          |            | read register source 1 |
| rs2       | rs2 addr.    | rs1 data    | instr. op.  |          |            | read register source 2 and execute |
| ex        | rd  addr.    | rs2 data    | rs1 data    |          |            | execute and write-back |

Similar to R-type but instead of a write back,
The ALU result is used as a branch taken condition.

TODO: in the 3-rd phase the ALU could be used to calculate the branch address,
the result stored stored somewhere and in the last phase loaded into the PC.
As an alternative, the branch immediate could be stored in an extended version of 
`rd` addr. buffer and used to calculate the new PC with a dedicated adder.

NOTE: since there is no memory access in the 4-th phase,
this phase could be combined into the next fetch,
but this would affect timing significantly.

### U-type

| cycle     | address      | read data   | data buffer | rd addr. | write data | description |
|-----------|--------------|-------------|-------------|----------|------------|-------------|
| fe        | PC           |             |             |          |            | instruction fetch |
| ex,wb     | rd  addr.    | rs2 data    | rs1 data    |          | ALU result | execute and write-back |

`rd` address is extracted directly from read data.

TODO

### J-type

| cycle     | address      | read data   | data buffer | rd addr. | write data | description |
|-----------|--------------|-------------|-------------|----------|------------|-------------|
| fe        | PC           |             |             |          |            | instruction fetch |
| TODO      | rd  addr.    |             |             |          |            |  |

TODO

## System bus backpressure and stall

If the [tightly coupled memory bus](../../../doc/Sysbus.md) is used,
then the ready signal can be used directly as a CPU stall,
simply as a state machine clock enable.
