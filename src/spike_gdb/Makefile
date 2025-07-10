SRC = rot13.c

APP = rot13

CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib
CFLAGS += -Wall -Wextra
CFLAGS += -g -Og

all: ${SRC}
	riscv32-unknown-elf-gcc ${CFLAGS} -o ${APP}.o -c ${SRC}
	riscv32-unknown-elf-gcc ${CFLAGS} -T spike.lds -nostartfiles -o ${APP}.elf ${APP}.o