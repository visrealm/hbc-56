*=$8000

!initmem $EF

PORT = $7f00

main:
	lda #1
	clc
	sta PORT
loop:	
	rol 
	sta PORT
	rol
	sta PORT
	rol
	sta PORT
	rol
	sta PORT
	rol
	sta PORT
	rol
	sta PORT
	rol
	sta PORT
	ror
	sta PORT
	ror
	sta PORT
	ror
	sta PORT
	ror
	sta PORT
	ror
	sta PORT
	ror
	sta PORT
	ror
	sta PORT
	jmp loop

*=$FFFC
!word $8000