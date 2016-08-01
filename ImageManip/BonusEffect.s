	AREA	BonusEffect, CODE, READONLY
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

	LDR R10, = 0x00818181 ;; threshold
	LDR R7, = 0 ;; i = 0
	LDR R9, = 0 ;; index = 0
iForLoop1
	LDR R8, = 0 ;; j = 0
	CMP R7, R6 ;; compare it to the width
	BEQ endiForLoop1
jForLoop1 
	MOV R2, R10 ;;pass in parameters to compareSub
	MOV R1, R9
	MOV R0,	R4
	BL compareSub
	ADD R9, R9, #4 ;; increment index
	CMP R8, R5 ;; compare it to the height
	BEQ endjForLoop1
	ADD R8, R8, #1 ;; increment j
	B jForLoop1
endjForLoop1
	ADD R7, R7, #1 ;; increment i
	B iForLoop1
endiForLoop1

	LDR R9, = 0 ;; index = 0
	LDR R7, = 0 ;; i = 0
iForLoop2
	LDR R8, = 0 ;; j = 0
	CMP R7, R6 ;; compare it to the width
	BEQ endiForLoop2
jForLoop2
	MOV R2, R10
	MOV R1, R9
	MOV R0,	R4
	BL alphaChannelSub
	ADD R9, R9, #4 ;; increment index
	CMP R8, R5 ;; compare it to the height
	BEQ endjForLoop2
	ADD R8, R8, #1 ;; increment j
	B jForLoop2
endjForLoop2
	ADD R7, R7, #1 ;; increment i
	B iForLoop2
endiForLoop2
	BL	putPic		;; re-display the updated image
	B stop
	
compareSub
;; compares two numbers and sees if the difference is greater than the threshold
;; parameters r0 - memory location
;;			  r1 - index
;;			  r2 - threshold
;; return values none
	STMFD SP!,{R4-R10, LR}
	LDR R4, [R0, R1] ;; load pixel
	MOV R8, R4, LSL #8 ;; alpha channel temporarily ignored 
	LSR R8, #8
	ADD R1, R1, #4 ;; take next pixel
	LDR R5, [R0, R1]
	MOV R9, R5, LSL #8 ;; alpha channel temporarily ignored 
	LSR R9, #8
	CMP R8, R9 ;; checks if a is greater than b and branches to either a - b or b - a depending on which is bigger
	BHS aMinusB
	SUB R6, R9, R8 ;; temp variable for difference between them
	CMP R6, R2 ;; if the difference is >= threshold it sets the flag in the alpha channel
	BHS setFlagB
	B endCompareSub
	
aMinusB
	SUB R6, R8, R9 ;; temp variable for difference between them
	CMP R6, R2 ;; if the difference is >= threshold it sets the flag in the alpha channel
	BHS setFlagA 
	B endCompareSub	

setFlagA
	ADD R4, R4, #0x10000000 ;; sets alpha channel flag to true then stores over original
	SUB R1, R1, #4
	STR R4, [R0, R1]
	B endCompareSub
setFlagB
	ADD R5, R5, #0x10000000 ;; sets alpha channel flag to true then stores over original
	STR R5, [R0, R1]
	B endCompareSub

endCompareSub
	LDMFD SP!, {R4-R10,PC}
	

	
alphaChannelSub
;; checks alpha channel and sets pixel to either black or white based on that
;; parameters r0 - memory location
;; 			  r1 - index

	STMFD SP!, {R4-R5, LR}
	LDR R4, [R0, R1] ;; load pixle
	LDR R5, =0x01000000
	CMP R4, R5 ;; if the alpha channel isn't set it is not an edge so make it white
	BLO makeWhite
	LDR R4, =0x00000000 ;; if alpha channel is set make it black then store
	STR R4, [R0, R1]
	B endAlphaChannelSub
	
	
makeWhite
	MOV R4, R5 ;; sets to 0x00FFFFFF which is white and stores
	SUB R4, R4, #1
	STR R4, [R0, R1]
	B endAlphaChannelSub
	

endAlphaChannelSub
	LDMFD SP!, {R4-R5, PC}

stop	B	stop


	END	
