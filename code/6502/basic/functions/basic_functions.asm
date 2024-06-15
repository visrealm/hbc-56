; Troy's HBC-56 - Custom BASIC functions
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

; CALL COLOR,$ab 

basicColor:
        jsr LAB_GTBY
        txa
        sta BASIC_COLOR
        
        php
        sei
        jsr tmsSetBackground
        lda BASIC_COLOR
        jsr tmsInitEntireColorTable
        plp
        rts

modeTable:
!word tmsModeText,tmsModeGraphicsI,tmsModeBitmap

doMode:
        jmp (modeTable, x)

basicDisplay:
        php
        sei
        jsr LAB_GTBY
        txa
        cmp #3
        bcs basicErrorHandler
        sta BASIC_MODE
        asl
        tax
        jsr doMode
        +tmsEnableOutput

        +consoleDisableCursor

        lda BASIC_COLOR
        jsr tmsInitEntireColorTable
        plp
        rts
        
basicErrorHandler:
        plp
        jmp LAB_FCER

basicCls:
        lda BASIC_MODE
        cmp #2
        bne +
        php
        sei
        +tmsSetAddrPattTable
        lda #0
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb

        +tmsSetAddrColorTable
        lda BASIC_COLOR
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        plp
        rts
+
        jmp tmsConsoleCls

basicPlot:
        jsr LAB_GADB
        stx BASIC_YPOS
        ldx Itempl
        stx BASIC_XPOS
        ldy BASIC_YPOS

        php
        sei

        jsr tmsSetPatternTmpAddressII
        jsr tmsSetAddressRead
        
        lda BASIC_XPOS
        and #07
        tax
        +tmsGet

        ora tableBitFromLeft, x
        pha
        jsr tmsSetAddressWrite
        pla
        +tmsPut

        ldx BASIC_XPOS
        ldy BASIC_YPOS

        jsr tmsSetColorTmpAddressII
        jsr tmsSetAddressWrite
        lda BASIC_COLOR
        +tmsPut

        plp

        rts

basicUnPlot:
        jsr LAB_GADB
        stx BASIC_YPOS
        ldx Itempl
        stx BASIC_XPOS
        ldy BASIC_YPOS

        php
        sei

        jsr tmsSetPatternTmpAddressII
        jsr tmsSetAddressRead
        
        lda BASIC_XPOS
        and #07
        tax
        +tmsGet

        and tableInvBitFromLeft, x
        pha
        jsr tmsSetAddressWrite
        pla
        +tmsPut

        plp

        rts


!src "functions/jump_table.asm"