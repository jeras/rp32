OUTPUT_ARCH( "riscv" )

SECTIONS
{
  . = 0x80000000;
  .text : { *(.text) }
  .data : { *(.data) }
}

