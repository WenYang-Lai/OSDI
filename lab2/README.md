# Lab2

### Lab2.1
- using costumized bios
    - ```-bios /path/to/bios```
- enable boot menu
    - ```-boot menu=on```
- show bootsplash image
    - ```-boot splash=/path/to/jpg,splash-time=5000```

### Lab2.2
- Add ```hello.s``` under ```boot/```directory
- modify ```boot/Makefile```
  - line 21~25
  
  ```
  hello: hello.s
	@$(AS) -o hello.o hello.s
	@$(LD) $(LDFLAGS) -o hello hello.o
	@objcopy -R .pdr -R .comment -R.note -S -O binary hello

  clean:
	@rm -f bootsect bootsect.o setup setup.o head.o hello hello.o
  ```
- modify ```Makefile```
  - Add 
  
```
boot/hello: boot/hello.s
	@make hello -C boot 
```
  - modify around line 46
  
```  
@tools/build.sh boot/bootsect boot/setup tools/kernel Image boot/hello $(ROOT_DEV)

```
- modify ```boot/bootsect.s```
  - Add ```load_hello```

```
# load hello from disk into memory
# ref to load_setup
load_hello:
	
	mov	$HELLOSEG, %ax		# hello SEG
	mov	%ax, %es		# set segment
	mov	$0x0000, %dx		# drive 0, head 0
	mov	$0x0002, %cx		# sector 2, track 0
	mov	$0x0000, %bx		# address = 0, in HELLOSEG
	.equ    AX, 0x0200+HELLOLEN
	mov     $AX, %ax		# service 2, nr of sectors
	int	$0x13			# read it
	jnc	ok_load_hello		# ok - continue
	mov	$0x0000, %dx
	mov	$0x0000, %ax		# reset the diskette
	int	$0x13
	jmp	load_hello

ok_load_hello:
	ljmp 	$HELLOSEG, $0x0

```
  - modify ```load_setup```: change sector number to 2

- modify ```tool/build.sh```
  - Write ```hello``` binary to image
  
```
[ ! -f "$bootsect" ] && echo "there is no bootsect binary file there" && exit -1
dd if=$bootsect bs=512 count=1 of=$IMAGE 2>&1 >/dev/null

```
  - set ```setup``` binary offset to 2, and system kernel offset to 5




### Lab2.3
- Add ```boot/bootsect.s``` line 67

```
# multiboot option
multiboot:
	mov 	%cs, %ax
	mov 	%ax, %ds
	mov 	%ax, %es
 
	mov 	$0x03, %ah      	# read cursor pos
	xor 	%bh, %bh
	int 	$0x10
    
	mov 	$34, %cx
	mov 	$0x0007, %bx        	# page 0, attribute 7 (normal)
	mov 	$msg_multiboot, %bp
	mov 	$0x1301, %ax      	# write string, move cursor
	int 	$0x10
	
	mov 	$0x0, %ah		# set function number
	int 	$0x16			# key strok
	
	cmp 	$0x31, %al 
	je  	load_setup
	cmp 	$0x32, %al
	je  	load_hello
	
	# show error msg
	mov 	$0x03, %ah      	# read cursor pos
	xor 	%bh, %bh
	int 	$0x10

	mov 	$28, %cx				
	mov 	$0x0007, %bx
	mov 	$msg_multiboot_error, %bp
	mov 	$0x1301, %ax 		# write string, move cursor
	int 	$0x10
	jmp 	multiboot		# retry 

```
### Question
- Q3: Using linker script to make boot image
    - Compile without ```objcopy``` to binary format. 
    - using linker instead of ```build.sh```
