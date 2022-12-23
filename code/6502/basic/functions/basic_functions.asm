; Troy's HBC-56 - Custom BASIC functions
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

; CALL COLOR,$ab 

basicColor:
        jsr  LAB_SCGB
        txa
        jmp tmsInitColorTable

basicCls:
        jsr tmsInitTextTable
        jmp tmsConsoleHome

modeTable:
!word tmsModeText,tmsModeGraphicsI,tmsModeII

tmsModeII:
        php
        sei
                ; clear the name table
        +tmsSetAddrNameTable
        ldy #3
        lda #0
-
        +tmsPut
        inc
        bne -
        dey
        bne -

        ; set all color table entries to transparent
        +tmsSetAddrColorTable
        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb        

        ; clear the pattern table
        +tmsSetAddrPattTable
        lda #0
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb

        plp
        jmp tmsModeGraphicsII


basicMode:
        php
        sei

        jsr basicCls
        jsr  LAB_SCGB
        txa
        cmp #03
        bcs basicErrorHandler
        asl
        tax
        plp
        jmp (modeTable,x)

basicMode2:
        php
        sei

        txa
        cmp #03
        bcs basicErrorHandler
        asl
        tax
        plp
        jmp (modeTable,x)


basicErrorHandler:
        plp
        JMP  LAB_FCER

doPlot:
        stx BASIC_XPOS
        php
        sei
        jsr tmsSetPatternTmpAddressII
        jsr tmsSetAddressRead
        lda BASIC_XPOS
        and #$07
        tax
        +tmsGet
        ora tableBitFromLeft, x
        pha
        jsr tmsSetAddressWrite
        pla
        +tmsPut
        plp
        rts

basicSetPixel
        jsr  LAB_SCGB
        stx BASIC_XPOS
        jsr  LAB_SCGB
        stx BASIC_YPOS

        ldx BASIC_XPOS
        ldy BASIC_YPOS

        bra doPlot

basicClearPixel
        pha
        phx
        phy
        php
        sei

        jsr  LAB_SCGB
        stx BASIC_XPOS
        jsr  LAB_SCGB
        stx BASIC_YPOS

        ldx BASIC_XPOS
        ldy BASIC_YPOS
        jsr tmsSetPatternTmpAddressII
        jsr tmsSetAddressRead
        lda BASIC_XPOS
        and #$07
        tax
        +tmsGet
        and tableInvBitFromLeft, x
        pha
        jsr tmsSetAddressWrite
        pla
        +tmsPut
        plp
        ply
        plx
        pla

        rts


*=$c000

PAL: ; $c000
        jmp basicColor   
CLS: ; $c003
        jmp basicCls
MODE: ; $c006
        jmp basicMode
SETPIXEL: ; $c009
        jmp basicSetPixel
CLEARPIXEL: ; $c00c
        jmp basicClearPixel
