### nctuOS

A tiny OS that used for course OSDI in National Chiao Tung University, Computer Science Dept.

This OS only supports x86

### Lab 3

In this lab, you will learn about interrupt and segmentation mechanism in x86.

We provided you with keyboard handler, timer handler, and simple VGA driver.

You can leverage `grep` to find out where to fill up to finish this lab.

`$ grep -R TODO .`

To run this kernel

    $ make
    $ qemu -hda kernel.img -monitor stdio

- Modify `boot/boot.S` to setup GDT
```
    SEG(STA_X | STA_R, 0, 0x7ff << 12)     # Kernel code segment
    SEG(STA_W, 0, 0x07ff << 12)     # Kernel data segment

gdtdesc: 
	.word	(gdtdesc-gdt)-1	# gdt limit
	.long	gdt 			# gdt base
```

- Modify `kernel/trap.c` and `kernel/trap_entry.S` to setup IDT for keyboard and timer
```
struct Gatedesc idt[256] = {0};
struct Pseudodesc idt_pd =
{
	.pd_lim = (uint16_t)(sizeof(idt) - 1),
	.pd_base = (uint32_t)idt
};

void trap_init()
{

    extern void irq_kbd();
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, irq_kbd, 0);

	/* Timer Trap setup */
	extern void irq_timer();
	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, irq_timer, 0);

  	/* Load IDT */
	lidt(&idt_pd);
}
static void trap_dispatch()
{
    extern void kbd_intr();
	extern void timer_handler();

	switch (tf->tf_trapno){
		case IRQ_OFFSET + IRQ_TIMER:
			timer_handler();
			break;
		case IRQ_OFFSET + IRQ_KBD:
			kbd_intr();
			break;	
		default:
			print_trapframe(tf);
			break;

	}
}
```

- Modify `kernel/main.c` to uncomment the setup process
    - uncomment it.
- Modify `kernel/shell.c` to support `kerninfo` and `chgcolor`
```

static unsigned char color = 0;

int chgcolor(int argc, char **argv)
{	
	color = (color+1) % 16;	
	settextcolor(color, 0);
	return 0;
}

int mon_kerninfo(int argc, char **argv)
{
	extern int kernel_load_addr, etext, data, end;

	cprintf("Kernel code size=%d\n", (int)&etext - (int)&kernel_load_addr);
	cprintf("Kernel data size=%d\n", (int)&end - (int)&data);
	
	return 0;
}


```

**After this lab, you should know about how interrupt works and the working flow of GDT & IDT**

### Acknowledgement

This is forked and modified from MIT's Xv6
