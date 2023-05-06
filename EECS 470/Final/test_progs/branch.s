.section .text
.align 4
	nop
	li sp, 2048
## Branch tests ##
	li t0, 0x1 #TODO: this will be test number
	li t6, 0
	li t1, 1
	li t2, 2
	bne t1,t2, bt1
	nop
	nop
	nop
	wfi
bt1:
	addi t6, t6, 1
	li t1, 0
	li t2, 0
	addi t6, t6, 1
	nop
	nop
	nop
	nop
	wfi
