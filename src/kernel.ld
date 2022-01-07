OUTPUT_ARCH("riscv")
ENTRY(main)

MEMORY {
  clint (rw) : ORIGIN = 0x02000000, LENGTH = 4096
  uart  (rw) : ORIGIN = 0x10000000, LENGTH = 4096
  ram  (wxa) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS {
  PROVIDE(CLINT_START = ORIGIN(clint));
  PROVIDE(UART_START = ORIGIN(uart));
  PROVIDE(RAM_START = ORIGIN(ram));
  PROVIDE(RAM_END = ORIGIN(ram) + LENGTH(ram));

  .text : {
    *(.text.main)
    *(.text .text.*)
  } >ram AT>ram

  .rodata : {
    *(.srodata .srodata.*)
    *(.rodata .rodata.*)
  } >ram AT>ram

  .data : {
    . = ALIGN(4096);
    *(.sdata .sdata.*)
    *(.data .data.*)
  } >ram AT>ram

  .bss : {
    *(.sbss .sbss.*)
    *(.bss .bss.*)
  } >ram AT>ram
}
