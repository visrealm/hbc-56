; Troy's HBC-56 - Breakout
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

ZP0 = HBC56_USER_ZP_START
POSX     = ZP0
POSX_SUB = ZP0 + 1
POSY     = ZP0 + 2
POSY_SUB = ZP0 + 3

SPDX     = ZP0 + 4
SPDX_SUB = ZP0 + 5
SPDY     = ZP0 + 6
SPDY_SUB = ZP0 + 7

DIRX     = ZP0 + 8
DIRY     = ZP0 + 9

TMP      = ZP0 + 10
; a block of TMP

PADX     = ZP0 + 21
PADW     = ZP0 + 22

LEVEL    = ZP0 + 23
SCORE_H  = ZP0 + 24
SCORE_M  = ZP0 + 25
SCORE_L  = ZP0 + 26
BALLS    = ZP0 + 27

MULT     = ZP0 + 28

BLOCK_COUNT = ZP0 + 29

PADSPD     = ZP0 + 30
PADSPD_SUB = ZP0 + 31


GAME_AREA_LEFT  = 8
GAME_AREA_WIDTH = 24 * 7
GAME_AREA_RIGHT = GAME_AREA_LEFT + GAME_AREA_WIDTH

BALL_BASE   = TMS_WHITE
BALL_SHADE  = TMS_GREY

PADDLE_HIGH  = TMS_WHITE
PADDLE_BASE  = TMS_CYAN
PADDLE_SHADE = TMS_LT_BLUE

TONE_PADDLE = 6
TONE_WALL   = 2
TONE_BRICK  = 4


PADDLE_WIDTH      = 32
PADDLE_SPEED      = 0
PADDLE_SPEED_SUB  = 100
NUM_BLOCKS        = 128

LEVEL_DATA   = $0400

hbc56Meta:
        +setHbcMetaTitle "BREAKOUT"
        +setHbcMetaNES
        rts

hbc56Main:
        sei

        jsr tmsModeGraphicsII

        +tmsDisableInterrupts
        +tmsDisableOutput

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        ; initialise vram
        +tmsSetAddrNameTable
        lda #0
        jsr _tmsSendPage        
        jsr _tmsSendPage
        jsr _tmsSendPage

        +tmsSetAddrColorTable
        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        

        +tmsSetAddrPattTable
        lda #0
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb


        ; block data
        +tmsSetAddrColorTableII 3
        +tmsSendData redBlockPal, 8
        +tmsSendData redBlockPal+8, 8
        +tmsSendData redBlockPal+8, 8
        +tmsSendData yellowBlockPal, 8
        +tmsSendData yellowBlockPal+8, 8
        +tmsSendData yellowBlockPal+8, 8

        +tmsSetAddrColorTableII 259
        +tmsSendData greenBlockPal, 8
        +tmsSendData greenBlockPal+8, 8
        +tmsSendData greenBlockPal+8, 8
        +tmsSendData blueBlockPal, 8
        +tmsSendData blueBlockPal+8, 8
        +tmsSendData blueBlockPal+8, 8

        +tmsSetAddrPattTableInd 3
        +tmsSendData block, 8 * 3
        +tmsSendData block, 8 * 3
        +tmsSetAddrPattTableInd 259
        +tmsSendData block, 8 * 3
        +tmsSendData block, 8 * 3

        ; title data
        +tmsSetAddrPattTableInd 128
        +tmsSendData titlePatt, 8*9*2
        +tmsSetAddrColorTableII 128
        lda #9
        sta TMP
-
        +tmsSendData titlePal, 8
        dec TMP
        bne -

        lda #9
        sta TMP
-
        +tmsSendData titlePal + 8, 8
        dec TMP
        bne -

        ; label data
        +tmsSetAddrPattTableInd 146
        +tmsSendData levelPatt, 8*7

        +tmsSetAddrPattTableInd 256+146
        +tmsSendData scorePatt, 8*7
        +tmsSendData ballsPatt, 8*7

        +tmsSetAddrColorTableII 146
        lda #8
        sta TMP
-
        +tmsSendData labelPal, 8
        dec TMP
        bne -

        +tmsSetAddrColorTableII 256+146
        lda #16
        sta TMP
-
        +tmsSendData labelPal, 8
        dec TMP
        bne -

        ; digits data
        +tmsSetAddrPattTableInd '0'
        +tmsSendData digitsPatt, 8*10
        +tmsSetAddrPattTableInd 256+'0'
        +tmsSendData digitsPatt, 8*10
        +tmsSetAddrPattTableInd 512+'0'
        +tmsSendData digitsPatt, 8*10

        +tmsSetAddrColorTableII '0'
        lda #10
        sta TMP
-
        +tmsSendData digitsPal, 8
        dec TMP
        bne -

        +tmsSetAddrColorTableII 256+'0'
        lda #10
        sta TMP
-
        +tmsSendData digitsPal, 8
        dec TMP
        bne -

        +tmsSetAddrColorTableII 512+'0'
        lda #10
        sta TMP
-
        +tmsSendData digitsPal, 8
        dec TMP
        bne -

;        +tmsSetPosWrite 0,4
;        +tmsSendData block1, 32 * 2
;        +tmsSendData block2, 32 * 2
;        +tmsSendData block1, 32 * 2
;        +tmsSendData block2, 32 * 2


        ; create ball
        +tmsCreateSpritePattern 0, ballPattern
        +tmsCreateSpritePattern 1, ballPattern + 8

        ; create paddle highlights
        +tmsCreateSpritePattern 2, paddleLeftSpr
        +tmsCreateSpritePattern 3, paddleRightSpr
        ; create paddle patterns
        +tmsSetAddrPattTableInd 768-32
        +memcpy TMP, paddlePatt, 8
        ldy #8
--
        phy
        +tmsSendData TMP, 8
        ply
        ldx #0
-
        lsr TMP, x
        inx
        cpx #8
        bne -
        dey
        bne --
        +tmsSendData paddlePatt + 8, 8
        +memcpy TMP, paddlePatt + 16, 8
        ldy #8
--
        phy
        +tmsSendData TMP, 8
        ply
        ldx #0
-
        asl TMP, x
        inx
        cpx #8
        bne -
        dey
        bne --

        ; set up paddle row colors
        +tmsSetAddrColorTableII 768-32
        ldy #32
        sty TMP
-
        +tmsSendData paddlePal, 8
        dec TMP
        bne -


        +ayToneEnable AY_PSG0, AY_CHC
        +aySetVolume AY_PSG0, AY_CHC, $00

        +aySetVolumeEnvelope AY_PSG0, AY_CHC
        +aySetEnvelopePeriod AY_PSG0, 850



        lda #4
        sta BALLS

        lda #0
        sta SCORE_H
        sta SCORE_M
        sta SCORE_L

        lda #1
        sta LEVEL

        lda #PADDLE_SPEED
        sta PADSPD
        lda #PADDLE_SPEED_SUB
        sta PADSPD_SUB

        jsr resetGame

        +tmsCreateSprite 0, 0, 0, 0, BALL_BASE
        +tmsCreateSprite 1, 1, 0, 0, BALL_SHADE

        +tmsCreateSprite 2, 2, 0, 0, PADDLE_HIGH
        +tmsCreateSprite 3, 3, 0, 0, PADDLE_SHADE

        jsr setBallPos

        +tmsEnableOutput

        jsr gameLoop

        +hbc56SetVsyncCallback gameLoop

        +tmsEnableInterrupts

        cli

-
        +nes1BranchIfNotPressed NES_B, +
        jsr tmsModeGraphicsI
+
        +nes1BranchIfNotPressed NES_A, -
        jmp hbc56Main

        rts



!macro negate val {
        lda val
        eor #$ff
        inc
        sta val
}


!macro addSubPixel pos, spd, dir {
        bit dir
        bpl @posDir
@negDir
        clc
        lda pos + 1
        adc spd + 1
        sta pos + 1
        lda pos
        bcs +
        dec
+
        sec
        sbc spd
        sta pos
        bra @end
@posDir
        clc
        lda pos + 1
        adc spd + 1
        sta pos + 1
        
        lda pos
        adc spd
        sta pos
@end
}

playNote:
        tax
        lda notesL,x
        +ayWriteA AY_PSG0, AY_CHC_TONE_L
        lda notesH,x
        +ayWriteA AY_PSG0, AY_CHC_TONE_H
        +aySetEnvShape AY_PSG0,AY_ENV_SHAPE_FADE_OUT
        rts

loadLevel:
        lda LEVEL
        cmp #2
        bne +
        +memcpy LEVEL_DATA, level2, 128
        jmp @endLoad
+
        cmp #3
        bne +
        +memcpy LEVEL_DATA, level3, 128
        jmp @endLoad
+

        ; default to level 1
        +memcpy LEVEL_DATA, level1, 128


@endLoad
        lda #0
        sta BLOCK_COUNT
        jsr renderLevel

        rts


renderLevel:
        ldx #0
-
        jsr renderBlock
        lda LEVEL_DATA, x
        beq +
        inc BLOCK_COUNT
+
        inx
        cpx #NUM_BLOCKS
        bne -
        rts

; X is block index
renderBlock:
        phx
        stx TMP
        txa
        +div8
        inc
        tay
        lda TMP
        and #$07
        sta TMP
        asl
        sec
        adc TMP
        tax

        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite

        plx
        lda LEVEL_DATA, x 
        +tmsPut
        inc
        +tmsPut
        inc
        +tmsPut


        rts


loseBall:
        lda #1
        sta MULT
        dec BALLS
        bmi endGame

        jsr resetPaddle

        rts

resetPaddle:
        ; draw paddle pattern
        lda #(GAME_AREA_WIDTH-PADDLE_WIDTH)/2 + GAME_AREA_LEFT
        sta PADX
        lda #PADDLE_WIDTH
        sta PADW

        jsr drawPaddle

        lda #0
        sta POSX_SUB
        sta POSY_SUB

        lda #0
        sta SPDX
        lda #2
        sta SPDY

        lda #0
        sta SPDX_SUB

        lda #0
        sta SPDY_SUB

        lda #1
        sta DIRX
        sta DIRY

        lda #GAME_AREA_WIDTH/2+GAME_AREA_LEFT-3
        sta POSX

        lda #128-3
        sta POSY

        +tmsSetPosWrite 1, 23
        lda #0
        ldx #21
-
        +tmsPut
        dex
        bne -


        ; output ball count
        +tmsSetPosWrite 26, 16
        +tmsPut '0'
        lda BALLS
        jsr outputBCD

        rts


nextLevel
        inc LEVEL
        bra resetGame

endGame:
        lda #1
        sta LEVEL

        lda #0
        sta SCORE_L
        sta SCORE_M
        sta SCORE_H

        lda #4
        sta BALLS
        bra resetGame

resetGame:

        jsr resetPaddle

        jsr loadLevel

        jsr drawBorder

        ; output level number
        +tmsSetPosWrite 26, 6
        +tmsPut '0'
        lda LEVEL
        jsr outputBCD

        lda #0
        jsr addScore
                
        rts

addScore:
        sed
        adc SCORE_L
        sta SCORE_L
        bcc @endAddScore
        lda #0
        adc SCORE_M
        sta SCORE_M
        bcc @endAddScore
        lda #0
        adc SCORE_H
        sta SCORE_H

@endAddScore
        cld

        ; output ball count
        +tmsSetPosWrite 25, 11
        lda SCORE_H
        jsr outputBCD
        lda SCORE_M
        jsr outputBCD
        lda SCORE_L
        jsr outputBCD
        rts

outputBCD:
        sta TMP
        +lsr4
        ora #$30
        +tmsPut
        lda TMP
        and #$0f
        ora #$30
        +tmsPut
        rts

drawBorder:
        ; border patterns
        +tmsSetAddrPattTableInd $10
        +tmsSendData borderTL, 7*8
        +tmsSetAddrPattTableInd $110
        +tmsSendData borderTL, 7*8
        +tmsSetAddrPattTableInd $210
        +tmsSendData borderTL, 7*8

        ; border palette
        +tmsSetAddrColorTableII $10
        jsr sendBorderPal
        +tmsSetAddrColorTableII $110
        jsr sendBorderPal
        +tmsSetAddrColorTableII $210
        jsr sendBorderPal

        ; border
        +tmsSetPosWrite 0,0
        +tmsPut $10
        ldx #7*3
        lda #$11
-
        +tmsPut
        dex
        bne -
        +tmsPut $12

        ldx #0
        ldy #1
        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite
        ldx #22
-
        +tmsPut $13
        jsr tmsSetAddressNextRow
        jsr tmsSetAddressWrite
        dex
        bne -
        +tmsPut $15


        ldx #7*3+1
        ldy #1
        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite
        ldx #22
-
        +tmsPut $14
        jsr tmsSetAddressNextRow
        jsr tmsSetAddressWrite
        dex
        bne -
        +tmsPut $15

        +tmsSetPosWrite 23,0
        lda #128
        ldx #9
-
        +tmsPut
        inc
        dex
        bne -

        ; render title
        +tmsSetPosWrite 23,1
        lda #128+9
        ldx #9
-
        +tmsPut
        inc
        dex
        bne -

        ; render labels
        +tmsSetPosWrite 24,4
        lda #146
        ldx #7
-
        +tmsPut
        inc
        dex
        bne -

        +tmsSetPosWrite 24,9
        lda #146
        ldx #7
-
        +tmsPut
        inc
        dex
        bne -

        +tmsSetPosWrite 24,14
        lda #146+7
        ldx #7
-
        +tmsPut
        inc
        dex
        bne -



        rts

sendBorderPal
        +tmsSendData borderPal, 8
        +tmsSendData borderPal, 8
        +tmsSendData borderPal, 8
        +tmsSendData borderPal+1, 8
        +tmsSendData borderPal+1, 8
        +tmsSendData borderPal+1, 8
        +tmsSendData borderPal+1, 8
        rts


drawPaddle:
        lda PADW
        cmp #8
        bcs +
        rts
+
        lda PADX
        +div8
        sta TMP
        cmp #1
        beq +
        dec
+
        tax
        ldy #23
        jsr tmsSetPosWrite
        lda TMP
        cmp #1
        beq +
        +tmsPut 0
+
        lda PADX
        and #$07

        tax
        clc
        adc PADW
        sec
        sbc #8
        sta TMP

        lda leftPatterns, x
        +tmsPut

@loop
        lda TMP
        beq @doneDraw
        cmp #9
        bcc +
        lda #8
+
        tax
        lda TMP
        stx TMP
        sec
        sbc TMP
        sta TMP

        lda rightPatterns, x
        +tmsPut
        bra @loop

@doneDraw:
        lda PADX
        clc
        adc PADW
        cmp #GAME_AREA_RIGHT-8
        bcs +
        +tmsPut 0
+

        ldx PADX
        ldy #192-5
        +tmsSpritePosXYReg 2
        clc
        txa
        adc PADW
        dec
        tax
        +tmsSpritePosXYReg 3
        rts



setBallPos:
        ldx POSX
        bit POSX_SUB
        bpl +
        inx
+
        ldy POSY
        bit POSY_SUB
        bpl +
        iny
+
        +tmsSpritePosXYReg 0
        +tmsSpritePosXYReg 1
        rts

xPosToLevelCell:
!byte 255,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,255,255,255
yPosToLevelCell:
!byte 255,0,8,16,24,32,40,48,56,64,72,80,88,96,104,112,255

; X and Y = pixel location
; returns: A = level index (or 255)
posToLevelCell:
        txa
        +div8
        tax
        lda xPosToLevelCell, x
        cmp #255
        beq @outOfBounds
        sta TMP
        tya
        +div8
        tay
        lda yPosToLevelCell, y
        cmp #255
        beq @outOfBounds
        clc
        adc TMP

@outOfBounds:
        rts


gameLoop:
        ;!byte $db

        ;+tmsColorFgBg TMS_WHITE, TMS_MAGENTA
        ;jsr tmsSetBackground

        lda POSY
        cmp #12 * 8
        bcs @noHit

        ; convert position to cell
        ldx POSX
        inx
        inx
        inx
        ldy POSY
        iny
        iny
        iny
        jsr posToLevelCell
        cmp #255
        beq @noHit
        tax
        lda LEVEL_DATA, x
        beq @noHit
        lda #0
        sta LEVEL_DATA, x
        jsr renderBlock
        +negate DIRY
        dec BLOCK_COUNT
        bne +
        jsr nextLevel
+

        ldx MULT
-
        lda #$25
        jsr addScore
        dex
        bne -

        inc MULT

        lda MULT
        inc
        inc
        jsr playNote

@noHit:


        +nes1BranchIfNotPressed NES_LEFT, +
        lda PADX
        cmp #GAME_AREA_LEFT + 2
        bcc +
        dec PADX
        dec PADX
+
        +nes1BranchIfNotPressed NES_RIGHT, +
        lda PADX
        clc
        adc PADW
        cmp #GAME_AREA_RIGHT-2
        bcs +
        inc PADX
        inc PADX
+
        jsr drawPaddle

        +addSubPixel POSX, SPDX, DIRX
        +addSubPixel POSY, SPDY, DIRY

        bit DIRX
        bmi @checkLeft
        lda POSX
        cmp #GAME_AREA_RIGHT-5
        bcc @doneXCheck
        +negate DIRX

        lda #TONE_WALL
        jsr playNote

        bra @doneXCheck
@checkLeft
        lda POSX
        cmp #GAME_AREA_LEFT
        bcs @doneXCheck
        +negate DIRX

        lda #TONE_WALL
        jsr playNote

@doneXCheck

        bit DIRY
        bmi @checkTop
        lda POSY
        cmp #192-6
        bcc @checkPaddle
        cmp #240
        bcc @doneYCheck
        jmp loseBall

@checkPaddle
        cmp #192-5-6
        bcc  @doneYCheck
        lda PADX
        cmp #6
        bcc +
        sec
        sbc #5
+
        cmp POSX
        bcs @doneYCheck
        lda PADX
        clc
        adc PADW
        cmp POSX
        bcc @doneYCheck
        
        ; paddle hit
        +negate DIRY

        +nes1BranchIfNotPressed NES_LEFT, +
        jsr pushLeft
+
        +nes1BranchIfNotPressed NES_RIGHT, +
        jsr pushRight
+
        lda #1
        sta MULT

        lda #TONE_PADDLE
        jsr playNote

        bra @doneYCheck

@checkTop
        lda POSY
        cmp #9
        bcs @doneYCheck
        +negate DIRY

        lda #TONE_WALL
        jsr playNote

@doneYCheck


        jsr setBallPos

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground


        rts

pushLeft:
        lda #-1
        sta TMP
        +addSubPixel SPDX, PADSPD, TMP

        lda SPDX
        bpl +
        +negate SPDX
        +negate DIRX
+

        rts

pushRight:
        lda #1
        sta TMP
        +addSubPixel SPDX, PADSPD, TMP

        lda SPDX
        bpl +
        +negate SPDX
        +negate DIRX
+

        rts


; BALL
; ----------

ballPattern:
!byte $70,$f8,$f8,$f8,$70,$00,$00,$00
!byte $00,$18,$28,$58,$70,$00,$00,$00


; PADDLE
; ----------

PADDLE_HIGH_FGBG  = PADDLE_HIGH << 4 | TMS_BLACK
PADDLE_BASE_FGBG  = PADDLE_BASE << 4 | TMS_BLACK
PADDLE_SHADE_FGBG = PADDLE_SHADE << 4 | TMS_BLACK

paddlePal:
!byte TMS_BLACK,TMS_BLACK,TMS_BLACK,PADDLE_HIGH_FGBG,PADDLE_BASE_FGBG,PADDLE_BASE_FGBG,PADDLE_BASE_FGBG,PADDLE_SHADE_FGBG
paddleLeftSpr:
!byte $c0,$80,$80,$00,$00,$00,$00,$00
paddleRightSpr:
!byte $40,$40,$c0,$00,$00,$00,$00,$00
paddlePatt:
!byte $00,$00,$00,$7f,$ff,$ff,$ff,$7f   ; left
!byte $00,$00,$00,$ff,$ff,$ff,$ff,$ff   ; centre
!byte $00,$00,$00,$fe,$ff,$ff,$ff,$fe   ; right

leftPatterns:
!byte 224,225,226,227,228,229,230,231
rightPatterns:
!byte 240,239,238,237,236,235,234,233,232



; BLOCKS
; ----------

block:
!byte $7f,$3f,$7f,$7f,$7f,$7f,$7f,$00   ; left
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00   ; centre
!byte $fc,$fe,$fe,$fe,$fe,$fe,$fc,$00   ; right

BLUE_HIGH       = TMS_CYAN    << 4   | TMS_TRANSPARENT
BLUE_BASE       = TMS_LT_BLUE << 4   | TMS_TRANSPARENT
BLUE_BASEH      = TMS_LT_BLUE << 4   | TMS_CYAN
BLUE_SHADE      = TMS_DK_BLUE << 4   | TMS_TRANSPARENT

GREEN_HIGH      = TMS_LT_GREEN  << 4 | TMS_TRANSPARENT
GREEN_BASE      = TMS_MED_GREEN << 4 | TMS_TRANSPARENT
GREEN_BASEH     = TMS_MED_GREEN << 4 | TMS_LT_GREEN
GREEN_SHADE     = TMS_DK_GREEN  << 4 | TMS_TRANSPARENT

YELLOW_HIGH     = TMS_WHITE     << 4 | TMS_TRANSPARENT
YELLOW_BASE     = TMS_LT_YELLOW << 4 | TMS_TRANSPARENT
YELLOW_BASEH    = TMS_LT_YELLOW << 4 | TMS_WHITE
YELLOW_SHADE    = TMS_DK_YELLOW << 4 | TMS_TRANSPARENT

RED_HIGH        = TMS_LT_RED  << 4 | TMS_TRANSPARENT
RED_BASE        = TMS_MED_RED << 4 | TMS_TRANSPARENT
RED_BASEH       = TMS_MED_RED << 4 | TMS_LT_RED
RED_SHADE       = TMS_DK_RED  << 4 | TMS_TRANSPARENT

blueBlockPal:
!byte BLUE_HIGH,BLUE_BASEH,BLUE_BASEH,BLUE_BASEH,BLUE_BASEH,BLUE_BASEH,BLUE_SHADE,TMS_TRANSPARENT
!byte BLUE_HIGH,BLUE_BASE,BLUE_BASE,BLUE_BASE,BLUE_BASE,BLUE_BASE,BLUE_SHADE,TMS_TRANSPARENT
greenBlockPal:
!byte GREEN_HIGH,GREEN_BASEH,GREEN_BASEH,GREEN_BASEH,GREEN_BASEH,GREEN_BASEH,GREEN_SHADE,TMS_TRANSPARENT
!byte GREEN_HIGH,GREEN_BASE,GREEN_BASE,GREEN_BASE,GREEN_BASE,GREEN_BASE,GREEN_SHADE,TMS_TRANSPARENT
yellowBlockPal:
!byte YELLOW_HIGH,YELLOW_BASEH,YELLOW_BASEH,YELLOW_BASEH,YELLOW_BASEH,YELLOW_BASEH,YELLOW_SHADE,TMS_TRANSPARENT
!byte YELLOW_HIGH,YELLOW_BASE,YELLOW_BASE,YELLOW_BASE,YELLOW_BASE,YELLOW_BASE,YELLOW_SHADE,TMS_TRANSPARENT
redBlockPal:
!byte RED_HIGH,RED_BASEH,RED_BASEH,RED_BASEH,RED_BASEH,RED_BASEH,RED_SHADE,TMS_TRANSPARENT
!byte RED_HIGH,RED_BASE,RED_BASE,RED_BASE,RED_BASE,RED_BASE,RED_SHADE,TMS_TRANSPARENT

; BORDER
; ----------

borderTL:
!byte $3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff
borderT:
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
borderTR:
!byte $f8,$fc,$fe,$fe,$fe,$fe,$fe,$fe
borderL:
!byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
borderR:
!byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
borderBL:
!byte $fe,$fe,$fe,$fe,$fe,$7c,$7c,$38
borderBR:
!byte $fe,$fe,$fe,$fe,$fe,$7c,$7c,$38

borderPal:
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT


; TITLE
; ----------

titlePatt:
!byte $00,$1e,$3f,$7f,$03,$01,$03,$7f,$00,$0f,$1f,$bf,$81,$80,$81,$bf,$00,$1f,$9f,$df,$d8,$d8,$d8,$df,$00,$e1,$c1,$83,$03,$07,$06,$e6,$00,$86,$86,$c6,$c6,$e6,$66,$67,$00,$18,$39,$33,$63,$67,$c6,$c6,$00,$c3,$e3,$f3,$33,$3b,$1b,$1b,$00,$0c,$0c,$0d,$0c,$0c,$0c,$0c,$00,$7f,$fe,$fc,$30,$30,$30,$30
!byte $7f,$7f,$63,$61,$63,$7f,$7f,$7f,$3f,$bf,$be,$b7,$b3,$b1,$b0,$30,$df,$9f,$18,$18,$98,$df,$df,$df,$c6,$86,$06,$0e,$0c,$ec,$cd,$8d,$67,$67,$66,$76,$36,$36,$f6,$f6,$86,$c6,$c6,$67,$63,$33,$39,$18,$1b,$1b,$1b,$3b,$31,$f1,$e0,$c0,$0c,$0c,$0c,$9c,$98,$f8,$f0,$60,$30,$30,$30,$30,$30,$30,$30,$30

titlePal:
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_GREY, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_GREY, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_GREY, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_GREY, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_GREY, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MED_RED, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_YELLOW, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MED_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_BLUE, TMS_TRANSPARENT

; LABELS
; ----------

levelPatt:
!byte $0c,$0c,$0c,$0c,$0c,$0c,$0f,$0f,$07,$07,$06,$07,$07,$06,$f7,$e7,$fb,$f3,$01,$f9,$f0,$00,$f8,$f0,$01,$83,$83,$c7,$c6,$6c,$7c,$38,$bf,$bf,$30,$3f,$3f,$30,$3f,$3f,$d8,$98,$18,$d8,$98,$18,$df,$9f,$00,$00,$00,$00,$00,$00,$e0,$c0
scorePatt:
!byte $1f,$3f,$30,$3f,$3f,$00,$1f,$3f,$e3,$c7,$07,$ce,$ee,$67,$e7,$c3,$fc,$f8,$01,$01,$01,$01,$fc,$f8,$7e,$ff,$c3,$81,$81,$c3,$ff,$7e,$0f,$1f,$80,$80,$9f,$9f,$18,$18,$e3,$f3,$3b,$3b,$f3,$e3,$73,$3b,$fc,$f8,$00,$fc,$f8,$00,$fc,$f8
ballsPatt:
!byte $0f,$1f,$00,$1f,$1f,$18,$1f,$1f,$e0,$f0,$30,$f1,$f3,$33,$f6,$e6,$60,$f0,$f0,$98,$9c,$0c,$7e,$fe,$c0,$c0,$c0,$c0,$c0,$c0,$ff,$fe,$60,$60,$60,$60,$60,$60,$7f,$7f,$1f,$3f,$30,$3f,$3f,$00,$9f,$3f,$e0,$c0,$00,$c0,$e0,$60,$e0,$c0

labelPal:
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT

; FONT
; ----------

digitsPatt:
!byte $7C,$CE,$DE,$F6,$E6,$C6,$7C,$00 ; 0
!byte $18,$38,$18,$18,$18,$18,$7E,$00 ; 1
!byte $7C,$C6,$06,$7C,$C0,$C0,$FE,$00 ; 2
!byte $FC,$06,$06,$3C,$06,$06,$FC,$00 ; 3
!byte $0C,$CC,$CC,$CC,$FE,$0C,$0C,$00 ; 4
!byte $FE,$C0,$FC,$06,$06,$C6,$7C,$00 ; 5
!byte $7C,$C0,$C0,$FC,$C6,$C6,$7C,$00 ; 6
!byte $FE,$06,$06,$0C,$18,$30,$30,$00 ; 7
!byte $7C,$C6,$C6,$7C,$C6,$C6,$7C,$00 ; 8
!byte $7C,$C6,$C6,$7E,$06,$06,$7C,$00 ; 9

digitsPal:
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT

; AUDIO DATA
; ----------

notesL:
!byte 0
+ayToneByteL NOTE_FREQ_B3
+ayToneByteL NOTE_FREQ_C4
+ayToneByteL NOTE_FREQ_CS4
+ayToneByteL NOTE_FREQ_D4
+ayToneByteL NOTE_FREQ_DS4
+ayToneByteL NOTE_FREQ_E4
+ayToneByteL NOTE_FREQ_F4
+ayToneByteL NOTE_FREQ_FS4
+ayToneByteL NOTE_FREQ_G4
+ayToneByteL NOTE_FREQ_GS4
+ayToneByteL NOTE_FREQ_A4
+ayToneByteL NOTE_FREQ_AS4
+ayToneByteL NOTE_FREQ_B4
+ayToneByteL NOTE_FREQ_C5
+ayToneByteL NOTE_FREQ_CS5
+ayToneByteL NOTE_FREQ_D5
+ayToneByteL NOTE_FREQ_DS5
+ayToneByteL NOTE_FREQ_E5
+ayToneByteL NOTE_FREQ_F5
+ayToneByteL NOTE_FREQ_FS5
+ayToneByteL NOTE_FREQ_G5
+ayToneByteL NOTE_FREQ_GS5
+ayToneByteL NOTE_FREQ_A5
+ayToneByteL NOTE_FREQ_AS5

notesH:
!byte 0
+ayToneByteH NOTE_FREQ_B3
+ayToneByteH NOTE_FREQ_C4
+ayToneByteH NOTE_FREQ_CS4
+ayToneByteH NOTE_FREQ_D4
+ayToneByteH NOTE_FREQ_DS4
+ayToneByteH NOTE_FREQ_E4
+ayToneByteH NOTE_FREQ_F4
+ayToneByteH NOTE_FREQ_FS4
+ayToneByteH NOTE_FREQ_G4
+ayToneByteH NOTE_FREQ_GS4
+ayToneByteH NOTE_FREQ_A4
+ayToneByteH NOTE_FREQ_AS4
+ayToneByteH NOTE_FREQ_B4
+ayToneByteH NOTE_FREQ_C5
+ayToneByteH NOTE_FREQ_CS5
+ayToneByteH NOTE_FREQ_D5
+ayToneByteH NOTE_FREQ_DS5
+ayToneByteH NOTE_FREQ_E5
+ayToneByteH NOTE_FREQ_F5 
+ayToneByteH NOTE_FREQ_FS5
+ayToneByteH NOTE_FREQ_G5
+ayToneByteH NOTE_FREQ_GS5
+ayToneByteH NOTE_FREQ_A5
+ayToneByteH NOTE_FREQ_AS5


; LEVEL DATA
; ----------

level1: 
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 3,3,3,3,3,3,3,0
!byte 6,6,6,6,6,6,6,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 3,3,3,3,3,3,3,0
!byte 6,6,6,6,6,6,6,0
!fill 128-88, 0


level2: 
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 3,3,3,3,3,3,3,0
!byte 3,3,3,3,3,3,3,0
!byte 6,6,6,6,6,6,6,0
!byte 6,6,6,6,6,6,6,0
!byte 3,3,3,3,3,3,3,0
!byte 3,3,3,3,3,3,3,0
!byte 6,6,6,6,6,6,6,0
!byte 6,6,6,6,6,6,6,0
!fill 128-88, 0


level3: 
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 3,3,3,3,3,3,3,0
!byte 0,0,0,0,0,0,0,0
!byte 6,6,6,6,6,6,6,0
!byte 0,0,0,0,0,0,0,0
!byte 3,3,3,3,3,3,3,0
!byte 0,0,0,0,0,0,0,0
!byte 6,6,6,6,6,6,6,0
!byte 0,0,0,0,0,0,0,0
!fill 128-88, 0
