!to "tms9918mctest.o", plain

HBC56_INT_VECTOR = onVSync

!source "../../lib/hbc56.asm"
!source "../../lib/gfx/fonts/tms9918font2subset.asm"
!source "../../lib/gfx/tms9918.asm"


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
        sta YPOS

        jsr tmsInit

        lda #TMS_R0_MODE_MULTICOLOR
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_MULTICOLOR
        jsr tmsReg1SetFields

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        +tmsSetAddrNameTable
        +tmsSendData TMS_NAME_DATA, $300

        cli

loop:
        +tmsSetAddrPattTable
        +tmsSendData TMS_BIRD_DATA, $800

        jsr medDelay
        jsr medDelay
        jsr medDelay
        jsr medDelay

        +tmsSetAddrPattTable
        +tmsSendData TMS_PATTERN_DATA, $800

        jsr medDelay
        jsr medDelay
        jsr medDelay
        jsr medDelay

        jmp loop

medDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay


delay:
	ldy #0
customDelay:
	ldx #0
-
	dex
	bne -
	ldx #0
	dey
	bne -
	rts



TMS_NAME_DATA:

!for y, 0, 23 {
!for x, 0, 31 {
        !byte x + ((y & $fc) << 3)
}
}

TMS_BIRD_DATA:
!bin "bird.bin"

TMS_PATTERN_DATA:
!bin "mcmode.bin"
