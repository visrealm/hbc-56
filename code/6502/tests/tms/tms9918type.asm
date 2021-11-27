!to "tms9918type.o", plain
!sl "tms9918type.lmap"

HBC56_SKIP_POST = 1

HBC56_INT_VECTOR = onVSync
!src "../../lib/hbc56.asm"
!src "../../lib/ut/memory.asm"
!src "../../lib/ut/util.asm"
TMS_MODEL = 9918
!src "../../lib/ut/math_macros.asm"
!src "../../lib/gfx/tms9918.asm"


!source "../../lib/inp/keyboard.asm"


XPOS = $44
YPOS = $45

TICKS_L = $46
TICKS_H = $47


onVSync:
        pha
        lda TICKS_L
        clc
        adc #1
        cmp #60
        bne +
        lda #0
        inc TICKS_H
+  
        sta TICKS_L
        +tmsReadStatus
        pla      
        rti


main:
        sei
        lda #0
        sta TICKS_L
        sta TICKS_H
        sta XPOS
        sta YPOS

        jsr tmsInit

        lda #TMS_R0_MODE_GRAPHICS_I
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_GRAPHICS_I
        jsr tmsReg1SetFields

        +tmsColorFgBg TMS_BLACK, TMS_CYAN

        +tmsSetAddrNameTable
        +tmsSendData TEXT, 32*24
        +tmsSetAddrNameTable

        cli

loop:
        jsr kbReadAscii
        cmp #$ff
        beq loop
        cmp #$0d ; enter
        bne +
        lda #0
        sta XPOS
        inc YPOS
        jsr setPosition
        jmp loop        
+
        cmp #$08 ; backspace
        bne ++
        dec XPOS
        bpl +
        lda #31
        sta XPOS
        dec YPOS
+
        jsr setPosition
        lda #' '
        +tmsPut
        jsr setPosition
        jmp loop
++
        +tmsPut
        inc XPOS
        lda XPOS
        cmp #32
        bne +
        lda #0
        sta XPOS
        inc YPOS
+

        jmp loop

setPosition:
        ldx XPOS
        ldy YPOS
        jsr tmsSetPosWrite
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

TMS_FONT_DATA:
!src "../../lib/gfx/fonts/tms9918font2subset.asm"

TEXT:
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "https://github.com/visrealm/vrEmuTms9918"
