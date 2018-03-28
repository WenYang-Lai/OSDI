ENTRY(start)

SECTIONS{
    
    .bootsect :
    {
        . = 0;
        boot/bootsect(.text)
    }
    . = 0x200;

    .hello :
    {
        boot/hello(.text)
    }
    . = 0x400;

    .setup :
    {
        boot/setup(.text)
    }
    . = 0xc00;

    .system :
    {
        tools/kernel(.text)
        . = 0x18598;
        tools/kernel(.rodata)
        . = 0x1a000;
        tools/kernel(.data)
        . = 0x1da20;
        tools/kernel(.bss)
    }

}
