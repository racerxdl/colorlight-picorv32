
__heap_size     = 0x200;    /* required amount of heap  */
__stack_size    = 0x800;    /* required amount of stack */

MEMORY
{
    RAM (xrw)       : ORIGIN = 0x00000000, LENGTH = 0x008000 /* 32 KB */
}

SECTIONS {
    .text :
    {
        *(.start)
        *(.text)           /* .text sections (code) */
        *(.text*)          /* .text* sections (code) */
        *(.rodata)         /* .rodata sections (constants, strings, etc.) */
        *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
        *(.srodata)        /* .rodata sections (constants, strings, etc.) */
        *(.srodata*)       /* .rodata* sections (constants, strings, etc.) */
    } >RAM

    .data :
    {
        *(.sbss)
        *(.data)
        *(.bss)
        *(.rela*)
        *(COMMON)
    } >RAM

    /* this is to define the start of the heap, and make sure we have a minimum size */
    .heap :
    {
        . = ALIGN(4);
        PROVIDE ( end = . );
        _sheap = .;
        . = . + __heap_size;
        . = ALIGN(4);
        _eheap = .;
    } >RAM

    .stack :
    {
        . = ALIGN(4);
        _estack = .;
        . = . + __stack_size;
        . = ALIGN(4);
        _sstack = .;
    } >RAM
}