# Evan Roman
# HW5
# The following program implements Run-length encoding, a simple compression algorithm
# The program will ask the user for a file and compress the data in the file using the "heap," otherwise exit

		.include "macros.asm"	# Include file of macros
	
		.data
heapPtr:	.word	0
inFile:		.space	64
buffer:		.space	1024
origSize:	.word	0
compressSize:	.word	0
		.text
main:
	# Allocate 1024 bytes of dynamic memory and save ptr
	allocHeap(heapPtr, 1024)
	
	# Prompt user for file name
	printStr("Please enter the filename to compress or <enter> to exit: ")
	getStr(inFile, 64)		# User inputs file name
	
	# User enters \n (nothing)
	lbu	$t0, inFile
	beq	$t0, 10, exit		# 10 for newl ASCII
	
	# Open file attempt and check for error
	openFile(inFile)
	ble	$v0, $0, failExit	# $v0 <= 0, terminate with failure
	move 	$s6, $v0     		# save the file descriptor
	
	# Read from file that was opened and store size
	readFile(buffer)
	sw	$s1, origSize
	
	# Add null terminator to end of file contents to avoid duplicate printing
	addNullToFile(buffer, origSize)
	
	# Close file that was read from
	closeFile
	
	# Print original data read from file
	printStr("\nOriginal data:\n")
	printStrMem(buffer)
	printChar('\n')
	
	# Compress data
	printStr("Compressed data:\n")
	la	$a0, buffer		# Address of input buffer
	lw	$a1, heapPtr		# Address of compression buffer
	lw	$a2, origSize		# Address of size of orig file
	jal	compressRLE		# Call compression function
	sw	$v0, compressSize	# Save size of compressed file
	
	# Print compressed data
	jal	printCompress
	printChar('\n')
	
	# Uncompress data
	printStr("Uncompressed data:\n")
	lw	$a1, heapPtr
	lw	$a2, origSize
	jal	uncRLE
	printChar('\n')
	
	# Original size
	printStr("Original file size: ")
	printInt(origSize)
	printChar('\n')
	
	# Compressed size
	printStr("Compressed file size: ")
	printInt(compressSize)
	printChar('\n')
	j	main
	
compressRLE:
	# Implement RLE compression algorithm
	li	$t0, 0			# i = 0
	li	$s1, 0			# Size of compressed file
	
outer:	# for (int i = 0; i < str.length(); i++)
	beq	$t0, $a2, compressReturn
	li	$t1, 1			# Count 1st byte
	
inner:	# while (i + 1 < str.length() && charAt(i) == charAt(i + 1))
	add	$s2, $t0, $a0		# Extract char buffer
	lbu	$t3, ($s2)		# Load char
	
	# Next char in buffer
	addi	$t2, $t0, 1
	add	$t2, $a0, $t2
	lbu	$s3, ($t2)
	
	# Check ending conditions for inner loop
	beq	$a2, $t0, store		# i < str.length()
	bne	$t3, $s3, store		# charAt(i) != charAt(i + 1)
	
	addi	$t0, $t0, 1		# i++
	addi	$t1, $t1, 1		# Count byte (count++)
	j	inner
	
store:	# Put chars in buffer
	sb	$t3, ($a1)		# Store char in buffer
	addi	$a1, $a1, 1		# Move heap ptr
	addi	$s1, $s1, 1		# Inc size of comp file
	
	bge	$t1, 10, tenths		# Count is 2 digits long
	
	addi	$t1, $t1, 48		# int -> ASCII (for file buff)
	sb	$t1, ($a1)		# Store count
	
	addi	$t0, $t0, 1		# i++
	addi	$s1, $s1, 1		# sizeOfComp++
	
	addi	$a1, $a1, 1		# inc heap ptr
	j	outer
	
tenths:
	li	$s4, 10			# 10 into register for div
	
	div	$t1, $s4		# count / 10
	mflo	$t4			# Quotient is tenths place
	
	addi	$t4, $t4, 48		# int -> ASCII
	sb	$t4, ($a1)		# Store count (tenths)
	
	addi	$a1, $a1, 1		# Move heap ptr
	addi	$s1, $s1, 1		# sizeOfComp++
	
	mfhi	$t5			# Remainder is ones place
	addi	$t5, $t5, 48		# int -> ASCII
	sb	$t5, ($a1)		# Store count (ones)
	
	addi	$t0, $t0, 1		# i++
	addi	$a1, $a1, 1		# inc heap ptr
	j	outer
	
compressReturn:
	move	$v0, $s1		# "return" comp size in $v0
	jr	$ra
	
printCompress:
	li	$v0, 4
	lw	$a0, heapPtr
	syscall
	jr	$ra
	
uncRLE:
	beq	$a2, $0, uncReturn	# Compressed file has been entirely read
	lbu	$t0, ($a1)		# 1st byte (NaN, letter or special char)
	lbu	$t1, 1($a1)		# 2nd byte (always a number)
	addi	$t1, $t1, -48		# ASCII -> int
	lbu	$t2, 2($a1)		# 3rd byte (either)
	
	bge	$t2, 58, onesCount	# Byte => 58, 3rd byte is a letter (Aa - Zz), singel digit count
	ble	$t2, 47, onesCount	# Byte <= 47, 3rd byte is NaN, single digit count
	
	# Byte is 48 <= x <= 57, 0 to 9
	# The count in the comp file must be 2 digits
	addi	$t2, $t2, -48		# ASCII -> int
	mul	$t1, $t1, 10		# Get tenths place
	add	$t1, $t1, $t2		# n * 10 + single digit num = count
	
	printUncompChars($t0, $t1)	# Print line of $t0 for $t1: (i < $t1) print $t0
	sub	$a2, $a2, $t1		# Decrease size by chars
	addi	$a1, $a1, 3		# Move to next byte that is a letter or special char in comp file (NaN)
	j	uncRLE
	
onesCount:
	# $t1 decribes count of char in compressed file
	printUncompChars($t0, $t1)	# Print line of $t0 for $t1: (i < $t1) print $t0
	sub	$a2, $a2, $t1		# Decrease size by chars
	addi	$a1, $a1, 2		# Move to next byte that is a letter or special char in comp file (NaN)
	j	uncRLE

uncReturn:
	jr	$ra
	
failExit:
	printStr("\nError opening file. Program terminating.")
	
exit:	# End program
	li	$v0, 10
	syscall
