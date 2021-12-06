HBC56_SKIP_POST = 1

HBC_56_BUILD = 1

HBC56_INT_VECTOR = onVSync
!src "hbc56.asm"
!src "ut/memory.asm"
!src "ut/util.asm"

!src "ut/math_macros.asm"
!src "gfx/tms9918.lmap"
!src "gfx/tms9918macros.asm"

!source "inp/keyboard.asm"

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

        jsr kbInit

        jsr tmsInit

        lda #TMS_R0_MODE_TEXT
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_TEXT
        jsr tmsReg1SetFields

        +tmsColorFgBg TMS_MED_RED, TMS_BLACK
        jsr tmsSetBackground

        +tmsSetAddrNameTable
        lda #' '
        jsr _tmsSendPage
        jsr _tmsSendPage
        jsr _tmsSendPage
        ;jsr _tmsSendPage
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
        lda #39
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
        cmp #40
        bne +
        lda #0
        sta XPOS
        inc YPOS
+

        jmp loop


setPosition:
        ldx XPOS
        ldy YPOS
        jsr tmsSetPosWriteText
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

*=$F800
!bin "../../lib/gfx/tms9918.bin"
