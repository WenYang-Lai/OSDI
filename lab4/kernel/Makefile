
GCC_LIB := $(shell $(CC) $(CFLAGS) -print-libgcc-file-name)

KERN_LDFLAGS = -T kernel/kern.ld

KERN_SRCFILES := kernel/entry.S \
		kernel/main.c \
		kernel/picirq.c \
		kernel/kbd.c \
		kernel/screen.c \
		kernel/printf.c \
		kernel/mem.c \
		kernel/entrypgdir.c \
		kernel/assert.c \
		kernel/kclock.c \
		lib/printfmt.c \
		lib/string.c

KERN_OBJS = kernel/main.o \
	kernel/entry.o \
	kernel/picirq.o \
	kernel/kbd.o \
	kernel/screen.o \
	kernel/trap.o \
	kernel/trap_entry.o \
	kernel/printf.o \
	kernel/mem.o \
	kernel/entrypgdir.o \
	kernel/assert.o \
	kernel/kclock.o \
	kernel/shell.o \
	kernel/timer.o \
	lib/printfmt.o \
	lib/readline.o \
	lib/string.o

kernel/%.o: kernel/%.c
	$(CC) $(CFLAGS) -Os -c -o $@ $<

kernel/%.o: kernel/%.S
	$(CC) $(CFLAGS) -c -o $@ $<

kernel/system: $(KERN_OBJS)
	@echo + ld kernel/system
	$(LD) $(KERN_LDFLAGS) $(KERN_OBJS) $(GCC_LIB) -o $@
	$(OBJDUMP) -S $@ > $@.asm
	$(NM) -n $@ > $@.sym
