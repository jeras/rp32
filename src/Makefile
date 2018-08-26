# https://www.sifive.com/blog/2017/08/14/all-aboard-part-1-compiler-args/
RISCV_ARCH := rv32i
RISCV_ABI  := ilp32

LDFLAGS += -T test_isa.lds -nostartfiles
LDFLAGS += -L$(ENV_DIR) --specs=nano.specs

# includes are empty for now

CFLAGS += -g
CFLAGS += -march=$(RISCV_ARCH)
CFLAGS += -mabi=$(RISCV_ABI)
CFLAGS += -mcmodel=medany

TOOL = /opt/riscv/bin/riscv64-unknown-elf

all:
	${TOOL}-as         -march=rv32i test_isa.S -o test_isa.o
#	${TOOL}-objdump -d -march=rv32i test_isa.o  > test_isa.elf.dump
	${TOOL}-objcopy -j .text -j .data -O binary test_isa.o test_isa.bin
	${TOOL}-objcopy -j .text -j .data -O ihex   test_isa.o test_isa.vmem
	srec_cat test_isa.hex -Intel -byte-swap 2 -Output test_isa.vmem -VMem 16
#	${TOOL}-objdump -j .sec1 -d -m avr31 test_isa.hex > test_isa.dump

all3:
	$(TOOL)-gcc $(CFLAGS) $(INCLUDES) -c -o test_isa.o test_isa.S
	$(TOOL)-gcc $(CFLAGS) $(INCLUDES) test_isa.o -o test_isa $(LDFLAGS)

all2:
	${TOOL}-as         -march=rv32i test_isa.S   -o test_isa.o
	${TOOL}-ld         -march=rv32i test_isa.o   -o test_isa.elf
	${TOOL}-objdump -d -march=rv32i test_isa.elf  > test_isa.elf.dump
	${TOOL}-objcopy -j .text -j .data -O binary test_isa.elf test_isa.bin
	${TOOL}-objcopy -j .text -j .data -O ihex   test_isa.elf test_isa.hex
	srec_cat test_isa.hex -Intel -byte-swap 2 -Output test_isa.vmem -VMem 16
	${TOOL}-objdump -j .sec1 -d -m avr31 test_isa.hex > test_isa.dump


all1:
	#${TOOL}-gcc -mmcu=atmega128 -Wall -Os -o test_isa.elf test_isa.S
	#${TOOL}-objcopy -j .text -j .data -O binary test_isa.elf test_isa.bin
	#${TOOL}-objcopy -j .text -j .data -O ihex   test_isa.elf test_isa.hex
	${TOOL}-as -mmcu=$(MMCU) test_isa.S -o test_isa.o
	${TOOL}-ld -m $(MMCU) test_isa.o -o test_isa.elf
	${TOOL}-objdump -d -m avr31 test_isa.elf > test_isa.elf.dump
	${TOOL}-objcopy -j .text -j .data -O binary test_isa.elf test_isa.bin
	${TOOL}-objcopy -j .text -j .data -O ihex   test_isa.elf test_isa.hex
	srec_cat test_isa.hex -Intel -byte-swap 2 -Output test_isa.vmem -VMem 16
	${TOOL}-objdump -j .sec1 -d -m avr31 test_isa.hex > test_isa.dump
