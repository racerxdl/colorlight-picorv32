ASM_SOURCES   := $(shell find . -name '*.s')
SOURCES       := $(shell find . -name '*.c')
OBJECTS       := $(SOURCES:%.c=%.o)
ASM_OBJECTS   := $(ASM_SOURCES:%.s=%.s.o)

CFLAGS=-mabi=ilp32e -march=rv32e -nostdlib
LDFLAGS=-T sections.lds -m elf32lriscv --strip-debug -nostdlib -O binary

# OC=riscv32-elf-objcopy
# CC=riscv32-elf-gcc
# LD=riscv32-elf-ld

OC=riscv64-linux-gnu-objcopy
CC=riscv64-linux-gnu-gcc-10
LD=riscv64-linux-gnu-ld

all: clean firmware.hex

%.o: %.c
	@echo "Building $< -> $@"
	@$(CC) -c $(CFLAGS) -o $@ $<

%.s.o: %.s
	@echo "Building $< -> $@"
	@$(CC) -c $(CFLAGS) -o $@ $<


firmware.hex:

firmware.elf: sections.lds $(OBJECTS) $(ASM_OBJECTS)
	@echo "Linking prog.elf $(OBJECTS) $(ASM_OBJECTS)"
	@$(LD) $(LDFLAGS) $(OBJECTS) $(ASM_OBJECTS) -o firmware.elf

firmware.bin: firmware.elf
	$(OC) -O binary firmware.elf /dev/stdout > firmware.bin

firmware.hex: firmware.bin
	python3 makehex.py $^ 4096 > $@

clean:
	@echo "Cleaning build files"
	@rm -f $(OBJECTS) *.hex *.bin *.elf *.mem *.o
