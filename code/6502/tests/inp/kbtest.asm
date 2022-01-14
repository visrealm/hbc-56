; Troy's HBC-56 - Input test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!src "hbc56kernel.inc"

Y_OFFSET          = 4

hbc56Meta:
        +setHbcMetaTitle "KEYBOARD TEST"
        rts

hbc56Main:
        jsr tmsModeGraphicsI

        lda #TMS_R1_SPRITE_MAG2
        jsr tmsReg1ClearFields
        lda #TMS_R1_SPRITE_16
        jsr tmsReg1SetFields

        +tmsSetAddrColorTable
        +tmsSendData colorTab, 32
        
        +tmsSetAddrNameTable
        lda #$fe
        jsr _tmsSendPage
        jsr _tmsSendPage
        jsr _tmsSendPage

        +tmsSetAddrPattTable
        +tmsSendData keyboardPatt, 256*8

        +tmsSetPosWrite 0, Y_OFFSET
        +tmsSendData keyboardInd, 512

        +tmsSetAddrSpritePattTable
        +tmsSendData sprites, 4*8

        +tmsCreateSprite 0, 0, 39, Y_OFFSET*8+39, TMS_DK_GREEN


        +tmsEnableOutput

        +hbc56SetVsyncCallback inputLoop

        cli
        +tmsEnableInterrupts

        jmp hbc56Stop


inputLoop:
	rts

colorTab:
!byte $4f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f
!byte $1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f

keyboardInd:
!bin "keyboard.ind"
keyboardIndEnd:

keyboardPatt:
!bin "keyboard.patt"
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
keyboardPattEnd:

sprites:
!byte $ff,$80,$80,$80,$80,$80,$80,$80   ; 14x15  $00
!byte $80,$80,$80,$80,$80,$80,$ff,$00
!byte $fc,$04,$04,$04,$04,$04,$04,$04
!byte $04,$04,$04,$04,$04,$04,$fc,$00
