# LB5PRT2.S [170309]
# QECE ELEC274 Lab exercise 5, part 3
###############################################################################
# Code to demonstrate inputting a multi-character value, converting it to
# its numeric equivalent, and then displaying the value on the 8SEGMENT
# display.
#
# Author:
#    David Athersych, P.Eng.
# History:
#	 170309	1.0	DA	Original release
#	 180226	1.1	DA	Minor modifications; increase commenting
#
#==============================================================================
#
# Directives - configuration information to the assembler.

# Symbol definitions
	.equ	LAST_RAM_WORD, 0x007FFFFC
	.equ	ESC_CHAR, 0x33				# ESC character
	.equ	CR, 0x0D					# CR (Carriage return) character
	.equ	LF, 0x0A					# LF (Line feed) character
	.equ	NUL, 0x00					# NUL (0) character - end of string char.
	
	.equ	LED_ADDR,	0x10000010		# address of 10 bit LED port
	.equ	EIGHTSEG,	0x10000020		# address of 8-segment display register
	.equ	ATESEG,		0x10000020		# compatible with code from lecture
	.equ	ByteMask,	0xFFFFFF00		# mask used to isolate 8-segs
		
	# Define base address for device, offsets and register masks.
	.equ	JTAG_UART_BASE,	0x10001000	# base address of JTAG UART
	.equ	OFFSET_DATA,	0			# offset from base for data register
	.equ	OFFSET_STATUS,	4			# offset from base for status register
	.equ	WSPACE_MASK,	0xFFFF		# 16 bit mask used to get status bits
	.equ	RVALID,			0x8000		# Read data available bit in data reg.
	.equ	DATA_IN_MASK,	0x00FF		# input data in bottom byte

#==============================================================================
.macro  rori    out, in, num
    roli    \out, \in, (32 - \num)
.endm
#==============================================================================

# Object module configuration.
	.text				# tell assembler that this is code segment
	.global	_start		# tell assembler that _start is visible to linker
	.org	0x00000400	# starting address for the following code

#==============================================================================
# Table of 8-segment patterns used to display 4-bit values 0x0 to 0xF. Note
# that each pattern takes 8 bits, so 4-segment display needs 32 bit value to
# display a 16-bit numeric value.
# (Note also that Table is kept in nonvolatile .TEXT section, not .DATA
 
Table:
	.byte	0x3F, 0x06, 0x5B, 0x4F
	.byte	0x66, 0x6D, 0x7D, 0x07
	.byte	0x7F, 0x67, 0x77, 0x7C
	.byte	0x39, 0x5E, 0x79, 0x71

Error:	.byte	0xC0				# error pattern
		.skip	3					# manual alignment to 4 byte boundary
#==============================================================================
	
# -------------------- START --------------------

_start:

	movia	sp, LAST_RAM_WORD	# set up stack pointer to last word in RAM
	
	# Prompt user to enter data
repeat:
	stw		r0, Num(r0)		# initialize accumulator
	movi	r7, 4			# count digits
	
	# Prompt user to enter data
	movia	r4, Prompt
	call	PrintString
	
Get4:
	# Now just cycle - reading a character, displaying what was read
	# converting to equivalent number and then adding to 4 digit
	# number.

	# Read a character
	call 	GetJTAG
	
	# Check if character is a letter A - F
	movui	r4, 'A'
	movui	r5, 'F'
    bltu	r2, r4, NotValidLetter
    bgtu	r2, r5, NotValidLetter
	
	# Convert ASCII letter A - F to decimal number
	subi	r2, r2, 'A'
	addi	r2, r2, 10
	
	br		BuildUpNumber
	
	# Check if character is a number 0 - 9
NotValidLetter:	
	movui	r4, '0'
	movui	r5, '9'
    bltu	r2, r4, BadChar
    bgtu	r2, r5, BadChar
	
	# Convert ASCII number to decimal number
	subi	r2, r2, '0'
	
	movi	r5, -1			# all 1s - it will be sign-extended
	beq		r2, r5, BadChar
	
	# Build up number being read in
	# start by shifting everything accumulated so far by 4 bits
BuildUpNumber:
	ldw		r6, Num(r0)		# get number so far
	slli	r6, r6, 4		# shift over 4 bits
	or		r6, r6, r2		# or the new 4 bits at the bottom
	stw		r6, Num(r0)		# store number for next time
	# Got enough yet?
	subi	r7, r7, 1		# decrement character counter
	bne		r7, r0, Get4	# not done, get another digit

	# Got 4 digits, show number on 8 segment display
	mov		r2, r6
	call	Show8Seg
	movi	r2, '\n'			# just like C
	call	PutJTAG
	
	br		repeat			# do it all over again

_end:
	br		_end			# nothing else to do and nowhere else to go.

BadChar:
	# Get here when an invalid character detected
	movi	r2, '\n'			# just like C
	call	PutJTAG
	movia	r4, BdChMsg
	call	PrintString
	br		repeat

###############################################################################
# Extract needed code from previous work:
# MACROS.S 8SEG.S CHARS.S JTAGPOLL.S

#==============================================================================
# Subroutine UpdLEDs
# Update all 10 LEDs
#
# Parameters:
#	R2	- contains 10 bit value to be displayed on LEDs
# Return value:
#	R2	- unchanged


UpdLEDs:
	subi	sp, sp, 4		# space for saved register value
	stw		r3, 0(sp)		# save R3
	movia	r3, LED_ADDR	# Address of LED output port
	stwio	r2, 0(r3)		# write parameter value to LED port
	movia	r3, LEDS		# get address of saved copy
	stw		r2, 0(r3)		# keep it - used by LEDbits (future code addition)
	ldw		r3, 0(sp)		# restore register
	addi	sp, sp, 4		# discard stack space
	ret
	
#==============================================================================
# Subroutine Show8Seg
# Update all 4 8-segment displays on the DE0 board
#
# Parameters:
#	R2	- contains 16 bit value to be displayed in 4 4-bit groups
# Return value:
#	R2	- unchanged

Show8Seg:
	#pshregs	ra, r2, r3, r4, r5, r6
	subi	sp, sp, 24
	stw		ra, 0(sp)
	stw		r2, 4(sp)
	stw		r3, 8(sp)
	stw		r4, 12(sp)
	stw		r5,	16(sp)
	stw		r6, 20(sp)
	sub		r3, r3, r3		# zero r3
	movi	r5, 0x0F		# 4 bits in bottom of r5 (why?)
L1:
	andi	r4, r2, 0x0F	# bottom 4 bits of r2 in r4
	ldbu	r6, Table(r4)	# load pattern into r6 (gets 0 extended)
	or		r3, r3, r6		# OR pattern into bottom byte of r3
	srli	r2, r2, 4		# shift bottom 4 bits into bit bucket
	rori	r3, r3, 8		# rotate r3 register to right 8 bits
	srli	r5, r5, 1		# shift r5 right by 1 bit
	bne		r5, r0, L1		# aha! We were using r5 to count the loop!
	# At this point, r3 has 4 patterns - for each of the 4 displays
	movia	r5, EIGHTSEG	# address of 8-segment display
	stwio	r3, 0(r5)		# write pattern to display
	movia	r5, Ondisp		# address of local where we store a copy
	stw		r3, 0(r5)
	# done
Restore:
	#popregs	r6, r5, r4, r3, r2, ra
	ldw		ra, 0(sp)
	ldw		r2, 4(sp)
	ldw		r3, 8(sp)
	ldw		r4, 12(sp)
	ldw		r5,	16(sp)
	ldw		r6, 20(sp)
	addi	sp, sp, 24
	ret

#==============================================================================
# Subroutine One8Seg
# Update just one 8-segment display
#
# Parameters:
#	R2 -	Bottom 4 bits [3:0] contain value to display
#			Bits 4 & 5 contain position to display in 00, 01, 10 11
# Return value:
#	R2	-	Unchanged
# NOTE:
#	This code has the same epilog as the function above!

One8Seg:
	#pshregs	ra, r2, r3, r4, r5, r6
	subi	sp, sp, 24
	stw		ra, 0(sp)
	stw		r2, 4(sp)
	stw		r3, 8(sp)
	stw		r4, 12(sp)
	stw		r5,	16(sp)
	stw		r6, 20(sp)
	mov		r6, r2			# save copy
	andi	r2, r2, 0x0F	# keep only bottom 4 bits
	ldbu	r2, Table(r2)	# get display pattern for this value
	# now need to figure out where to store it
	srli	r6, r6, 4		# get bits [5:4] into positions [1:0]
	slli	r6, r6, 3		# get number of bits to shift over (mul 8)
	sll		r2, r2, r6		# put pattern into correct byte position
	movia	r4, ByteMask	# Mask to clean out existing data
	rol		r4, r4, r6		# get 0 byte into correct position also
	movia	r5, Ondisp		# address of what is currently on display
	ldw		r6, 0(r5)		# fetch display value
	and		r6, r6, r4		# zero byte we're changing
	or		r6, r6, r2		# and store new value for that byte
	movia	r3, EIGHTSEG	# address of 8-segment display
	stwio	r6, 0(r3)		# light up the leds
	stw		r6, 0(r5)		# store updated copy of led value
	br		Restore			# same epilogue

#==============================================================================
# Subroutine PutJTAG
# Write character to JTAG output port.  Characters written to this port will
# be displayed on monitor screen.
# Parameters:
#	R2	- contains character to be displayed
# Return value:
#	nothing

	.global	PutJTAG

PutJTAG:
	subi	sp, sp, 8	# subtract 8 from sp, making room for two words
	stw		r3, 4(sp)	# save contents of r3
	stw		r4, 0(sp)	# and r4.
	movia	r3, JTAG_UART_BASE	# r3 points to base of UART device registers
loop2:
	ldwio	r4, OFFSET_STATUS(r3)	# fetch contents of status register
	andhi	r4, r4, WSPACE_MASK		# keep only low-order 16 bits
	beq		r4, r0, loop2			# all 0? Try again
	# Get here when READY bit turns on
	stwio	r2, OFFSET_DATA(r3)		# Write character to data register
eggsit:
	# our work accomplished; restore register values
	ldw		r3, 4(sp)
	ldw		r4, 0(sp)
	addi	sp, sp, 8	# add 8 to sp, effectively discarding space on stack
	ret					# go back to calling site, all registers preserved
	
#==============================================================================
# Subroutine GetJTAG
# Read character from JTAG input port.  Characters read from this port will
# also be echoed back, that is, displayed on monitor screen.
# Parameters:
#	none
# Return value:
#	R2	- contains character read

	.global	GetJTAG

GetJTAG:
	subi	sp, sp, 8	# two words on stack
	stw		r3, 4(sp)
	stw		r4, 0(sp)
	movia	r3, JTAG_UART_BASE	# point to JTAG base register
loop3:
	ldwio	r2, 0(r3)			# read JTAG register
	andi	r4, r2, RVALID		# check if data available
	beq		r4, r0, loop3		# if no data, check again
	# character returned in r2
	andi	r2, r2, 0x00ff		# data in least significant byte
	# handle echo, so human can see what was typed.  Assume output is ready,
	# (fairly safe assumption if JTAG being used for human input) so just
	# write character to output port
	stwio	r2, OFFSET_DATA(r3)	# write character to data register
	# restore saved registers
	br	eggsit					# use existing exit code in PutJTAG
	
#==============================================================================
# Subroutine GetString
# Reads characters from serial port and stores them in supplied buffer. Stops
# when buffer is full or when CR character found. End of input marked with
# NUL character.
#
# Uses:
#	GetJTAG - fetches one character from serial port
#
# Parameters:
#	R4	- Address of buffer to fill.
#	R3	- length of buffer
# Returns:

GetString:
	# Save registers
	subi	sp, sp, 12			# space for three registers
	stw		ra, 8(sp)			# return address
	stw		r2, 4(sp)			# working register
	stw		r5, 0(sp)			# working register
	# r4 points to buffer, r3 holds max length. Neither will be preserved.
gsloop:
	cmplei	r5, r3, 1			# make sure r3 greater than 1
	bne		r5, r0, gsdone		# r5 non-zero if r3 <= 1
	call	GetJTAG				# returns with character in R2
	cmpeqi	r5, r2, '\n'		# was it return key?
	bne		r5, r0, gsdone		# r5 non-zero if r2 == LF
	stb		r2, 0(r4)			# store character read where r4 points
	addi	r4, r4, 1			# move buffer pointer by 1 character
	subi	r3, r3, 1			# one less place in buffer
	br		gsloop				# do it again
gsdone:
	# Either r3 says only one more byte left, or just read CR character
	# Store end-of-string marker in buffer, restore registers and return
	stb		r0, 0(r4)			# NUL byte for end of string
	ldw		r5, 0(sp)			# restore R5
	ldw		r2, 4(sp)
	ldw		ra, 8(sp)
	addi	sp, sp, 12
	ret
	
#==============================================================================
# Subroutine PrintString
# Print ASCIZ string to output device.  This code uses the PrintChar function
# so it needs to save ra.  Note that this code will keep outputting characters
# until NUL found - it does not have any length checking.

# Parameters:
#	R4	- contains address of string to be displayed
# Return value:
#	R4	- point to end of string (i.e. null character at end.

PrintString:
	# We will call another function, so we need to save contents of ra
	subi	sp, sp, 8			# decrement stack pointer by 2 words
	stw		ra, 4(sp)			# store ra on stack
	stw		r2, 0(sp)			# Use R2 to pass character to PrintChar
	# r4 points to ASCIZ string, but we won't preserve it
loop0:
	ldb		r2, 0(r4)			# fetch the byte pointed to by r4
	beq		r2, r0, done		# if byte value is 0, branch to done.
	call	PutJTAG				# print character in r2
	addi	r4, r4, 1			# increment r4 pointer
	br		loop0				# do next character
done:
	# add a newline character to output
	movi	r2, '\n'			# just like C
	call	PutJTAG
	# restore saved r2 contents
	ldw		r2, 0(sp)			# value at top of stack is saved r2
	ldw		ra, 4(sp)			# value below that is saved ra
	addi	sp, sp, 8			# two words off stack pointer
	ret							# return to address in ra

#==============================================================================
# Static data.
Prompt:	.asciz	"Type 4 digit hex number: "
BdChMsg:.asciz	"Bad character"
CRLF:	.byte	CR, LF, NUL
#==============================================================================

	.org	0x00001000	# where this data is to go in memory
	.DATA
Num:	.word	0		# used to accumulate number read in
Ondisp:	.word	0		# save value currently on display in 8 segment
LEDS:	.word	0		# save value currently on display in LEDs

InBuff:	.skip	64		# 64 byte buffer should be big enough

	.end				# tells assembler this is the end

