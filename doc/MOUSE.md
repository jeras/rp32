# R5P Mouse processor

## introduction

The main feature of this processor is storing GPR
in the same memory as instructions and data,
instead of having a dedicated register file.

This approach can be used in small FPGA to avoid the overhead,
when the GPR register file would consume less than the entire memory block size.
For FPGA families without some kind of distributed memory with asynchronous read
to be used for the GPR register file,
this approach avoids using logic cell registers for GPR.

On ASIC this enables the creation of a processor
around a single single-port memory.
Thus having the smallest possible memory cell for GPR.

This approach looses some of the RISC architecture advantages,
when there is a fast GPR register file compared to a slower memory.
The advantage of simultaneous 2R1W GPR and memory access is also lost.

The design is still competitive, when the GPR, the stack
and the current code section are all in a fast SRAM,
while the remaining accesses are to a
high latency and/or low data rate memory or peripheral.
Examples of such memories can be an XIP SPI Flash
or so other slow external memory controller.

Performance aside, this processor can still take full advantage
of the RISC-V toolchain compared to a fully custom solution,
which would also require a custom toolchain.

## Instruction execution phases

The CPU takes multiple clock cycles to execute an instruction.
Most of this cycles are used to perform a system bus access to either
fetch an instruction, read/write to GPR or memory/peripheral load/store.

Phases have a similar meaning as pipeline stages,
but the word stage is not used,
since there is no pipelining parallelism.
The same logic is used in each stage to perform a different task.

| Phase | Description |
|-------|-------------|
| IF    | Instruction fetch and decode (partial). |
| RS1   | Read register source 1. |
| RS2   | Read register source 1. |
| LD    | Memory load. |
| ST    | Memory store. |
| EXE   | Execute. |
| WB    | Write-back. |

Instructions take between 1 and 4 clock cycles to execute,
depending on the instruction.
The CPU state machine has 4 states, 
Each phase fits into one of those states.
Instructions do not need all available phases
so multiple similar phases can share the same state.

| state | phases     | address      | read data   | data buffer | write data     | description |
|-------|------------|--------------|-------------|-------------|----------------|-------------|
| `ST0` | IFD        | PC           |             |             |                | instruction fetch |
| `ST1` | RS1/WB     | rs1 addr.    | instr. op.  |             |       ALU data | read register source 1 or upper immediate write-back |
| `ST2` | RS2/LD,EXE | rs2/ld addr. | rs1 data    | instr. op.  |                | read register source 2 or memory load, execute |
| `ST3` | ST/WB,EXE  | st/rd addr.  | rs2/ld data | rs1 data    | st/ld/ALU data | store or write-back destination register, execute |

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

| signal    | description |
|-----------|-------------|
| `bus_adr` | bus address |
| `bus_wdt` | bus write data |
| `bus_rdt` | bus read data |
| `dec_rs1` | decoder GPR `rs1` address |
| `dec_rs2` | decoder GPR `rs2` address |
| `dec_rd`  | decoder GPR `rd`  address |
| `dec_imi` | decoder immediate I (integer, load) |
| `dec_imb` | decoder immediate B (branch) |
| `dec_ims` | decoder immediate S (store) |
| `gpr_rs1` | GPR `rs1` data |
| `gpr_rs2` | GPR `rs2` data |
| `alu_add` | ALU adder |
| `inw`     | instruction Operation Code |
| `inw_buf` |
| `buf_dat` |

### R-type

Arithmetic (`ADD`, `SUB`) and logical (`OR`, `AND`, `XOR`) operations.

| cycle     | `alu_add` | `bus_adr` | `bus_wdt` | `bus_rdt` | data buffer | description |
|-----------|-----------|-----------|-----------|-----------|-------------|-------------|
| fe        |   PC+4    | `alu_add` |           |           |             | instruction fetch |
| rs1       |           | `dec_rs1` |           | `inw`     |             | read register source 1 |
| rs2       |           | `dec_rs2` |           | `gpr_rs1` | instr. op.  | read register source 2 |
| wb,ex     | `rs1+rs2` | `dec_rd`  | `alu_add` | `gpr_rs2` | rs1 data    | execute and write-back |

In the last phase, the ALU is used for summation or a logical operation
between `rs1` data (in the data buffer) and `rs2` (on the read data bus).
The ALU output is placed on the write data bus for write-back.

The `rd` address must be stored in a dedicated register,
since the data buffer looses the instruction opcode
in the previous phase.

### I-type

| cycle     | `alu_add` | `bus_adr` | `bus_wdt` | `bus_rdt` | data buffer | description |
|-----------|-----------|-----------|-----------|-----------|-------------|-------------|
| fe        |   PC+4    | `alu_add` |           |           |             | instruction fetch |
| rs1       |           | `dec_rs1` |           | `inw`     |             | read register source 1 |
| wb,ex     | `rs1+imi` | `dec_rd`  | `alu_add` | `gpr_rs2` | rs1 data    | execute and write-back |

For I-type instructions there is no need to read `rs2` contents,
so this phase can be skipped.

In the last phase, the ALU is used for summation or a logical operation
between `rs1` data (on the read data bus) and an immediate
(from the instruction opcode inside the data buffer).
The ALU output is placed on the write data bus for write-back.

The `rd` address is decoded from the instruction opcode inside the data buffer.
NOTE: a better alternative is to use the same dedicated register as for R-type.

#### JALR

| cycle     | `alu_add` | `bus_adr` | `bus_wdt` | `bus_rdt` | data buffer | description |
|-----------|-----------|-----------|-----------|-----------|-------------|-------------|
| fe        |   PC+4    | `alu_add` |           |           |             | instruction fetch |
| rs1       |           | `dec_rs1` |           | `inw`     |             | read register source 1 |
| wb,ex     |   PC+4    | `dec_rd`  | `alu_add` | `gpr_rs2` | rs1 data    | execute and write-back |
|-----------|-----------|-----------|-----------|-----------|-------------|-------------|
| fe        | ` PC+buf` | `alu_add` |           |           |             | instruction fetch |

### L-type (I-type load)

| cycle     | `alu_add` | `bus_adr` | `bus_wdt` | `bus_rdt` | data buffer | description |
|-----------|-----------|-----------|-----------|-----------|-------------|-------------|
| fe        |   PC+4    | `alu_add` |           |           |             | instruction fetch |
| rs1       |           | `dec_rs1` |           | `inw`     |             | read register source 1 |
| ld        | `rs1+imi` | `alu_add` |           | `gpr_rs2` | `dimm`      | load |
| wb        |           | `dec_rd`  | `bus_rdt` |           |             | write-back |

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

| cycle     | `alu_add` | `bus_adr` | `bus_wdt` | `bus_rdt` | buffer    | description |
|-----------|-----------|-----------|-----------|-----------|-----------|-------------|
| fe        |   PC+4    | `alu_add` |           |           |           | instruction fetch |
| rs1       |           | `dec_rs1` |           | `inw`     |           | read register source 1 |
| rs2       | `rs1+ims` | `dec_rs2` |           | `gpr_rs1` | `dec_ims` | read register source 2 |
| wb        |           | `buf_dat` | `bus_rdt` | `gpr_rs1` | `alu_add` | write-back |

TODO: leaving table here, since it uses adder in same stage as load,


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

| cycle     | `alu_add` | `bus_adr` | `bus_wdt` | `bus_rdt` | data buffer | description |
|-----------|-----------|-----------|-----------|-----------|-------------|-------------|
| fe        |   PC+imb  | `alu_add` |           |           |             | instruction fetch with branch |
| rs1       |           | `dec_rs1` |           | `inw`     |             | read register source 1 |
| rs2       |           | `dec_rs2` |           | `gpr_rs1` | instr. op.  | read register source 2 |
| wb,ex     | `rs1+rs2` |           |           | `gpr_rs2` | rs1 data    | execute |

| cycle     | address      | read data   | data buffer | rd addr. | write data | description |
|-----------|--------------|-------------|-------------|----------|------------|-------------|
| fe        |   PC+imb           |             |             |          |            | instruction fetch |
| rs1       | rs1 addr.    | instr. op.  |             |          |            | read register source 1 |
| rs2       | rs2 addr.    | rs1 data    | instr. op.  |          |            | read register source 2 and execute |
| ex        | rd  addr.    | rs2 data    | rs1 data    |          |            | execute and write-back |

Similar to R-type but instead of a write back,
The ALU result is used as a branch taken condition.

TODO: in the 3-rd phase the ALU could be used to calculate the branch address,
the result stored somewhere and in the last phase loaded into the PC.
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

JAL

| cycle     | `alu_add` | `bus_adr` | `bus_wdt` | `bus_rdt` | data buffer | description |
|-----------|-----------|-----------|-----------|-----------|-------------|-------------|
| fe        |   PC+4    | `alu_add` |           |           |             | instruction fetch |
| wb,ex     |   PC+4    | `dec_rd`  | `alu_add` | `gpr_rs2` | rs1 data    | execute and write-back |
|-----------|-----------|-----------|-----------|-----------|-------------|-------------|
| fe        | ` PC+buf` | `alu_add` |           |           |             | instruction fetch |


| cycle     | address      | read data   | data buffer | rd addr. | write data | description |
|-----------|--------------|-------------|-------------|----------|------------|-------------|
| fe        | PC           |             |             |          |            | instruction fetch |
| TODO      | rd  addr.    |             |             |          |            |  |

TODO

## System bus backpressure and stall

If the [tightly coupled memory bus](../../../doc/Sysbus.md) is used,
then the ready signal can be used directly as a CPU stall,
simply as a state machine clock enable.
