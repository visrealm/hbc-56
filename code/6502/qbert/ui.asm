; Troy's HBC-56 - Q*Bert
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


LIFE_PATTERN_INDEX = 5

SCORE_POS_X = 1
SCORE_POS_Y = 1

CHANGE_TO_COLOR = TMS_MED_RED
CHANGE_TO_PATTERN_INDEX = 192
CHANGE_TO_PATTERN_COUNT = 6

CHANGE_TO_ARROWS_PATTERN_INDEX = CHANGE_TO_PATTERN_INDEX + CHANGE_TO_PATTERN_COUNT
CHANGE_TO_ARROWS_COLOR = TMS_MAGENTA
CHANGE_TO_ARROWS_PATTERN_COUNT = 2

CHANGE_TO_POS_X = 1
CHANGE_TO_POS_Y = 3
CHANGE_TO_ARROWS_POS_X = 1
CHANGE_TO_ARROWS_POS_Y = 5

LIVES_NAMETABLE_POS_X       = 0
LIVES_NAMETABLE_POS_Y       = 6
LIVES_MAX_VISIBLE = 5


uiInit:
        ; platform patterns (for each bank)
        +tmsSetAddrPattTableIIBank0 LIFE_PATTERN_INDEX
        jsr .bertInitSendPatterns

       +tmsSetAddrPattTableIIBank1 LIFE_PATTERN_INDEX
       jsr .bertInitSendPatterns

       +tmsSetAddrPattTableIIBank2 LIFE_PATTERN_INDEX
       jsr .bertInitSendPatterns

        ; platform colors (for each bank)
        +tmsSetAddrColorTableIIBank0 LIFE_PATTERN_INDEX
        jsr .bertInitSendColors

       +tmsSetAddrColorTableIIBank1 LIFE_PATTERN_INDEX
       jsr .bertInitSendColors

       +tmsSetAddrColorTableIIBank2 LIFE_PATTERN_INDEX
       jsr .bertInitSendColors

        +tmsSetAddrPattTableIIBank2 CHANGE_TO_PATTERN_INDEX
        +tmsSendData .levelCirclePatt, 8 * 12

        +tmsSetAddrColorTableIIBank2 CHANGE_TO_PATTERN_INDEX
        +tmsColorFgBg TMS_MED_GREEN, TMS_TRANSPARENT
        +tmsPutAccRpt 8 * 12

        +tmsSetAddrSpritePattTable 256 - 12
        +tmsSendData .levelOne, 8 * 4

        rts

uiStartGame:
        jsr uiRenderLives

        +tmsSetAddrColorTableIIBank0 '0'
        +tmsSendDataRpt .digitsPal, 8, 10

        ; "change to" text and arrows
        +tmsSetAddrPattTableIIBank0 CHANGE_TO_PATTERN_INDEX
        +tmsSendData .changeToPatt, 8 * CHANGE_TO_PATTERN_COUNT
        +tmsSendData .changeToArrowsPatt, 8 * CHANGE_TO_ARROWS_PATTERN_COUNT

        +tmsSetAddrColorTableIIBank0 CHANGE_TO_PATTERN_INDEX
        +tmsPutRpt (CHANGE_TO_COLOR << 4), 8 * CHANGE_TO_PATTERN_COUNT
        +tmsPutRpt (CHANGE_TO_ARROWS_COLOR << 4), 8 * CHANGE_TO_ARROWS_PATTERN_COUNT

        +tmsSetPosWrite CHANGE_TO_POS_X, CHANGE_TO_POS_Y
        +tmsPutSeq CHANGE_TO_PATTERN_INDEX, 6

        +tmsSetPosWrite CHANGE_TO_ARROWS_POS_X, CHANGE_TO_ARROWS_POS_Y
        lda #CHANGE_TO_ARROWS_PATTERN_INDEX
        +tmsPut
        +tmsPut

        +tmsSetPosWrite CHANGE_TO_ARROWS_POS_X +4, CHANGE_TO_ARROWS_POS_Y
        lda #CHANGE_TO_ARROWS_PATTERN_INDEX + 1
        +tmsPut
        +tmsPut


        ; text
        +tmsSetAddrPattTableIIBank0 ' '
        +tmsSendData TMS_FONT_DATA, 8 * 64

        +tmsSetAddrColorTableIIBank0 ' '
        +tmsSendDataRpt .fontPal, 8, 64

        +tmsSetAddrColorTableIIBank0 '0'
        +tmsSendDataRpt .digitsPal, 8, 10

        jsr outputScore


        rts

addPlayerLife:
        inc PLAYER_LIVES
        bra uiRenderLives

losePlayerLife:
        dec PLAYER_LIVES
        ; do something if 0 (or -1?)
         ; flow on through

uiRenderLives:
        ldx #LIVES_NAMETABLE_POS_X
        ldy #LIVES_NAMETABLE_POS_Y
        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite

        lda #0
-
        inc
        sta TMP

        lda PLAYER_LIVES
        cmp TMP
        bcc @drawEmpty

        +tmsPut LIFE_PATTERN_INDEX
        +tmsPut LIFE_PATTERN_INDEX + 2
        +add16Imm TMS_TMP_ADDRESS, 32, TMS_TMP_ADDRESS
        jsr tmsSetAddressWrite
        +tmsPut LIFE_PATTERN_INDEX + 1
        +tmsPut LIFE_PATTERN_INDEX + 3
        
.checkNext
        +add16Imm TMS_TMP_ADDRESS, 32, TMS_TMP_ADDRESS
        jsr tmsSetAddressWrite

        lda TMP
        cmp #LIVES_MAX_VISIBLE
        bcc -
 
        rts

@drawEmpty
        lda #0
        +tmsPut
        +tmsPut
        +add16Imm TMS_TMP_ADDRESS, 32, TMS_TMP_ADDRESS
        jsr tmsSetAddressWrite
        lda #0
        +tmsPut
        +tmsPut
        bra .checkNext


uiTick:
        jsr .updateChangeArrows
        rts

.bertInitSendPatterns:
        +tmsSendData .bertCharPatt, 8 * 4
        rts

.bertInitSendColors:
        +tmsSendData .bertCharColor, 8 * 4        
        rts


.updateChangeArrows:
        lda HBC56_TICKS
        beq @changeArrowsNone
        cmp #20
        beq @changeArrowsOne
        cmp #40
        beq @changeArrowsTwo
        rts

@changeArrowsNone
        jsr .arrowsPosOne
        lda #0
        +tmsPut
        +tmsPut
        jsr .arrowsPosTwo
        lda #0
        +tmsPut
        +tmsPut
        rts
@changeArrowsOne
        jsr .arrowsPosOne
        +tmsPut CHANGE_TO_ARROWS_PATTERN_INDEX
        +tmsPut 0
        jsr .arrowsPosTwo
        +tmsPut 0
        +tmsPut CHANGE_TO_ARROWS_PATTERN_INDEX + 1
        rts
@changeArrowsTwo
        jsr .arrowsPosOne
        lda #CHANGE_TO_ARROWS_PATTERN_INDEX
        +tmsPut
        +tmsPut
        jsr .arrowsPosTwo
        lda #CHANGE_TO_ARROWS_PATTERN_INDEX + 1
        +tmsPut
        +tmsPut
        rts
        
.arrowsPosOne
        +tmsSetPosWrite CHANGE_TO_ARROWS_POS_X, CHANGE_TO_ARROWS_POS_Y
        rts

.arrowsPosTwo
        +tmsSetPosWrite CHANGE_TO_ARROWS_POS_X + 4, CHANGE_TO_ARROWS_POS_Y
        rts



; -----------------------------------------------------------------------------
; Output two BCD digits to current location
; Inputs:
;   A = BCD encoded value
; -----------------------------------------------------------------------------
outputBCD:
        sta TMP
        +lsr4
        ora #'0'
        +tmsPut
        lda TMP
outputBCDLow:
        and #$0f
        ora #'0'
        +tmsPut
        rts


; lsb bcd score to add in accumulator, msb score in TMP
scoreAdd:
        clc
        sed
        adc SCORE_L
        sta SCORE_L
        lda TMP
        adc SCORE_M
        sta SCORE_M
        bcc +
        lda #0
        adc SCORE_H
        sta SCORE_H
+
        cld

        ; flow on through

outputScore:
        +tmsSetPosWrite SCORE_POS_X, SCORE_POS_Y
        lda SCORE_H
        jsr outputBCD
        lda SCORE_M
        jsr outputBCD
        lda SCORE_L
        jsr outputBCD
        rts


.bertCharPatt:
!byte $00,$00,$3e,$7f,$e4,$e4,$ff,$ff
!byte $3e,$7f,$3f,$22,$22,$22,$33,$19
!byte $00,$00,$00,$00,$00,$00,$c0,$e0
!byte $f0,$c8,$48,$30,$00,$00,$00,$80

.bertCharColor:
!byte $80,$80,$90,$90,$8f,$81,$80,$80
!byte $86,$60,$60,$60,$60,$60,$80,$80
!byte $80,$80,$80,$80,$80,$80,$90,$90
!byte $80,$80,$80,$60,$60,$60,$80,$80




.changeToPatt
!byte $00,$00,$f4,$84,$87,$84,$f4,$00
!byte $00,$00,$99,$a5,$bd,$a5,$a5,$00
!byte $00,$00,$27,$a8,$6b,$29,$26,$00
!byte $00,$00,$78,$40,$70,$40,$78,$00
!byte $00,$00,$3e,$08,$08,$08,$08,$00
!byte $00,$00,$60,$92,$90,$92,$60,$00
.changeToArrowsPatt
!byte $10,$18,$fc,$fe,$fc,$18,$10,$00
!byte $08,$18,$3f,$7f,$3f,$18,$08,$00

.levelCirclePatt:
!byte $00,$00,$00,$01,$03,$07,$0f,$1e
!byte $07,$3f,$ff,$f8,$c0,$80,$00,$00
!byte $e0,$fc,$ff,$1f,$03,$01,$00,$00
!byte $00,$00,$00,$80,$c0,$e0,$f0,$78
!byte $3c,$38,$70,$70,$70,$e0,$e0,$e0
!byte $3c,$1c,$0e,$0e,$0e,$07,$07,$07
!byte $e0,$e0,$e0,$70,$70,$70,$38,$3c
!byte $07,$07,$07,$0e,$0e,$0e,$1c,$3c
!byte $1e,$0f,$07,$03,$01,$00,$00,$00
!byte $00,$00,$80,$c0,$f8,$ff,$3f,$07
!byte $00,$00,$01,$03,$1f,$ff,$fc,$e0
!byte $78,$f0,$e0,$c0,$80,$00,$00,$00

.levelOne:
!byte $01,$03,$07,$0f,$01,$01,$01,$01
!byte $01,$01,$01,$01,$01,$01,$01,$01
!byte $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
!byte $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0

.fontPal
+byteTmsColorFgBg TMS_DK_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_CYAN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_CYAN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_BLUE, TMS_TRANSPARENT

.digitsPal
+byteTmsColorFgBg TMS_DK_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MED_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MED_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_GREEN, TMS_TRANSPARENT

