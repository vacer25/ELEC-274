# LB2PRT1.S [170121]
# QECE ELEC274 Lab exercise 2, part 1

###############################################################################
# Code to show some computation and a simple loop, accessing all elements in
# an array
# Author:
#    David Athersych, P.Eng.
# History:
#	170121	1.0	DA	Original release
#	180118	2.0	DA	Updated for 2018
#
#==============================================================================
# Actual assembly code starts here:
#
# Directives - configuration information to the assembler.

# Symbol definitions - equivalent to #define LAST_RAM_WORD  0x007FFFFC
	.equ	LAST_RAM_WORD,	0x007FFFFC
	.equ	ARR_SIZE,		17

# Object module configuration.
	.text				# tell assembler that this is code segment
	.global	_start		# tell assembler that _start is visible to linker

	.org	0x00000000	# starting address for the following code

_start:
	# Initialize stack pointer to point to last word in memory. Stack is
	# used by hardware to store return address during function call. Stack
	# may also be used for temporary variables.
	movia	sp, LAST_RAM_WORD

	# Go through 10 integer values found starting at label A, looking for
	# biggest value and smallest value
	movia	r2, A		# Address of A in r2
	movi	r3, ARR_SIZE		# Store count in r3 (we'll count down)
	movi	r4, 0
	# Now go through remaining elements
loop:
	# Pehaps a bit odd, but check if we're done
	beq		r3, r0, calc_avg	# counter down to 0; we have done 9 elements
	## YOUR CODE GOES HERE
	## ---<SNIP>---
    ldw		r7, 0(r2)	# Get value in A[i]
	add		r4, r4, r7
	## ---<SNIP>---
endloop:
	# have processed one element; reduce count and increment pointer
	subi	r3, r3, 1		# one less element to inspect
	addi	r2, r2, 4		# move pointer to next element
	br		loop			# note that loop is where end condition checked

calc_avg:
	mov		r6, r0
	movi	r5, ARR_SIZE
div_loop:
	blt		r4, r5, done
	sub		r4, r4, r5
	addi	r6, r6, 1
    br		div_loop
	
done:	# get here when count has reached 0

	br		done			# nothing else to do
	

#==============================================================================

	.org	0x00000800	# where this code is to go in memory
A:		.word	4,6,8,3,16,22,0,7,11,24,12,9,15,6,38,26,40
AVG:	.skip	4		# set aside 4 bytes, no initialize

	.end				# tells assembler this is the end

