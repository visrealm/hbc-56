

; Troy's HBC-56 - Breakout
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

; -----------------------------------------------------------------------------
; HBC-56 Program Metadata
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "Q*BERT-56"
        +setHbcMetaNES
        rts

; -----------------------------------------------------------------------------
; HBC-56 Program Entry
; -----------------------------------------------------------------------------
hbc56Main:
        sei

        ; go to graphics II mode
        jsr tmsModeGraphicsII

        ; disable display durint init
        +tmsDisableInterrupts
        +tmsDisableOutput

        lda #TMS_R1_SPRITE_MAG2
        jsr tmsReg1ClearFields
        lda #TMS_R1_SPRITE_16
        jsr tmsReg1SetFields

        ; set backrground
        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground


        jsr clearVram
        jsr tilesToVram

        +tmsSetPosWrite 0, 2
        +tmsSendData .gameTable, 32*22


        +tmsSetPosWrite 0, 0
        +tmsPut 1
        +tmsPut 3
        +tmsPut 0
        +tmsPut 1
        +tmsPut 3
        +tmsSetPosWrite 0, 1
        +tmsPut 2
        +tmsPut 4
        +tmsPut 0
        +tmsPut 2
        +tmsPut 4

        +tmsEnableOutput

        +hbc56SetVsyncCallback gameLoop
        +tmsEnableInterrupts

        cli

        jmp hbc56Stop

gameLoop:
        lda HBC56_TICKS
        and #$0f
        lsr
        lsr

        cmp #1
        bcs +
        jmp updateColor1
+
        cmp #2
        bcs +
        jmp updateColor2
+
        cmp #3
        bcs +
        jmp updateColor3
+
        jmp updateColor4

        rts

updateColor1:
        +tmsSetAddrColorTableIIBank0 1
        +tmsSendData .color1, 8 * 4

        ;+tmsSetAddrColorTableIIBank1 1
        ;+tmsSendData .color1, 8 * 4

        ;+tmsSetAddrColorTableIIBank2 1
        ;+tmsSendData .color1, 8 * 4
        rts

updateColor2:
        +tmsSetAddrColorTableIIBank0 1
        +tmsSendData .color2, 8 * 4

        ;+tmsSetAddrColorTableIIBank1 1
        ;+tmsSendData .color2, 8 * 4

        ;+tmsSetAddrColorTableIIBank2 1
        ;+tmsSendData .color2, 8 * 4
        rts

updateColor3:
        +tmsSetAddrColorTableIIBank0 1
        +tmsSendData .color3, 8 * 4

        ;+tmsSetAddrColorTableIIBank1 1
        ;+tmsSendData .color3, 8 * 4

        ;+tmsSetAddrColorTableIIBank2 1
        ;+tmsSendData .color3, 8 * 4
        rts

updateColor4:
        +tmsSetAddrColorTableIIBank0 1
        +tmsSendData .color4, 8 * 4

        ;+tmsSetAddrColorTableIIBank1 1
        ;+tmsSendData .color4, 8 * 4

        ;+tmsSetAddrColorTableIIBank2 1
        ;+tmsSendData .color4, 8 * 4
        rts

; -----------------------------------------------------------------------------
; Clear/reset VRAM
; -----------------------------------------------------------------------------
clearVram:
        ; clear the name table
        +tmsSetAddrNameTable
        lda #0
        jsr _tmsSendPage        
        jsr _tmsSendPage
        jsr _tmsSendPage

        ; set all color table entries to transparent
        +tmsSetAddrColorTable
        +tmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
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
        rts

tilesToVram:

        ; brick patterns (for each bank)
        +tmsSetAddrPattTableIIBank0 1
        +tmsSendData .pattern, 8 * 4

        +tmsSetAddrPattTableIIBank1 1
        +tmsSendData .pattern, 8 * 4

        +tmsSetAddrPattTableIIBank2 1
        +tmsSendData .pattern, 8 * 4

        +tmsSetAddrPattTableIIBank0 128
        jsr .buildTopBlocks
        +tmsSetAddrPattTableIIBank0 160
        jsr .buildBottomBlocks

        +tmsSetAddrColorTableIIBank0 128
        jsr .buildTopBlocksColor
        +tmsSetAddrColorTableIIBank0 160
        jsr .buildBottomBlocksColor

        +tmsSetAddrPattTableIIBank0 254
        +tmsSendData .clearPatt, 8 * 2
        +tmsSetAddrColorTableIIBank0 254
        +tmsPutRpt $fe, 8 * 2

        +tmsSetAddrPattTableIIBank1 128
        jsr .buildTopBlocks
        +tmsSetAddrPattTableIIBank1 160
        jsr .buildBottomBlocks

        +tmsSetAddrColorTableIIBank1 128
        jsr .buildTopBlocksColor
        +tmsSetAddrColorTableIIBank1 160
        jsr .buildBottomBlocksColor

        +tmsSetAddrPattTableIIBank1 254
        +tmsSendData .clearPatt, 8 * 2
        +tmsSetAddrColorTableIIBank1 254
        +tmsPutRpt $fe, 8 * 2

        +tmsSetAddrPattTableIIBank2 128
        jsr .buildTopBlocks
        +tmsSetAddrPattTableIIBank2 160
        jsr .buildBottomBlocks

        +tmsSetAddrColorTableIIBank2 128
        jsr .buildTopBlocksColor
        +tmsSetAddrColorTableIIBank2 160
        jsr .buildBottomBlocksColor

        +tmsSetAddrPattTableIIBank2 254
        +tmsSendData .clearPatt, 8 * 2
        +tmsSetAddrColorTableIIBank2 254
        +tmsPutRpt $fe, 8 * 2



        ; brick colors (for each bank)
        +tmsSetAddrColorTableIIBank0 1
        +tmsSendData .color2, 8 * 4

        +tmsSetAddrColorTableIIBank1 1
        +tmsSendData .color2, 8 * 4

        +tmsSetAddrColorTableIIBank2 1
        +tmsSendData .color2, 8 * 4

        +tmsSetAddrSpritePattTable
        +tmsSendData .bertPattR, 8 * 4 * 3

        +tmsCreateSprite 0, 0, 122, 7, TMS_LT_RED
        +tmsCreateSprite 1, 4, 122, 10, TMS_BLACK
        +tmsCreateSprite 2, 8, 122, -6, TMS_WHITE

        rts        

.buildTopBlocks:
        +tmsSendData .blockPatt, 8 * 4
        +tmsSendData .blockPatt, 8 * 4
        +tmsSendData .blockPatt, 8 * 4
        +tmsSendData .blockPatt, 8 * 4
        +tmsSendData .blockPatt, 8 * 4
        +tmsSendData .blockPatt, 8 * 4
        +tmsSendData .blockPatt, 8 * 4
        +tmsSendData .blockPatt, 8 * 4
        rts

.buildBottomBlocks:
        +tmsSendData .blockPatt2, 8 * 4
        +tmsSendData .blockPatt2, 8 * 4
        +tmsSendData .blockPatt2, 8 * 4
        +tmsSendData .blockPatt2, 8 * 4
        +tmsSendData .blockPatt2, 8 * 4
        +tmsSendData .blockPatt2, 8 * 4
        +tmsSendData .blockPatt2, 8 * 4
        +tmsSendData .blockPatt2, 8 * 4
        rts

.buildTopBlocksColor:
        +tmsPutRpt $50, 8 * 4
        +tmsPutRpt $5e, 8 * 2
        +tmsPutRpt $5f, 8 * 2
        +tmsPutRpt $b0, 8 * 4
        +tmsPutRpt $be, 8 * 2
        +tmsPutRpt $bf, 8 * 2
        +tmsPutRpt $20, 8 * 4
        +tmsPutRpt $2e, 8 * 2
        +tmsPutRpt $2f, 8 * 2
        +tmsPutRpt $80, 8 * 4
        +tmsPutRpt $8e, 8 * 2
        +tmsPutRpt $8f, 8 * 2
        rts

.buildBottomBlocksColor:
        +tmsPutRpt $f0, 8 * 2
        +tmsPutRpt $e0, 8 * 2
        +tmsPutRpt $5f, 8 * 2
        +tmsPutRpt $5e, 8 * 2
        +tmsPutRpt $f0, 8 * 2
        +tmsPutRpt $e0, 8 * 2
        +tmsPutRpt $bf, 8 * 2
        +tmsPutRpt $be, 8 * 2
        +tmsPutRpt $f0, 8 * 2
        +tmsPutRpt $e0, 8 * 2
        +tmsPutRpt $2f, 8 * 2
        +tmsPutRpt $2e, 8 * 2
        +tmsPutRpt $f0, 8 * 2
        +tmsPutRpt $e0, 8 * 2
        +tmsPutRpt $8f, 8 * 2
        +tmsPutRpt $8e, 8 * 2
        rts


.pattern:
!byte $07,$3F,$80,$00,$07,$3F,$FE,$3F
!byte $07,$C0,$F8,$00,$00,$00,$00,$00
!byte $E0,$FC,$FE,$7F,$F8,$C0,$01,$03
!byte $1F,$FC,$E0,$00,$00,$00,$00,$00

.blockPatt:
!byte $00,$00,$00,$00,$01,$07,$1F,$7F   
!byte $01,$07,$1F,$7F,$FF,$FF,$FF,$FF   
!byte $80,$E0,$F8,$FE,$FF,$FF,$FF,$FF
!byte $00,$00,$00,$00,$80,$E0,$F8,$FE
.blockPatt2:
!byte $7F,$1F,$07,$01,$00,$00,$00,$00   
!byte $FF,$FF,$FF,$FF,$7F,$1F,$07,$01   
!byte $FF,$FF,$FF,$FF,$FE,$F8,$E0,$80
!byte $FE,$F8,$E0,$80,$00,$00,$00,$00

.clearPatt:
!byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
!byte $00,$00,$00,$00,$00,$00,$00,$00

.bertPattR:
!byte $0F,$3F,$79,$79,$F9,$FF,$FF,$FF   ; red
!byte $7F,$3F,$1F,$11,$11,$11,$39,$1E
!byte $00,$C0,$00,$00,$20,$F8,$FC,$FE
!byte $B2,$12,$0C,$00,$00,$00,$C0,$70

!byte $06,$06,$00,$00,$00,$00,$00,$00   ; black offset y+3
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $C0,$C0,$00,$00,$00,$0C,$0C,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00

!byte $00,$00,$00,$00,$00,$00,$00,$00   ; white offset y-13
!byte $00,$00,$00,$00,$00,$00,$00,$06
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$C0


.gameTable
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$81,$82,$83,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$88,$89,$8a,$8b,$00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$ac,$ad,$ae,$af,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$a8,$a9,$aa,$ab,$00,$00,$00,$00,$00,$00,$80,$81,$86,$87,$84,$85,$82,$83,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$81,$86,$87,$84,$85,$86,$87,$84,$85,$82,$83,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$80,$81,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$82,$83,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$80,$81,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$82,$83,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$80,$81,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$82,$83,$00,$00,$00,$00
!byte $00,$00,$00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$00,$00,$00
!byte $00,$00,$00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00,$00,$00
!byte $00,$00,$80,$81,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$82,$83,$00,$00
!byte $00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$00
!byte $00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00
!byte $00,$00,$a8,$a9,$aa,$ab,$a8,$a9,$aa,$ab,$a8,$a9,$aa,$ab,$a8,$a9,$aa,$ab,$a8,$a9,$aa,$ab,$a8,$a9,$aa,$ab,$a8,$a9,$aa,$ab,$00,$00


;TMS_TRANSPARENT         = $00
;TMS_BLACK               = $01
;TMS_MED_GREEN           = $02
;TMS_LT_GREEN            = $03
;TMS_DK_BLUE             = $04
;TMS_LT_BLUE             = $05
;TMS_DK_RED              = $06
;TMS_CYAN                = $07
;TMS_MED_RED             = $08
;TMS_LT_RED              = $09
;TMS_DK_YELLOW           = $0a
;TMS_LT_YELLOW           = $0b
;TMS_DK_GREEN            = $0c
;TMS_MAGENTA             = $0d
;TMS_GREY                = $0e
;TMS_WHITE               = $0f

!macro colorTable c1, c2, c3, c4 {
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, c2
+byteTmsColorFgBg TMS_TRANSPARENT, c2
+byteTmsColorFgBg c3, c2
+byteTmsColorFgBg c3, c2
+byteTmsColorFgBg c3, c4
+byteTmsColorFgBg c3, TMS_CYAN
+byteTmsColorFgBg c3, TMS_CYAN
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_CYAN
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_CYAN
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT

+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg c1, c2
+byteTmsColorFgBg c1, c4
+byteTmsColorFgBg c1, c4
+byteTmsColorFgBg TMS_CYAN, c4
+byteTmsColorFgBg TMS_CYAN, c4
+byteTmsColorFgBg TMS_CYAN, c3
+byteTmsColorFgBg TMS_CYAN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_CYAN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
}

.color1:
+colorTable TMS_MED_RED, TMS_MED_GREEN, TMS_LT_YELLOW, TMS_LT_BLUE
.color2:
+colorTable TMS_MED_GREEN, TMS_LT_YELLOW, TMS_LT_BLUE, TMS_MED_RED
.color3:
+colorTable TMS_LT_YELLOW, TMS_LT_BLUE, TMS_MED_RED, TMS_MED_GREEN
.color4:
+colorTable TMS_LT_BLUE, TMS_MED_RED, TMS_MED_GREEN, TMS_LT_YELLOW

