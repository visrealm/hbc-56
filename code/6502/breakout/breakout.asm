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

PADX     = ZP0 + 11
PADW     = ZP0 + 12

BALL_BASE   = TMS_WHITE
BALL_SHADE  = TMS_GREY

PADDLE_HIGH  = TMS_CYAN << 4 | TMS_BLACK
PADDLE_BASE  = TMS_LT_BLUE << 4 | TMS_BLACK
PADDLE_SHADE = TMS_DK_BLUE << 4 | TMS_BLACK



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

        +tmsColorFgBg TMS_WHITE, TMS_MAGENTA
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


        ; create ball
        +tmsCreateSpritePattern 0, ballPattern
        +tmsCreateSpritePattern 1, ballPattern + 8



        ; output paddle row name table entries
        +tmsSetPosWrite 0, 23
        lda #256-32
        ldx #32
-
        +tmsPut
        inc
        dex
        bne -

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
        clc
        adc #1
        sta val
}


!macro addSubPixel pos, spd, dir {
        bit dir
        bpl ++
        clc
        lda pos + 1
        adc spd + 1
        sta pos + 1
        lda pos
        bcc +
        dec
+
        sec
        sbc spd
        sta pos
        bra +++
++
        clc
        lda pos + 1
        adc spd + 1
        sta pos + 1
        
        lda pos
        adc spd
        sta pos
+++
}

resetGame:

        ; draw paddle pattern
        lda #128-12
        sta PADX
        lda #32
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

        lda #128-3
        sta POSX

        lda #98-3
        sta POSY

        lda #256-32
        ldy #0
        jsr tmsSetPatternTmpAddressBank2
        jsr tmsSetAddressWrite
        lda #0
        jsr _tmsSendPage        

        rts

drawPaddle:
        lda PADX
        +div8
        dec
        clc
        adc #256-32
        ldy #3
        jsr tmsSetPatternTmpAddressBank2
        jsr tmsSetAddressWrite
        lda #0
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut

        lda PADW
        sta TMP
        lda PADX
        and #$07
        tax
        clc
        adc TMP
        sec
        sbc #8
        sta TMP
        lda #$ff
        cpx #0
        beq +
-
        lsr
        dex
        bne -
+
        lsr
        +tmsPut
        sec
        rol
        +tmsPut
        +tmsPut
        +tmsPut
        lsr
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
        dex
        lda #$80
        cpx #0
        beq +
-
        sec
        ror
        dex
        bne -
+
        tax
        lda #0
        +tmsPut
        +tmsPut
        +tmsPut

        lda TMP
        bne +
        txa
        asl
        bra ++
+
        txa
++
        tay
        +tmsPut
        txa
        +tmsPut
        +tmsPut
        +tmsPut
        tya
        +tmsPut
        bra @loop
@doneDraw:

        lda #0
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        
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


gameLoop:
        +nes1BranchIfNotPressed NES_LEFT, +
        lda PADX
        cmp #2
        bcc +
        dec PADX
        dec PADX
+
        +nes1BranchIfNotPressed NES_RIGHT, +
        lda PADX
        clc
        adc PADW
        cmp #253
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
        cmp #255-5
        bcc @doneXCheck
        +negate DIRX
        bra @doneXCheck
@checkLeft
        lda POSX
        cmp #3
        bcs @doneXCheck
        +negate DIRX
@doneXCheck

        bit DIRY
        bmi @checkTop
        lda POSY
        cmp #192-8
        bcc @checkPaddle
        cmp #240
        bcc @doneYCheck
        jsr resetGame
@checkPaddle
        cmp #192-5-5
        bcc  @doneYCheck
        lda POSX
        cmp PADX
        bcc @doneYCheck
        sbc PADW
        cmp PADX
        bcs @doneYCheck
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
        cmp #2
        bcs @doneYCheck
        +negate DIRY
@doneYCheck


        jsr setBallPos


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
        lda #128
        adc SPDX_SUB
        sta SPDX_SUB
        bcc +
        inc SPDX
+
        rts
        
decreaseSpdX:
        sec
        lda SPDX_SUB
        sbc #128
        sta SPDX_SUB
        bcs +
        dec SPDX
        bpl +
        lda #0
        sta SPDX
        +negate DIRX
+
        rts


ballPattern:
!byte $70,$f8,$f8,$f8,$70,$00,$00,$00
!byte $00,$18,$28,$58,$70,$00,$00,$00

paddlePal:
!byte TMS_BLACK,TMS_BLACK,TMS_BLACK,PADDLE_HIGH,PADDLE_BASE,PADDLE_BASE,PADDLE_BASE,PADDLE_SHADE