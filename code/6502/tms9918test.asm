!to "tms9918test.o", plain

!source "hbc56.asm"

!source "gfx/tms9918.asm"

main:
        lda #0

        jsr tmsInit

        +tmsPrint "TI BASIC READY", 1, 16
        +tmsPrint ">10 PRINT \"HELLO WORLD!\"", 0, 17
        +tmsPrint ">RUN", 0, 18
        +tmsPrint "HELLO WORLD!", 1, 19
        +tmsPrint "** DONE **", 1, 21
        +tmsPrint ">", 0, 23
        +tmsPrint 127, 1, 23

loop:
        clc
        adc #1

        jsr medDelay

        +tmsPrint ' ', 1, 23

        jsr medDelay

        +tmsPrint 127, 1, 23

        jmp loop

fillRam:
        ; font table
        lda #<$4000
        sta TMS9918_REG
        lda #>$4000
        sta TMS9918_REG

        lda #$00

	ldx #255
	ldy #64
-
	dex
        tya
        
        sta TMS9918_RAM
	bne -
	ldx #255
	dey
	bne -
	rts


medDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay


delay:
	ldx #255
	ldy #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts
