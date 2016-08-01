	AREA	Adjust, CODE, READONLY
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
	MOV	R6, R0
	BL	getPicWidth	;; load the width of the image (columns) in R6
	MOV	R5, R0

	LDR R10, = 0x10 ;brightness
	LDR R11, = 0x08 ;contrast
	LDR R12, = 0x10 ;divisor
	LDR R7, = 0
	LDR R9, = 0
iForLoop
	LDR R8, = 0
	CMP R7, R5
	BEQ endiForLoop
jForLoop
	LDR R0,[R4, R9]
	BL componentSub
	BL contrastSub
	BL brightenSub
	BL combineSub
	STR R0, [R4, R9]
	ADD R9, R9, #4
	CMP R8, R6
	BEQ endjForLoop
	ADD R8, R8, #1
	B jForLoop
endjForLoop
	ADD R7, R7, #1
	B iForLoop
endiForLoop
	BL	putPic		; re-display the updated image
	B stop
	
	
divideSub
	;; take a wild guess, doesn't return remainder
	;; parameters R0 - number to be divided
	;;			  R12 - divisor
	;; return values R0 - answer
	
	STMFD SP!, {R4 - R12, LR}
	MOV R4, R12
	MOV R5, R0
	LDR R6, = 0x00
divWhile
	CMP R5, R4
	BLO endDivWhile
	ADD R6, R6, #1
	SUB R5, R5, R4
	B divWhile
endDivWhile
	MOV R0, R6
	LDMFD SP!, {R4 - R12, PC}

combineSub
	;; combines components back into a single register
	;; parameters r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	;; return values r0 - colour of combined parts
	
	STMFD SP!, {R4-R12,LR}
	LDR R0, =0
	ADD R0, R0, R3
	ADD R0, R0, R2
	ADD R0, R0, R1
	LDMFD SP!, {R4-R12,PC}

contrastSub
	;; changes the contrast of each component
	;; parameters r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	;; return values r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	
	STMFD SP!, {R4-R12,LR}
	MUL R1, R11, R1
	LSR R1, #16
	MOV R0, R1
	BL divideSub
	LSL R0, #16
	MOV R1, R0
	
	MUL R2, R11, R2
	LSR R2, #8
	MOV R0, R2
	BL divideSub
	LSL R0, #8
	MOV R2, R0
	
	MUL R3, R11, R3
	MOV R0, R3
	BL divideSub
	MOV R3, R0
	
	LDMFD SP!,{R4-R12,PC}
	
checkSub
	;; checks components to see that none have gone past 255 or 0
	;; parameters r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	;; return values r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	
	
	STMFD SP!, {R4-R12,LR}
	LDR R9, = 0x00FF0000
	LDR R10, = 0x0000FF00
	LDR R11, = 0x000000FF
redStart
	CMP R1, R9
	BGT setRedMax
	CMP R1, R10
	BLE setRedMin
greenStart
	CMP R2, R10
	BGT setGreenMax
	CMP R2, R11
	BLE setGreenMin
blueStart
	CMP R3, R9
	BGT setBlueMin
	CMP R3, R10
	BLE setBlueMax
finishedChecking
	LDMFD SP!, {R4-R12,PC}

setRedMax
	MOV R1, R9
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


componentSub
	;; getting individual RGB components of a given colour
	;; parameter r0 - colour passed in
	;; return values r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	STMFD SP!, {LR}
	AND R1, R0, #0x00FF0000
	AND R2, R0, #0x0000FF00
	AND R3, R0, #0x000000FF
	
	LDMFD SP!, {PC}
	
brightenSub
	;; takes the components of a pixel and makes them brighter
	;; parameters r1 - red value
	;;			  r2 - green value
	;; 			  r3 - blue value
	;; return values r1 - brighter red value
	;;			  r2 - brighter green value
	;; 			  r3 - brighter blue value
	
	STMFD SP!,{R4-R12,LR}
	LSL R10, #16
	ADD R1, R1, R10
	LSR R10, #16
	LSL R10, #8
	ADD R2, R2, R10
	LSR R10, #8
	ADD R3, R3, R10

	BL checkSub

	LDMFD SP!, {R4-R12,PC}
stop	B	stop


	END	

