OUTPUT_ARCH("riscv")

ENTRY(_start)

MEMORY {
  mem_if (rx)   : ORIGIN = 0x00000000, LENGTH = 0x10000
  mem_ls (rw!x) : ORIGIN = 0x80000000, LENGTH = 0x10000
}

SECTIONS
{

  .text.init ALIGN((ORIGIN(mem_if) + 0x0), 64) : AT(ALIGN((ORIGIN(mem_if) + 0x0), 64)) {
    PROVIDE(_ftext = .);
    *(.text.init)
    PROVIDE(_etext = .);
  } > mem_if

  .text ALIGN((ADDR(.text.init) + SIZEOF(.text.init)), 64) : AT(ALIGN((LOADADDR(.text.init) + SIZEOF(.text.init)), 64)) {
    *(.text)
  } > mem_if

  .tohost ALIGN((ORIGIN(mem_ls) + 0x0), 64) : AT(ALIGN((ORIGIN(mem_ls) + 0x0), 64)) {
    *(.tohost)
  } > mem_ls

  .data ALIGN((ADDR(.tohost) + SIZEOF(.tohost)), 64) : AT(ALIGN((LOADADDR(.tohost) + SIZEOF(.tohost)), 64)) {
    *(.data)
  } > mem_ls

  .data.string ALIGN((ADDR(.data) + SIZEOF(.data)), 64) : AT(ALIGN((LOADADDR(.data) + SIZEOF(.data)), 64)) {
    *(.data.string)
  } > mem_ls

  PROVIDE(_data = ADDR(.data));
  PROVIDE(_data_lma = LOADADDR(.data));
  PROVIDE(_edata = ADDR(.data) + SIZEOF(.data));

  .bss ALIGN((ADDR(.data.string) + SIZEOF(.data.string)), 64) : AT(ALIGN((LOADADDR(.data.string) + SIZEOF(.data.string)), 64)) ALIGN(8) {
    PROVIDE(_fbss = .);
    *(.bss)
    PROVIDE(_ebss = .);
  }

}
