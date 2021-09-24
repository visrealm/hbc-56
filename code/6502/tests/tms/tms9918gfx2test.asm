!to "tms9918gfx2test.o", plain

HBC56_INT_VECTOR = onVSync

!source "../../lib/hbc56.asm"

!source "../../lib/gfx/tms9918.asm"


XPOS = $44
YPOS = $45

TICKS   = $46
TICKS_L = TICKS
TICKS_H = TICKS + 1

CONFIG_STEP = $48

setupNameTable:
        +tmsSetAddrNameTable
        +tmsSendData TMS_NAME_DATA, $300
        rts

setupColorTable:
        +tmsSetAddrColorTable
        +tmsSendData TMS_COLOR_DATA, $1800
        rts

setupPatternTable:
        +tmsSetAddrPattTable
        +tmsSendData testImg, $1800
        rts

onVSync:
        pha
        lda CONFIG_STEP
        beq doneConfig
        cmp #3
        bne doneNameTable
        jsr setupNameTable
        dec CONFIG_STEP
        jmp endInt

doneNameTable:
        cmp #2
        bne doneColorTable
        jsr setupColorTable
        dec CONFIG_STEP
        jmp endInt

doneColorTable:
        jsr setupPatternTable
        dec CONFIG_STEP
        +tmsEnableOutput

doneConfig
        jsr doFrame

endInt
        +tmsReadStatus
        pla      
        rti



main:
        sei
        lda #0
        sta TICKS_L
        sta TICKS_H
        sta YPOS
        
        lda #3
        sta CONFIG_STEP

        jsr tmsInit

        +tmsDisableInterrupts
        +tmsDisableOutput

        +tmSetGraphicsMode2

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        +tmsEnableInterrupts

        cli

loop:
        jmp loop

doFrame:
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
        +tmsPut 
        dex
        bne nextCol
        dey
        bne nextRow

        pla
	rts


medDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay


delay:
	ldx #0
	ldy #0
-
	dex
	bne -
	ldx #0
	dey
	bne -
	rts

customDelay:
	ldx #0
-
	dex
	bne -
	ldx #0
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
!bin "metallica.bin"
