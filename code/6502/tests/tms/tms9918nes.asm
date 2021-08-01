!to "tms9918nes.o", plain

HBC56_INT_VECTOR = onVSync

!source "hbc56.asm"

TMS_MODEL = 9929
!source "gfx/tms9918.asm"
!source "gfx/fonts/tms9918font1.asm"

!source "gfx/bitmap.asm"
!source "inp/nes.asm"

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

TICKS_L = $48
TICKS_H = $49


onVSync:
        pha
        lda TICKS_L
        clc
        adc #1
        cmp #TMS_FPS
        bne +
        lda #0
        inc TICKS_H
+  
        sta TICKS_L
        +tmsReadStatus
        pla      
        rti


main:

	lda #0
	sta PIX_ADDR_L

        sei
        lda #0
        sta TICKS_L
        sta TICKS_H

        jsr tmsInit

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
LAST_TICKS_H = $8b

outputSeconds:
        sei

        +tmsSetPos 8, 1
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
        cmp TICKS_L
        bcc +
        +tmsPrint ' ', 1, 23
        jmp ++
+
        +tmsPrint 127, 1, 23
++

        lda TICKS_H
        cmp LAST_TICKS_H
        beq .endOutput
        sta LAST_TICKS_H

        ; output seconds (as hex)
        +tmsSetPos 1, 1
        lda TICKS_H
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
