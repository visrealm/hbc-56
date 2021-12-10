; 6502 LCD Type - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56


!src "kernel.inc"

LCD_MODEL = 12864

LCD_BUFFER_ADDR = $7d00

!src "lcd/lcd.asm"

TMP_CHAR = R0

main:
        sei
        jsr kbInit
        jsr lcdInit
        jsr lcdDisplayOn
        jsr lcdCursorBlinkOn

loop:
        jsr kbReadAscii
        bcc .endLoop
        sta TMP_CHAR
        cmp #$0d ; enter
        bne +
        jsr lcdNextLine
        jmp .endLoop    
+
        cmp #$08 ; backspace
        bne ++
        ; TBD
        jmp .endLoop
++
        sei
        lda TMP_CHAR
        jsr lcdChar
        cli

.endLoop
        jmp loop
        ;rts

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

customDelay:
	ldx #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts
