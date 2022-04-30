# Tightly Coupled Bus

Tightly Coupled Bus is a system bus based on FPGA/ASIC synchronous SRAM memory interfaces.

Proposed names are based on:
* Tightly Integrated Memory (TIM) used by [SiFive](https://www.sifive.com/),
* Tightly Coupled Memory (TCM) used by [ARM](https://www.kernel.org/doc/Documentation/arm/tcm.txt),
  [Codasip](https://codasip.com/), and [Syntacore](https://syntacore.com/),
* Local Memory (LM) used by [Andes](http://www.andestech.com/en/risc-v-andes/)

A processor native system bus is usually custom designed
to supports exactly the features that are present in the processor itself.
This also means there are differences between the protocols
used by instruction fetch and load/store unit.

This description will start with a superset of features
at least partially shared by both interfaces.

The design is based on the following principles:
* Intended for closely coupled memories and caches, and therefore based on synchronous memory (SRAM) interfaces.
* Support pipelining for both writes and reads to minimize stalling overhead.
  Meaning the handshake is dune during the arbitration phase.
* Handshake based on AXI4-Stream (valid/ready).
* Low power consumption should be considered.

## Bus signals

Regarding naming conventions,
for aesthetic reasons (vertical allignment) all signal names are
[three-letter abbreviation (TLA)](https://en.wikipedia.org/wiki/Three-letter_acronym).
Suffixes specifying the direction of module ports (input/output, i/o) shall be avoided.
Instead the set of signals can have a prefix or is grouped into a SystemVerilog interface.
This set name shall use specifiers like manager/subordinate (master/slave, m/s).

The SRAM signal chip select/enable is replaced with the AXI handshake signal valid `vld`.
Backpressure is supported by adding the AXI handshake signal ready `rdy`.
Hanshake signals shall follow the basic principles defined for the AXI family of protocols.
* While valid is not active all other signals shall be ignored (`X` in timing diagrams).
* `vld` must be inactive during reset.
* Once the manager assrts `vld`, it must not remove it till the transfer is completed by an active `rdy` signal.
* The manager must not wait for `rdy` to be asserted before starting a new transfer by asserting `vld`.
* The subordinate can assert/remove the `rdy` signal without restrictions.

This means once a transfer is initiated, it must be completed.
Since `rdy` can be asserted during reset (`rdy` can be a constant value),
`vld` must not be asserted, since this would indicate transfers while in reset state.
Since the subordinate is allowed to wait for `vld` before asserting `rdy` (no restrictions),
the manager can't wait for `rdy` to before asserting `vld`,
since this could result in a lockup.
There is also no integrated timeout abort mechanism,
although it would be possible to place such functionality
into a module placed between the manager and the subordinate.

| parameter/generic | description |
| `AW`              | Address width. |
| `DW`              | Data width. |
| `SW=DW/8`         | Byte select width. |

| signal | width  | direction | description |
|--------|--------|-----------|-------------|
| `vld`  | 1      | M -> S    | Hanshake valid. |
| `wen`  | 1      | M -> S    | Write enable. |
| `adr`  | `AW`   | M -> S    | Address. |
| `ben`  | `DW`/8 | M -> S    | Byte enable (select). |
| `wdt`  | `DW`   | M -> S    | Write data. |
| `rdt`  | `DW`   | S -> M    | Read data. |
| `rdy`  | 1      | S -> M    | Hanshake ready. |

## Handshake protocol and signal timing

### Write transfer

A write transfer is performed when both handshake signals `vld` and `rdy` are simultaneously active
and the write enable signal `wen` is also active.

Only bytes with an active corresponding byte enable bit in `ben` are written.
The other bytes can be optimized to unchanged value, zeros or just undefined,
depending what brings the preferred optimization for area timing, power consumption, ...
The same optimization principle can be applied to all signals when valid is not active.

There are no special pipelining considerations for write transfers,
all signals shall be propagated through a pipeline,
similar to a single direction data stream

The base protocol does not have a mechanism for confirming
write transfers reached their destination and were successfully applied.

[image]

### Read transfer

A read transfer is performed when both handshake signals `vld` and `rdy` are simultaneously active
and the write enable signal `wen` is not active.

The handshake is done during the arbitration phase, it is primarily
about whether the address `adr` from the manager can reach the subordinate.

Read data is available on `rdt` after a fixed delay of 1 clock cycle from the transfer.

## Support components

### Arbiter

### Decoder


## Limitations and undefined features

There are some generalizations and additional features that can be implemented,
but were not researched well enough to be fully defined.

### Data output hold

SRAM usually holds the data output from the last read request,
till a new request is processed.
In a similar fashion, the entire bus could hold the last read value,
this means read data multiplexers in decoder modules have to hold.
The held data can be lost if a subordinate is accessed by another manager.

Read data hold can be useful during CPU stalls.
Either there is no need to repeat a read or a temporary buffer
for read data can be avoided.

### Out of order transfers

Out of order reads are not supported.

### Generalized read delay

The delay of 0 would be an asynchronous read,
a delay of 1 is equal to a common SRAM read cycle,
longer delays can be caused by registers in the system bus interconnect.

### Integration with standard system busses

It is possible to translate between the processor native system bus and
standard system busses like APB, AHB, AXI4-Lite, Wishbone, ...

Such translation could compromise the performance,
so it might make sense to implement a standard bus interface unit (BIU)
separately inside the processor core,
instead of attaching translators to the optimized native bus.

### Write confirmation

Write confirmation could be returned with the same timing as read data.

In case the native system bus is only used for the intend purpose
of connecting tightly coupled memories, writes can be assumed to always succeed.

Write through cache access was not yet researched.

### Atomic access

TODO, on some implementations it might be possible
to simultaneously perform both read and write.