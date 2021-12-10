!src "hbc56kernel.inc"

XPOS = $44
YPOS = $45


hbc56Meta:
        +setHbcMetaTitle "TMS9918 NES TEST"
        +setHbcMetaNES
        rts

BUFFER_ADDR = $1000

sprite1:
!byte %00001000
!byte %00000100
!byte %00001111
!byte %00011011
!byte %00111111
!byte %00101111
!byte %00101000
!byte %00000110

sprite2:
!byte %00100000
!byte %01000000
!byte %11100000
!byte %10110000
!byte %11111000
!byte %11101000
!byte %00101000
!byte %11000000

XPOS = $44
YPOS = $45
XPOS1 = $46
YPOS1 = $47

hbc56Main:
	lda #0

        sei

        jsr tmsModeGraphicsI

        jsr tmsInitTextTable ; clear the name table

        +tmsEnableOutput
        +tmsEnableInterrupts

        +tmsPrint "TROY'S HBC-56 BASIC READY", 1, 15
        +tmsPrint ">10 PRINT \"HELLO WORLD!\"", 0, 17
        +tmsPrint ">RUN", 0, 18
        +tmsPrint "HELLO WORLD!", 1, 19
        +tmsPrint "** DONE **", 1, 21
        +tmsPrint ">", 0, 23
        +tmsPrint 127, 1, 23

        lda #40
        sta XPOS
        sta YPOS

        lda #80
        sta XPOS1
        sta YPOS1

        +tmsCreateSpritePattern 0, sprite1
        +tmsCreateSpritePattern 1, sprite2

        +tmsCreateSprite 0, 0, 40, 40, TMS_MAGENTA
        +tmsCreateSprite 1, 1, 56, 40, TMS_MAGENTA
        +tmsCreateSprite 2, 0, 80, 80, TMS_MED_RED
        +tmsCreateSprite 3, 1, 96, 80, TMS_MED_RED

        cli


loop:
        jsr outputSeconds

        ldx XPOS
        ldy YPOS
        +tmsSpritePosXYReg 0
        txa
        clc
        adc #16
        tax
        +tmsSpritePosXYReg 1

        ldx XPOS1
        ldy YPOS1
        +tmsSpritePosXYReg 2
        txa
        clc
        adc #16
        tax
        +tmsSpritePosXYReg 3

        ldy #8
        jsr customDelay        

        jmp loop

COLOR = $89
IMG = $8a
LAST_SECONDS_L = $8b

outputSeconds:
        sei

        +tmsSetPosWrite 8, 1
        +nesBranchIfNotPressed NES_LEFT, +
        +tmsPut 'L'
        dec XPOS
+
        +nesBranchIfNotPressed NES_RIGHT, +
        +tmsPut 'R'
        inc XPOS
+
        +nesBranchIfNotPressed NES_UP, +
        +tmsPut 'U'
        dec YPOS
+
        +nesBranchIfNotPressed NES_DOWN, +
        +tmsPut 'D'
        inc YPOS
+
        +nesBranchIfNotPressed NES_SELECT, +
        +tmsPut 'S'
        +tmsPut 'e'
        dec YPOS1
+
        +nesBranchIfNotPressed NES_START, +
        +tmsPut 'S'
        +tmsPut 't'
        inc YPOS1
+
        +nesBranchIfNotPressed NES_B, +
        +tmsPut 'B'
        dec XPOS1
+
        +nesBranchIfNotPressed NES_A, +
        +tmsPut 'A'
        inc XPOS1
+
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '

        ; flashing cursor
        lda #(TMS_FPS / 2)
        cmp HBC56_TICKS
        bcc +
        +tmsPrint ' ', 1, 23
        jmp ++
+
        +tmsPrint 127, 1, 23
++

        lda HBC56_SECONDS_L
        cmp LAST_SECONDS_L
        beq .endOutput
        sta LAST_SECONDS_L

        ; output seconds (as hex)
        +tmsSetPosWrite 1, 1
        lda HBC56_SECONDS_L
        jsr tmsHex8  ; calls cli
        sei

.endOutput
        cli
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

customDelay:
	ldx #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts
