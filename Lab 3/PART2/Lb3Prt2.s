# Lab3Prt2.S [170201]
# 
###############################################################################
# Lab3Prt2 - code for part 2 of lab 3 - print hex digits
#
# Author:
# David Athersych, P.Eng. Cynosure Computer Technologies Inc.
#
# HISTORY:
# 170201 DFA	First release
###############################################################################

# Actual assembly code starts here:
#
# Directives - configuration information to the assembler.

# Symbol definitions
	.equ	LAST_RAM_WORD,	0x007FFFFC
	.equ	JTAG_UART_BASE,	0x10001000	# base address of JTAG UART
	.equ	OFFSET_DATA,	0			# offset from base for data register
	.equ	OFFSET_STATUS,	4			# offset from base for status register
	.equ	WSPACE_MASK,	0xFFFF		# 16 bit mask used to get status bits

# Object module configuration.
	.text				# tell assembler that this is code segment
	.global	_start		# tell assembler that _start is visible to linker

	.org	0x00000000	# starting address for the following code

_start:
	# Initialize stack pointer to point to last word in memory. Stack is
	# used by hardware to store return address during function call. Stack
	# may also be used for temporary variables.
	movia	sp, LAST_RAM_WORD
	
	
	movi	r2, 0xD0
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
	movi	r2, 0xD1
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xD2
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xD3
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xD4
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xD5
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xD6
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xD7
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xD8
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xD9
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar    
    movi	r2, 0xDA
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
	movi	r2, 0xDB
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xDC
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xDD
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xDE
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    movi	r2, 0xDF
	call	ToHexChar
    mov		r2, r3
    call 	PrintChar
    
	movi	r2, '\n'
	call	PrintChar
    
	movia	r4, MSG
	call	PrintString
	movi	r2, '\n'
	call	PrintChar
    
	movi	r2, 0xDE
	call	PrintHex8
	movi	r2, '\n'
	call	PrintChar
    
	movi	r2, 0xAD
	call	PrintHex8
	movi	r2, '\n'
	call	PrintChar
    
	movi	r2, 0xBE
	call	PrintHex8
	movi	r2, '\n'
	call	PrintChar
    
	movi	r2, 0xEF
	call	PrintHex8
	movi	r2, '\n'
	call	PrintChar
    
_end:
	br		_end		# nothing else to do and nowhere else to go.

#==============================================================================
# Subroutine PrintChar
# Print 1 character to output device.  Taken from Lab1part2 - unchanged.
# Note that this code does not call any other functions, so it does not save
# ra.
#
# Parameters:
#	R2	- contains character to be displayed
# Return value:
#	nothing

PrintChar:
	subi	sp, sp, 8	# subtract 4 from sp, making room for two words.
	stw		r3, 4(sp)	# save contents of r3
	stw		r4, 0(sp)	# and r4.
	movia	r3, JTAG_UART_BASE	# r3 points to base of UART device registers
loop2:
	ldwio	r4, OFFSET_STATUS(r3)	# fetch contents of status register
	andhi	r4, r4, WSPACE_MASK		# keep only high-order 16 bits
	beq		r4, r0, loop2			# all 0? Try again
	# Get here when READY bit turns on
	stwio	r2, OFFSET_DATA(r3)		# Write character to data register
	# our work accomplished; restore register values
	ldw		r3, 4(sp)
	ldw		r4, 0(sp)
	addi	sp, sp, 8	# add 8 to sp, effectively discarding space on stack
	ret					# go back to calling site, all registers preserved

#==============================================================================
# Subroutine ToHexChar
# Convert 4 bit quantity at bottom of r2 to an approriate hex character
# Return the character in the low byte of r3.

hextable:	.ascii	"0123456789ABCDEF"

ToHexChar:
	subi	sp, sp, 4	# subtract 4 from sp, making room for a word.
	stw		r2, 0(sp)	# save contents of r2
	##---<SNIP>---
	andi	r2, r2, 0xF	# Get bottom 4 bits of r2
	movia	r3, hextable
    add		r3, r3, r2
	ldb		r3, 0(r3)
	##---<SNIP>---
	ldw		r2, 0(sp) 	# restore original r2
	addi	sp, sp, 4	# add 4 to sp, effectively discarding space on stack
	ret

#==============================================================================
# Subroutine PrintHex8
# Convert 8-bit quantity in bottom byte of r2 and prints out 2 characters

PrintHex8:
	subi	sp, sp, 16	# subtract 16 from sp, making room for 4 words.
	stw		ra, 12(sp)	# save contents of ra
	stw		r2, 8(sp)	# save contents of r2
	stw		r3, 4(sp)	# save contents of r3
	stw		r4, 0(sp)	# save contents of r4
	##---<SNIP>---
    mov		r4, r2
	andi	r2, r4, 0xF0# Get bits 8-5 of original r2
    srli	r2, r2, 4
	call	ToHexChar
	mov		r2, r3
    call 	PrintChar
	andi	r2, r4, 0xF	# Get bottom 4 bits of original r2
	call	ToHexChar
	mov		r2, r3
    call 	PrintChar
	##---<SNIP>---
	ldw		ra, 12(sp) 	# restore original ra
	ldw		r2, 8(sp) 	# restore original r2
	ldw		r3, 4(sp)	# restore original r3
	ldw		r3, 0(sp)	# restore original r4
	addi	sp, sp, 16	# add 16 to sp, effectively discarding space on stack
	ret

#==============================================================================
# Subroutine PrintString
# Print ASCIZ string to output device.  This code uses the PrintChar function
# so it needs to save ra.

# Parameters:
#	R4	- contains address of string to be displayed
# Return value:
#	nothing, but r4 will point to end of string

PrintString:
	# We will call another function, so we need to save contents of ra
	subi	sp, sp, 8	# subtract 8 from sp, making room for two words.
	stw		ra, 4(sp)	# save contents of ra
	stw		r2, 0(sp)	# save contents of r2
	##---<SNIP>---
loop:
	ldb		r2, 0(r4)		# fetch the byte pointed to by r3
	beq		r2, r0, done	# if byte value is 0, branch to done.
	call	PrintChar		# print character in r2
	addi	r4, r4, 1		# increment r3 pointer
	br		loop			# do next character
done:
	# add a newline character to the end
	movi	r2, '\n'		# just like C
	call	PrintChar
	##---<SNIP>---
	ldw		ra, 4(sp) 	# restore original ra
	ldw		r2, 0(sp)	# restore original r2
	addi	sp, sp, 8	# add 8 to sp, effectively discarding space on stack
	ret							# return to address in ra

#==============================================================================
	.data
	.org	0x00001000			# where this is to go in memory
MSG:.asciz	"ELEC274 Lab 3"		# 

	.end						# tells assembler this is the end

