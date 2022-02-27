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

LAST_BLOCK = ZP0 + 23

GAME_AREA_LEFT  = 8
GAME_AREA_WIDTH = 24 * 7
GAME_AREA_RIGHT = GAME_AREA_LEFT + GAME_AREA_WIDTH

BALL_BASE   = TMS_WHITE
BALL_SHADE  = TMS_GREY

PADDLE_HIGH  = TMS_WHITE
PADDLE_BASE  = TMS_CYAN
PADDLE_SHADE = TMS_LT_BLUE

PADDLE_WIDTH = 32
NUM_BLOCKS   = 128

LEVEL_DATA   = $0400

hbc56Meta:
        +setHbcMetaTitle "BREAKOUT"
        rts

hbc56Main:
        sei

        jsr tmsModeGraphicsII

        lda #$0f
        jsr tmsReg1ClearFields

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

        jsr resetGame

        +tmsCreateSprite 0, 0, 0, 0, BALL_BASE
        +tmsCreateSprite 1, 1, 0, 0, BALL_SHADE

        +tmsCreateSprite 2, 2, 0, 0, PADDLE_HIGH
        +tmsCreateSprite 3, 3, 0, 0, PADDLE_SHADE

        jsr setBallPos

        +tmsEnableOutput

        +hbc56SetVsyncCallback gameLoop

        +tmsEnableInterrupts

        cli

        jsr hbc56Stop

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

loadLevel:
        +memcpy LEVEL_DATA, level1, 128

        jsr renderLevel

        lda #79
        sta LAST_BLOCK

        rts


renderLevel:
        ldx #0
-
        jsr renderBlock
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

resetGame:

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

        +tmsSetPosWrite 0, 23
        lda #0
        ldx #32
-
        +tmsPut
        dex
        bne -

        jsr loadLevel

        jsr drawBorder
        
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

        +tmsColorFgBg TMS_WHITE, TMS_MAGENTA
        jsr tmsSetBackground

        lda POSY
        cmp #12 * 8
        bcs @noHit

        ; convert position to cell
        ldx POSX
        ldy POSY
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
        bra @doneXCheck
@checkLeft
        lda POSX
        cmp #GAME_AREA_LEFT
        bcs @doneXCheck
        +negate DIRX
@doneXCheck

        bit DIRY
        bmi @checkTop
        lda POSY
        cmp #192-6
        bcc @checkPaddle
        cmp #240
        bcc @doneYCheck
        jsr resetGame
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
        +negate DIRY
        +nes1BranchIfNotPressed NES_LEFT, +
        jsr pushLeft
+
        +nes1BranchIfNotPressed NES_RIGHT, +
        jsr pushRight
+

        bra @doneYCheck

@checkTop
        lda POSY
        cmp #9
        bcs @doneYCheck
        +negate DIRY
@doneYCheck


        jsr setBallPos

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground


        rts

pushLeft:
        bit DIRX
        bmi increaseSpdX
        bra decreaseSpdX

pushRight:
        bit DIRX
        bpl increaseSpdX
        bra decreaseSpdX

increaseSpdX:
        clc
        lda #100
        adc SPDX_SUB
        sta SPDX_SUB
        bcc +
        inc SPDX
+
        rts
        
decreaseSpdX:
        sec
        lda SPDX_SUB
        sbc #100
        sta SPDX_SUB
        bcs +
        dec SPDX
        bpl +
        lda #0
        sta SPDX
        +negate SPDX_SUB
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

BORDER_BASE_FGBG  = TMS_MAGENTA << 4 | TMS_TRANSPARENT
BORDER_HIGH_FGBG  = TMS_WHITE   << 4 | TMS_TRANSPARENT

borderPal:
!byte BORDER_HIGH_FGBG,BORDER_BASE_FGBG,BORDER_BASE_FGBG,BORDER_BASE_FGBG,BORDER_BASE_FGBG,BORDER_BASE_FGBG,BORDER_BASE_FGBG,BORDER_BASE_FGBG,BORDER_BASE_FGBG





; LEVEL DATA
; ----------

level1: 
!byte 0,0,0,0,0,0,0,0 ; block types
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
