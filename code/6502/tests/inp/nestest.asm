; Troy's HBC-56 - Input test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!src "hbc56kernel.inc"

Y_OFFSET          = 10

hbc56Meta:
        +setHbcMetaTitle "NES CARD TEST"
        +setHbcMetaNES
        rts

hbc56Main:
        jsr tmsModeGraphicsI

        lda #TMS_R1_SPRITE_MAG2
        jsr tmsReg1ClearFields
        lda #TMS_R1_SPRITE_16
        jsr tmsReg1SetFields

        +tmsSetAddrColorTable
        +tmsSendData colorTab, 32
        
        +tmsSetAddrPattTable 128
        +tmsSendData brownWhite, 8*8

        +tmsSetAddrPattTable 128+8
        +tmsSendData blackBrown, 32*8

        +tmsSetAddrPattTable 128+40
        +tmsSendData greyBlack, 16*8

        +tmsSetAddrPattTable 128+56
        +tmsSendData greenBlack, 8*8

        +tmsSetAddrPattTable 128+64
        +tmsSendData greenBrown, 8*8

        +tmsSetAddrSpritePattTable
        +tmsSendData sprites, 12*8

        +tmsPrint "NES PORT A", 3, Y_OFFSET-2

        +tmsCreateSprite 0, 0, 48, Y_OFFSET*8+23, TMS_DK_RED
        +tmsCreateSprite 1, 4, 64, Y_OFFSET*8+23, TMS_DK_RED
        +tmsCreateSprite 2, 8, 88, Y_OFFSET*8+39, TMS_DK_RED
        +tmsCreateSprite 3, 8, 100, Y_OFFSET*8+39, TMS_DK_RED

        +tmsPrint "NES PORT B", 16+3, Y_OFFSET-2

        +tmsCreateSprite 4, 0, 128+48, Y_OFFSET*8+23, TMS_DK_RED
        +tmsCreateSprite 5, 4, 128+64, Y_OFFSET*8+23, TMS_DK_RED
        +tmsCreateSprite 6, 8, 128+88, Y_OFFSET*8+39, TMS_DK_RED
        +tmsCreateSprite 7, 8, 128+100, Y_OFFSET*8+39, TMS_DK_RED


        +tmsSetPosWrite 0, Y_OFFSET
        !for i, 8 {
                +tmsSendData controller + ((i-1)*16), 16
                +tmsSendData controller + ((i-1)*16), 16
        }

        +tmsPrint "HBC-56  NES CONTROLLER CARD TEST", 0, 1

        +tmsEnableOutput

        +hbc56SetVsyncCallback inputLoop

        cli
        +tmsEnableInterrupts

        jmp hbc56Stop

!macro testButton1 .nesBtn, .x, .y, .offInd, .onInd {
        +tmsSetPosWrite .x, .y
        lda #.offInd
        +nes1BranchIfNotPressedSafe .nesBtn, +
        lda #.onInd
+
        +tmsPut
}

!macro testButton2 .nesBtn, .x, .y, .offInd, .onInd {
        +tmsSetPosWrite .x, .y
        lda #.offInd
        +nes2BranchIfNotPressedSafe .nesBtn, +
        lda #.onInd
+
        +tmsPut
}

inputLoop:
        +testButton1 NES_UP, 3, Y_OFFSET+3, BTN_UP, BTN_UP_SEL
        +testButton1 NES_LEFT, 2, Y_OFFSET+4, BTN_LEFT, BTN_LEFT_SEL
        +testButton1 NES_RIGHT, 4, Y_OFFSET+4, BTN_RIGHT, BTN_RIGHT_SEL
        +testButton1 NES_DOWN, 3, Y_OFFSET+5, BTN_DOWN, BTN_DOWN_SEL
        +testButton1 NES_SELECT, 6, Y_OFFSET+5, BTN_STAL, BTN_STAL_SEL
        +testButton1 NES_SELECT, 7, Y_OFFSET+5, BTN_STAR, BTN_STAR_SEL
        +testButton1 NES_START, 8, Y_OFFSET+5, BTN_STAL, BTN_STAL_SEL
        +testButton1 NES_START, 9, Y_OFFSET+5, BTN_STAR, BTN_STAR_SEL

        +tmsSpriteColor 2, TMS_DK_RED
        +nes1BranchIfNotPressed NES_B, +
        +tmsSpriteColor 2, TMS_DK_GREEN
+
        +tmsSpriteColor 3, TMS_DK_RED
        +nes1BranchIfNotPressed NES_A, +
        +tmsSpriteColor 3, TMS_DK_GREEN
+


        +testButton2 NES_UP, 16+3, Y_OFFSET+3, BTN_UP, BTN_UP_SEL
        +testButton2 NES_LEFT, 16+2, Y_OFFSET+4, BTN_LEFT, BTN_LEFT_SEL
        +testButton2 NES_RIGHT, 16+4, Y_OFFSET+4, BTN_RIGHT, BTN_RIGHT_SEL
        +testButton2 NES_DOWN, 16+3, Y_OFFSET+5, BTN_DOWN, BTN_DOWN_SEL
        +testButton2 NES_SELECT, 16+6, Y_OFFSET+5, BTN_STAL, BTN_STAL_SEL
        +testButton2 NES_SELECT, 16+7, Y_OFFSET+5, BTN_STAR, BTN_STAR_SEL
        +testButton2 NES_START, 16+8, Y_OFFSET+5, BTN_STAL, BTN_STAL_SEL
        +testButton2 NES_START, 16+9, Y_OFFSET+5, BTN_STAR, BTN_STAR_SEL

        +tmsSpriteColor 6, TMS_DK_RED
        +nes2BranchIfNotPressed NES_B, +
        +tmsSpriteColor 6, TMS_DK_GREEN
+
        +tmsSpriteColor 7, TMS_DK_RED
        +nes2BranchIfNotPressed NES_A, +
        +tmsSpriteColor 7, TMS_DK_GREEN
+

	rts

BTN_UP          = $ae
BTN_LEFT        = $af
BTN_RIGHT       = $b0
BTN_DOWN        = $b1
BTN_STAL        = $9f
BTN_STAR        = $a0

BTN_UP_SEL      = $b8
BTN_LEFT_SEL    = $b9
BTN_RIGHT_SEL   = $ba
BTN_DOWN_SEL    = $bb
BTN_STAL_SEL    = $c0
BTN_STAR_SEL    = $c1

colorTab:
!byte $f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4,$f4
!byte $b4,$1b,$1b,$1b,$1b,$e1,$e1,$c1,$cb,$f4,$f4,$f4,$f4,$f4,$f4,$f4

controller:
!byte $80,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$80
!byte $82,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$83
!byte $82,$8f,$88,$99,$88,$88,$a8,$a9,$a9,$aa,$88,$88,$88,$88,$90,$83
!byte $82,$8c,$97,$ae,$9b,$88,$a8,$a9,$a9,$aa,$88,$88,$88,$88,$8d,$83
!byte $82,$98,$af,$b2,$b0,$9c,$ab,$ac,$ac,$ad,$88,$8a,$8a,$8b,$8d,$83
!byte $82,$8c,$9a,$b1,$9d,$9e,$9f,$a0,$9f,$a0,$96,$85,$85,$95,$8d,$83
!byte $82,$91,$8e,$93,$8e,$8e,$93,$93,$93,$93,$8e,$93,$93,$94,$92,$83
!byte $80,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$80

brownWhite:
!byte $00,$00,$00,$00,$00,$00,$00,$00   ; $80
!byte $00,$00,$00,$00,$00,$00,$00,$ff   ; $81
!byte $01,$01,$01,$01,$01,$01,$01,$01   ; $82
!byte $80,$80,$80,$80,$80,$80,$80,$80   ; $83
!byte $ff,$00,$00,$00,$00,$00,$00,$00   ; $84
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff   ; $85

blackBrown:
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff   ; $88
!byte $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff   ; $89
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00   ; $8a
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$0f   ; $8b
!byte $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f   ; $8c
!byte $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc   ; $8d
!byte $ff,$ff,$ff,$ff,$ff,$ff,$00,$00   ; $8e
!byte $1f,$3f,$3f,$3f,$3f,$3f,$3f,$3f   ; $8f
!byte $f8,$fc,$fc,$fc,$fc,$fc,$fc,$fc   ; $90
!byte $3f,$3f,$3f,$3f,$3f,$1f,$00,$00   ; $91
!byte $fc,$fc,$fc,$fc,$fc,$f8,$00,$00   ; $92
!byte $00,$ff,$ff,$ff,$ff,$ff,$00,$00   ; $93
!byte $0f,$ff,$ff,$ff,$ff,$ff,$00,$00   ; $94
!byte $07,$07,$07,$07,$07,$07,$07,$07   ; $95
!byte $fe,$7e,$7e,$7e,$7e,$7e,$7e,$7e   ; $96
!byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$01   ; $97
!byte $3e,$3e,$3e,$3e,$3e,$3e,$3e,$3e   ; $98
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00   ; $99
!byte $01,$fe,$fe,$fe,$fe,$fe,$fe,$fe   ; $9a
!byte $7f,$7f,$7f,$7f,$7f,$7f,$7f,$80   ; $9b
!byte $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f   ; $9c
!byte $80,$7f,$7f,$7f,$7f,$7f,$7f,$7f   ; $9d
!byte $ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe   ; $9e
!byte $00,$00,$00,$0f,$1f,$0f,$00,$00   ; $9f
!byte $00,$00,$00,$f0,$f8,$f0,$00,$00   ; $a0

greyBlack:
!byte $ff,$ff,$ff,$ff,$ff,$7f,$00,$7f   ; $a8
!byte $ff,$ff,$ff,$ff,$ff,$ff,$00,$ff   ; $a9
!byte $ff,$ff,$ff,$ff,$ff,$fe,$00,$fe   ; $aa
!byte $ff,$ff,$ff,$ff,$ff,$7f,$00,$00   ; $ab
!byte $ff,$ff,$ff,$ff,$ff,$ff,$00,$00   ; $ac
!byte $ff,$ff,$ff,$ff,$ff,$fe,$00,$00   ; $ad
!byte $00,$18,$3c,$7e,$18,$18,$18,$00   ; $ae
!byte $00,$10,$30,$7e,$7e,$30,$10,$00   ; $af
!byte $00,$08,$0c,$7e,$7e,$0c,$08,$00   ; $b0
!byte $00,$18,$18,$18,$7e,$3c,$18,$00   ; $b1
!byte $00,$18,$3c,$7e,$7e,$3c,$18,$00   ; $b2

greenBlack:
!byte $00,$18,$3c,$7e,$18,$18,$18,$00   ; $b8
!byte $00,$10,$30,$7e,$7e,$30,$10,$00   ; $b9
!byte $00,$08,$0c,$7e,$7e,$0c,$08,$00   ; $ba
!byte $00,$18,$18,$18,$7e,$3c,$18,$00   ; $bb

greenBrown:
!byte $00,$00,$00,$0f,$1f,$0f,$00,$00   ; $c0
!byte $00,$00,$00,$f0,$f8,$f0,$00,$00   ; $c1


sprites:
!byte $00,$00,$00,$00,$00,$00,$00,$00   ; SEL  $00
!byte $3b,$22,$3b,$0a,$3b,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $a0,$20,$20,$20,$b8,$00,$00,$00

!byte $00,$00,$00,$00,$00,$00,$00,$00   ; STA  $04
!byte $3b,$21,$39,$09,$39,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $b8,$28,$38,$28,$28,$00,$00,$00

!byte $3c,$7e,$ff,$ff,$ff,$ff,$7e,$3c   ; A/B  $08
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
