main: main.o
	ld.lld -T link.ld -o $@ $<

%.o: %.s
	clang -mno-relax --target=riscv32 -march=rv32im -c -o $@ $^
	llvm-objcopy -j .text -O binary main.o mem_if.bin
	llvm-objcopy -j .data -O binary main.o mem_ls.bin
	llvm-objdump --arch=riscv32 --disassemble main.o > mem_if.asm
	hexdump -v -e '"%08X\n"' mem_if.bin > mem_if.mem
	hexdump -v -e '"%08X\n"' mem_ls.bin > mem_ls.mem
#	the character '!' is used instead of a single quote '''
#	\173 and \175 are curly brackets '{', '}'
	printf "logic [XLEN-1:0] mem [0:MEM_SIZ/4-1] = \047\173\n" > mem_if.vh
	hexdump -v -e '"    32!h%08_ax/4:"' -e '" 32!h%08X,\n"' mem_if.bin >> mem_if.vh
	sed -i 's/!/'\''/g' mem_if.vh
	printf "    default: 32\047h00000000\n\175;\n" >> mem_if.vh

clean:
	$(RM) main *.o
	$(RM) main *.bin
	$(RM) main *.asm
	$(RM) main *.mem
	$(RM) main *.vh

.PHONY: clean
