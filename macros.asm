# Contains all macros used in HW5

	# Allocate dynamic memory (heap)
	.macro	allocHeap(%addr, %numBytes)
	li	$v0, 9
	li	$a0, %numBytes		# Allocate num of bytes
	syscall
	sw	$v0, %addr		# Save ptr
	.end_macro
	
	# Print int
	.macro	printInt(%int)
	li	$v0, 1
	lw	$a0, %int
	syscall
	.end_macro
	
	# Print char
	.macro	printChar(%char)
	li	$v0, 11
	la	$a0, %char
	syscall
	.end_macro

	# Print string
	.macro	printStr(%str)
		.data
	msg:	.asciiz	%str
		.text
	li	$v0, 4
	la	$a0, msg
	syscall
	.end_macro
	
	# Print string that is stored in memory
	.macro	printStrMem(%str)
	li	$v0, 4
	la	$a0, %str
	syscall
	.end_macro
	
	# Print chars that were uncompressed
	.macro	printUncompChars(%char, %size)
	move	$s3, %size
	
	loopChars:
	# Print char for size amt
	beq	$s3, $0, return
	li	$v0, 11
	move	$a0, %char
	syscall
	addi	$s3, $s3, -1	# size--
	j	loopChars
		
	return:
	.end_macro
	
	# Get string
	.macro getStr(%buffer, %bytes)
	li	$v0, 8
	la	$a0, %buffer
	la	$a1, %bytes
	syscall
	.end_macro
	
	# Add \0 to end of file content (buffer)
	.macro	addNullToFile(%buffer, %size)
	lw	$t1, %size
	la	$t0, %buffer
	
	add	$t0, $t0, $t1		# End of contents
	sb	$0, ($t0)		# Add \0 to end
	.end_macro
	
	
	# Open file
	.macro	openFile(%fileName)
	
	# First replace \n with \0
	la	$t0, %fileName
	findNewl:
	lbu	$t1, ($t0)
	beq	$t1, 10, replace	# $t1 == '\n'
	addi	$t0, $t0, 1		# next char
	j	findNewl
	
	replace:
	sb	$0, ($t0)		# '\n' = '\0'
	
	li	$v0, 13			# system call for open file
	la	$a0, %fileName		# $a0 = fileName
	li	$a1, 0			# Open for reading (flags are 0: read, 1: write)
	li	$a2, 0			# Mode is ignored
	syscall
	.end_macro
	
	# Read file
	.macro readFile(%buffer)
	li	$v0, 14			# system call for file read
	move	$a0, $s6		# file descriptor
	la	$a1, %buffer		# address of buffer to read into
	li	$a2, 1024		# hardcoded buffer length
	syscall				# read from file
	move	$s1, $v0	 	# $s1 = Number of characters read
	.end_macro
	
	# Close file
	.macro	closeFile
	li   	$v0, 16       		# system call for close file
  	move 	$a0, $s6      		# file descriptor to close
  	syscall				# close file
	.end_macro