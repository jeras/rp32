main: main.o
	ld.lld -T link.ld -o $@ $<

%.o: %.s
	clang -mno-relax --target=riscv32 -march=rv32im -c -o $@ $^
	../../lowrisc-toolchain-rv32imc-20210412-1/bin/llvm-objcopy -j .text -O binary main.o mem_if.bin
	../../lowrisc-toolchain-rv32imc-20210412-1/bin/llvm-objcopy -j .data -O binary main.o mem_ls.bin
	../../lowrisc-toolchain-rv32imc-20210412-1/bin/llvm-objdump --arch=riscv32 --disassemble main.o > mem_if.asm
	cat mem_if.bin | hexdump -v -e '"%08X\n"' > mem_if.vmem
	cat mem_ls.bin | hexdump -v -e '"%08X\n"' > mem_ls.vmem
#	cp *.bin *.vmem ../sim/

clean:
	$(RM) main *.o
	$(RM) main *.bin
	$(RM) main *.asm
	$(RM) main *.vmem

.PHONY: clean
