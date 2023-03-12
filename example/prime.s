	.file	"prime.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.rodata
	.align	2
.LC0:
	.string	"1 is neither prime nor composite."
	.globl	__modsi3
	.align	2
.LC1:
	.string	"%d is a prime number."
	.align	2
.LC2:
	.string	"%d is not a prime number."
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	li	a5,30
	sw	a5,-28(s0)
	lw	a4,-28(s0)
	li	a5,1
	bne	a4,a5,.L2
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	printf
	li	a5,0
	j	.L3
.L2:
	sw	zero,-20(s0)
	li	a5,2
	sw	a5,-24(s0)
	j	.L4
.L6:
	lw	a5,-28(s0)
	lw	a1,-24(s0)
	mv	a0,a5
	call	__modsi3
	mv	a5,a0
	bne	a5,zero,.L5
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L5:
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L4:
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	blt	a4,a5,.L6
	lw	a5,-20(s0)
	bne	a5,zero,.L7
	lw	a1,-28(s0)
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	printf
	j	.L8
.L7:
	lw	a1,-28(s0)
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	printf
.L8:
	li	a5,0
.L3:
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g1ea978e3066) 12.1.0"
