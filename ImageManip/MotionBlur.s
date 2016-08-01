	AREA	MotionBlur, CODE, READONLY
	IMPORT	main
	IMPORT	getPicAddr
	IMPORT	putPic
	IMPORT	getPicWidth
	IMPORT	getPicHeight
	EXPORT	start

start
	PRESERVE8
	BL	getPicAddr	;; load the start address of the image in R4
	MOV	R4, R0
	BL	getPicHeight	;; load the height of the image (rows) in R5
	MOV	R5, R0
	BL	getPicWidth	;; load the width of the image (columns) in R6
	MOV	R6, R0

	LDR R10, = 11 ;; radius 
	LDR R7, = 0 ;; set i = 0
iForLoop
	LDR R8, = 0 ;; set j = 0
	CMP R7, R6 ;; compare it to the width
	BEQ endiForLoop
jForLoop
	MUL R9, R5, R7 ;; gets index by multiplying height by i and then adding j
	ADD R9, R9, R8
	MOV R3, R10 ;; pass in parameters to merge function
	MOV R2, R6
	MOV R1, R9
	MOV R0,	R4
	BL mergeSub
	MOV R1, R9 ;; reset r1 and r2 as parameters to store function
	MOV R2, R4
	BL storeSub
	CMP R8, R5 ;; compare it to the height
	BEQ endjForLoop
	ADD R8, R8, #1 ;; increment j and carry on
	B jForLoop
endjForLoop
	ADD R7, R7, #1 ;; increment i and carry on
	B iForLoop
endiForLoop
	BL	putPic ;; re-display the updated image
	B stop
	
	
storeSub
	;; stores a given value in memory
	;; parameters r0 - value to be stored
	;;			  r1 - index of a storage location
	;; 			  r2 - address for storage
	;; return values - null
	
	STMFD SP!, {LR}
	STR R0, [R2, R1, LSL #2] ;; I wonder what this store command might do?
	LDMFD SP!, {PC}
	
mergeSub
	;; merges together pixels and causes a blur effect
	;; parameters r0 - address of 0,0
	;;			  r1 - index
	;;			  r2 - width
	;;			  r3 - radius
	;; return values r0 - blurred pixel
	
	STMFD SP!, {R4-R12, LR}
	MOV R11, R0 ;; move parameters to other places so they won't be overwritten
	MOV R9, R1
	MOV R4, R2
	MOV R10, R3
	LDR R0, [R11, R9, LSL #2] ;; load pixel
	BL componentSub
	MOV R5, R1 ;; take each component and store them in a safe place
	MOV R6, R2
	MOV R7, R3
	MOV R0, R10
	LDR R12, =0x02 ;; load divisor and divide radius by 2
	BL divideSub
	MOV R12, R0
	LDR R8, =0 ;; set counter to 0

negativeForLoop
	BL getMaxValueSub ;; find max value for later usage
	CMP R8, R12 ;; need to do blur upwards by radius/2
	BGE endNegativeForLoop
	SUB R9, R9, R4 ;; move one row backwards
	CMP R9, R1
	BHI setXMax ;; if index is greater than max then set to max
negativeForReturn1
	SUB R9, R9, #1 ;; move one column backwards
	CMP R9, R1
	BHI setYMax ;; if index is greater than max then set to max
negativeForReturn2
	LDR R3, [R11, R9, LSL #2] ;;  load pixel
	MOV R0, R3 ;; pass as parameter to component sub
	BL componentSub
	ADD R5, R1 ;; add the component values to the total values for each colour
	ADD R6, R2
	ADD R7, R3
	ADD R8, R8, #1
	B negativeForLoop
endNegativeForLoop
	LDR R8, =0
	B resetIndexLoop

resetIndexLoop ;; this loops sets the index back to the original pixel
	BL getMaxValueSub
	ADD	R9, R9, R4 ;; move one row and one column forwards
	ADD R9, R9, #1
	ADD R8, R8, #1
	CMP R8, R12 ;; once the counter is the same as the radius/2 we have undone the index changes
	BNE resetIndexLoop
	LDR R8, =0
	B positiveForLoop
positiveForLoop
	CMP R8, R12
	BGE endPositiveForLoop
	ADD R9, R9, R4
	CMP R9, R1
	BHI setXMin ;; if index is greater than max then set to 0
positiveForReturn1
	ADD R9, R9, #1
	CMP R9, R1
	BHI setYMin ;; if index is greater than max then set to 0
positiveForReturn2
	LDR R3, [R11, R9, LSL #2] ;; load pixel and add components to totals
	MOV R0, R3
	BL componentSub
	ADD R5, R1
	ADD R6, R2
	ADD R7, R3
	ADD R8, R8, #1
	B positiveForLoop

endPositiveForLoop
	MOV R12, R10 ;; set radius as divisor for averaging
	MOV R0, R5 ;; take each total colour value and average them
	LSR R0, #16 ;; right shifted for efficiency
	BL divideSub
	LSL R0, #16
	MOV R1, R0 ;; then store in original place of colour value for later passing as parameter
	MOV R0, R6 ;; same as above
	LSR R0, #8 
	BL divideSub
	LSL R0, #8
	MOV R2, R0
	MOV R0, R7 ;; same as above
	BL divideSub
	MOV R3, R0
	BL checkSub
	BL combineSub
	MOV R1, R9
	MOV R2, R11
	LDMFD SP!, {R4-R12, PC}
	
setXMax
	MOV R9, R1
	B negativeForReturn1
	
setYMax
	MOV R9, R1
	B negativeForReturn2

setXMin
	LDR R9, =0
	B positiveForReturn1

setYMin
	LDR R9, =0
	B positiveForReturn2
	
getMaxValueSub
	;; finds the max value for an index
	;; parameters - none
	;; return value r1 - max value
	STMFD SP!, {LR}
	BL getPicWidth
	MOV R2, R0
	BL getPicHeight
	MOV R3, R0
	LDR R1, =1 ;; number of columns * columns length + width gives max value
	MUL R1, R3, R1
	MUL R1, R3, R1
	ADD R1, R1, R2
	LDMFD SP!, {PC}

checkSub
	;; checks components to see that none have gone past 255 or 0
	;; parameters r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	;; return values r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	
	
	STMFD SP!, {R4-R12,LR}
	LDR R9, = 0x00FF0000 ;; max values for comparison
	LDR R10, = 0x0000FF00
	LDR R11, = 0x000000FF
redStart
	CMP R1, R9  ;; if greater than max then set to max
	BHI setRedMax
	CMP R1, R10 ;; if less than min then set to min
	BLS setRedMin
greenStart
	CMP R2, R10 ;; if greater than max then set to max
	BHI setGreenMax
	CMP R2, R11 ;; if less than min then set to min
	BLS setGreenMin
blueStart
	CMP R3, R9 ;; if the value is greater than the max of red it must have overflowed so set it to min
	BHI setBlueMin
	CMP R3, R11 ;; else if greater than max it must have gone too high so set it to max
	BHS setBlueMax
finishedChecking
	LDMFD SP!, {R4-R12,PC}

setRedMax
	MOV R1, R9 ;; these should be self evident based on their names
	B greenStart
	
setRedMin
	LDR R1, =0x00
	B greenStart

setGreenMax
	MOV R2, R10
	B blueStart

setGreenMin
	LDR R2, =0x00
	B blueStart

setBlueMin
	LDR R3, =0x00
	B finishedChecking

setBlueMax
	MOV R3, R11
	B finishedChecking
	
	
	
divideSub
	;; take a Wild Guess, doesn't return remainder
	;; parameters R0 - number to be divided
	;;			  R12 - divisor
	;; return values R0 - answer
	
	STMFD SP!, {R4-R12, LR}
	MOV R4, R12
	MOV R5, R0
	LDR R6, = 0x00 ;; clear R6 for use as a counter
divWhile
	CMP R5, R4 ;; if divisor is greater than dividend then end the loop
	BLO endDivWhile
	ADD R6, R6, #1 ;; increment counter and subtract divisor from dividend
	SUB R5, R5, R4
	B divWhile
endDivWhile
	MOV R0, R6 ;; store answer in return value register
	LDMFD SP!, {R4-R12, PC}
	

combineSub
	;; combines components back into a single register
	;; parameters r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	;; return values r0 - colour of combined parts
	
	STMFD SP!, {R4-R12,LR}
	LDR R0, =0 ;; clears r0 and sums all the colour values, simple stuff
	ADD R0, R0, R3
	ADD R0, R0, R2
	ADD R0, R0, R1
	LDMFD SP!, {R4-R12,PC}

	

componentSub
	;; getting individual RGB components of a given colour
	;; parameter r0 - colour passed in
	;; return values r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	
	STMFD SP!, {LR}
	
	AND R1, R0, #0x00FF0000 ;; clears all bits that are not in the red value
	AND R2, R0, #0x0000FF00 ;; clears all bits that are not in the green value
	AND R3, R0, #0x000000FF ;; clears all bits that are not in the blue value
	
	LDMFD SP!, {PC}

	
	
stop	B	stop


	END	
