#      $File: NewcastleUniversity/ELEC4720/2025s2/Makefile $
#      $Date: 2025-10-13 04:07:50 +1100 (Mon, 13 Oct 2025) $
#  $Revision: 2482 $
#    $Author: Peter $
#
#     Course: ELEC4720(2025s2) Programmable Logic Design
#     School: Engineering
# University: The University of Newcastle
#    Address: CALLAGHAN NSW 2308 Australia
#
#     Author: Dr Peter Stepien
#      Email: pstepien@ieee.org (peter.stepien@newcastle.edu.au)
#  Copyright: 2025
	
# Assignment 2 Demonstration Program

	.data
	.globl buffer

buffer:
	.space 4

	.text
	.globl main
	.globl loop
	.globl exit

main:
	# Initialise some registers
	subu $t0, $t0, $t0 # Set t0=0
	addiu $t1, $t0, 7  # Set t1=7

	# Memory operations
	sw $t1, buffer     # Save t1 to buffer
	lw $t2, buffer     # Load t2 from buffer
	
	# Remaining arithmetic
	addu $t3, $t1, $t2 # Unsigned t3=t1+t2=14
	sub $t4, $t1, $t3  # Signed t4=t1-t3=-7
	addi $t5, $t1, 3   # Signed t5=t1+3=10
	add $t6, $t4, $t5  # Signed t6=t4+t5=3

	# Logical
	and $s0, $t1, $t5  # s0=t1 and t5 = 2
	or $s1, $t1, $t5   # s1=t1 or t5 = 15
	xor $s2, $t1, $t5  # s2=t1 xor t5 = 13
	nor $s3, $t1, $t5  # s0=t1 nor t5 = not 15

	# Comparison
	slt $s4, $t4, $t6  # Signed s4=t5 < t6 = 1 (true)
	sltu $s5, $t4, $t6 # Unsigned s5=t5 < t6 = 0 (false)

	# Loop to test jump and branch (not optimal)
loop:
	addiu $t0, $t0, 1  # Increment counter
	beq $t0, $t5, exit # Exit loop (t0=10)
	j loop             # Loop again

# System call to exit program (spim)
# Your program needs to stop here

exit:
	li $v0, 10
	syscall

# END OF FILE
