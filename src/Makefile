RISCV_PREFIX   ?= riscv32-unknown-elf-
RISCV_GCC      ?= $(RISCV_PREFIX)gcc
RISCV_OBJDUMP  ?= $(RISCV_PREFIX)objdump
RISCV_OBJCOPY  ?= $(RISCV_PREFIX)objcopy
RISCV_READELF  ?= $(RISCV_PREFIX)readelf

main: main.o
	ld.lld -T link.ld -o $@ $<

%.o: %.s
	clang -mno-relax --target=riscv32 -march=rv32im -c -o $@ $^
	RISCV_OBJCOPY -j .text -O binary main.o mem_if.bin
	RISCV_OBJCOPY -j .data -O binary main.o mem_ls.bin
	RISCV_OBJDUMP --arch=riscv32 --disassemble main.o > mem_if.asm
	cat mem_if.bin | hexdump -v -e '"%08X\n"' > mem_if.vmem
	cat mem_ls.bin | hexdump -v -e '"%08X\n"' > mem_ls.vmem
#	cp *.bin *.vmem ../sim/

clean:
	$(RM) main *.o
	$(RM) main *.bin
	$(RM) main *.asm
	$(RM) main *.vmem

.PHONY: clean
