; Troy's HBC-56 - TMS9918 Console mode test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

hbc56Meta:
        +setHbcMetaTitle "CONSOLE TEST"
        rts

hbc56Main:
        sei
        jsr kbInit

        jsr tmsModeText

        +tmsSetAddrNameTable
        lda #' '
        ldx #(40 * 25 / 8)
        jsr _tmsSendX8

        +tmsSetColorFgBg TMS_LT_GREEN, TMS_BLACK
        +tmsEnableOutput
        cli

        +tmsEnableInterrupts

        +consoleEnableCursor

loop:
        jsr kbReadAscii
        bcc .endLoop
        cmp #$0d ; enter
        bne +
        sei
        +tmsConsoleOut ' '
        lda #39
        sta TMS9918_CONSOLE_X
        jsr tmsIncPosConsole
        cli
        jmp .endLoop    
+
        cmp #$08 ; backspace
        bne ++
        sei
        +tmsConsoleOut ' '
        jsr tmsDecPosConsole
        jsr tmsDecPosConsole
        +tmsConsoleOut ' '
        jsr tmsDecPosConsole
        cli
        jmp .endLoop
++
        sei
        pha
        jsr tmsSetPosConsole
        pla
        +tmsPut
        jsr tmsIncPosConsole
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
