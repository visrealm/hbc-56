; Troy's HBC-56 - TMS9918 Graphics II mode test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

YPOS = $48

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

hbc56Meta:
        +setHbcMetaTitle "TMS GFXII MODE"
        rts

hbc56Main:
        sei

        jsr tmsModeGraphicsII

        +tmsDisableInterrupts
        +tmsDisableOutput


        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground


        jsr setupNameTable
        jsr setupColorTable
        jsr setupPatternTable

        +tmsEnableOutput

        cli

loop:
        jsr doFrame
        +hbc56CustomDelay 64
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

.palette
!byte $80,$90,$a0,$20,$30,$70,$50,$40,$d0,$40,$50,$70,$30,$20,$a0,$90

TMS_NAME_DATA:

!for third, 0, 2 {
        !for i, 0, 255 {
                !byte i
        }
}

TMS_COLOR_DATA:

!for .c, 0, 11 {
        !for .r, 0, 511 {
                !byte (.c + 2) << 4
        }
}


testImg:
!bin "mode2test.bin"
;!bin "metallica.bin"
