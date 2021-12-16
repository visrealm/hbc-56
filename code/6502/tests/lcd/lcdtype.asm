; Troy's HBC-56 - LCD Type - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

TMP_CHAR        = HBC56_USER_ZP_START 

; -----------------------------------------------------------------------------
; metadata for the HBC-56 kernel
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "LCD CONSOLE MODE"
        +consoleLCDMode
        rts


hbc56Main:
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
        jsr lcdBackspace
        jmp .endLoop
++
        sei
        lda TMP_CHAR
        jsr lcdCharScroll
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
