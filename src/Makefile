main: main.o
	ld.lld -T link.lds -o $@ $<

%.o: %.s
	clang -mno-relax --target=riscv32 -march=rv32i -c -o $@ $^
	../../lowrisc-toolchain-rv32imc-20210412-1/bin/llvm-objcopy -j .text -j .data -O binary main.o main.bin
	cat main.bin | hexdump -v -e '"%08X\n"' > main.vmem

clean:
	$(RM) main *.o

.PHONY: clean
