OUTPUT_ARCH("riscv")

ENTRY(_start)

MEMORY
{
  mem_if (rx)  : ORIGIN = 0x00000000, LENGTH = 64k
  mem_ls (rwx) : ORIGIN = 0x80000000, LENGTH = 64k
}

SECTIONS
{
  .text.init ALIGN((ORIGIN(mem_if) + 0x0), 64) : AT(ALIGN((ORIGIN(mem_if) + 0x0), 64)) {
    PROVIDE(_ftext = .);
    *(.text.init)
    PROVIDE(_etext = .);
  }

  .text ALIGN((ADDR(.text.init) + SIZEOF(.text.init)), 64) : AT(ALIGN((LOADADDR(.text.init) + SIZEOF(.text.init)), 64)) {
    *(.text)
  }

  .tohost ALIGN((ORIGIN(mem_ls)), 64) : AT(ALIGN((ORIGIN(mem_ls)), 64)) {
    *(.tohost)
  }

  .data ALIGN((ADDR(.tohost) + SIZEOF(.tohost)), 64) : AT(ALIGN((LOADADDR(.tohost) + SIZEOF(.tohost)), 64)) {
    *(.data)
  }

  PROVIDE(_data = ADDR(.data));
  PROVIDE(_data_lma = LOADADDR(.data));
  PROVIDE(_edata = ADDR(.data) + SIZEOF(.data));
}