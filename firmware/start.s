.section .start

start:

addi x1, zero, 0
li s0, 0x00008000; /* 32K RAM top = stack address */
addi x3, zero, 0
addi x4, zero, 0
addi x5, zero, 0
addi x6, zero, 0
addi x7, zero, 0
addi x8, zero, 0
addi x9, zero, 0
addi x10, zero, 0
addi x11, zero, 0
addi x12, zero, 0
addi x13, zero, 0
addi x14, zero, 0
addi x15, zero, 0


# Update LEDs
li a0, 0x02000000
li a1, 0x00
sw a1, 0(a0)

call main

loop:
j loop
