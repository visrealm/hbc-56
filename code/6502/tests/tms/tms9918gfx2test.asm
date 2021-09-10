!to "tms9918gfx2test.o", plain

HBC56_INT_VECTOR = onVSync

!source "../../lib/hbc56.asm"

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

        +tmsDisableOutput

        +tmSetGraphicsMode2

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        +tmsSetAddrNameTable
        +tmsSendData TMS_NAME_DATA, $300

        +tmsSetAddrColorTable
        +tmsSendData TMS_COLOR_DATA, $1800

        +tmsSetAddrPattTable
        +tmsSendData testImg, $1800

        +tmsEnableOutput

        cli

loop:
        +tmsSetAddrColorTable

        lda YPOS
        clc
        adc #1
        sta YPOS
        pha

        ldy #24
nextRow
        pla
        clc
        adc #1
        and #$0f
        pha
        tax
        lda .palette, x
        ldx #0

nextCol
        sta TMS9918_RAM
        +tmsWait
        dex
        bne nextCol
        dey
        bne nextRow

        pla

        jsr delay

        jmp loop

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

.palette
!byte $80,$90,$a0,$20,$30,$70,$50,$40,$d0,$40,$50,$70,$30,$20,$a0,$90

TMS_NAME_DATA:

!for third, 0, 2 {
        !for i, 0, 255 {
                !byte i
        }
}

TMS_FONT_DATA:
TMS_COLOR_DATA:

!for c, 0, 11 {
        !for r, 0, 511 {
                !byte (c + 2) << 4
        }
}


testImg:
!bin "mode2test.bin"
