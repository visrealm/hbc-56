; Troy's HBC-56 - Q*Bert
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

!src "io/timer.inc"


DEBUG=0


; Zero page addresses
; -------------------------
ZP0 = HBC56_USER_ZP_START

QBERT_STATE    = ZP0
QBERT_DIR      = ZP0 + 1
QBERT_ANIM     = ZP0 + 2
QBERT_X        = ZP0 + 3
QBERT_Y        = ZP0 + 4
SCORE_L        = ZP0 + 5
SCORE_M        = ZP0 + 6
SCORE_H        = ZP0 + 7
TMP            = ZP0 + 8
TMP2           = ZP0 + 9
TMP3           = ZP0 + 10
TMP4           = ZP0 + 11
TMP5           = ZP0 + 12
TMP6           = ZP0 + 13
CELL_X         = ZP0 + 14
CELL_Y         = ZP0 + 15
BADBALL_X      = ZP0 + 16
BADBALL_Y      = ZP0 + 17
BADBALL_STATE  = ZP0 + 18
BADBALL_DIR    = ZP0 + 19
BADBALL_ANIM   = ZP0 + 20

COILY_X       = ZP0 + 21
COILY_Y       = ZP0 + 22
COILY_STATE   = ZP0 + 23
COILY_DIR     = ZP0 + 24
COILY_ANIM    = ZP0 + 25

AUDIO_CH0_PCM_STATE = ZP0 + 64
AUDIO_CH0_PCM_ADDR  = AUDIO_CH0_PCM_STATE + 1
AUDIO_CH0_PCM_BYTES = AUDIO_CH0_PCM_STATE + 3

AUDIO_CH1_PCM_STATE = AUDIO_CH0_PCM_STATE + 5
AUDIO_CH1_PCM_ADDR  = AUDIO_CH1_PCM_STATE + 1
AUDIO_CH1_PCM_BYTES = AUDIO_CH1_PCM_STATE + 3

AUDIO_CH2_PCM_STATE = AUDIO_CH1_PCM_STATE + 5
AUDIO_CH2_PCM_ADDR  = AUDIO_CH2_PCM_STATE + 1
AUDIO_CH2_PCM_BYTES = AUDIO_CH2_PCM_STATE + 3


COLOR_TOP1   = TMP
COLOR_TOP2   = TMP2
COLOR_TOP3   = TMP3
COLOR_LEFT   = TMP4
COLOR_RIGHT  = TMP5
COLOR_TMP    = TMP6


; actors
;   - id
;   - typeid
;   - state
;   - facing
;   - 


; cells
;   - x
;   - y
;   - color

; setBlockColors (c1, c2, c3, left, right)


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
        +tmsSetColorFgBg TMS_WHITE, TMS_BLACK

        lda #0
        sta QBERT_STATE
        sta QBERT_DIR
        sta QBERT_ANIM
        sta SCORE_L
        sta SCORE_M
        sta SCORE_H


        jsr clearVram

        +tmsSetPosWrite 0, 0
        +tmsSendData .gameTable, 32*24

        jsr tilesToVram

        +tmsEnableOutput

        +hbc56SetVsyncCallback gameLoop
        +tmsEnableInterrupts

        jsr badBallInit
        jsr coilyInit

        +tmsCreateSprite 0, 12, 120, 7, TMS_DK_RED
        +tmsCreateSprite 1, 16, 120, 10, TMS_BLACK
        +tmsCreateSprite 2, 20, 120, -6, TMS_WHITE

        jsr resetBert

        jsr .bertSpriteRestDR

        jsr audioInit

        +hbc56SetViaCallback timerHandler
        +timer1SetContinuousHz 4096

        cli

        jmp hbc56Stop

timerHandler:
        bit VIA_IO_ADDR_T1C_L
        jsr audioTick
        rts

resetBert:
        lda #120
        sta QBERT_X
        lda #12
        sta QBERT_Y

        lda #14
        sta CELL_X
        lda #2
        sta CELL_Y
        rts

.bertSpriteRestDR:

        lda QBERT_Y
        cmp #170
        bcc +
        jsr resetBert
+

        +tmsSpriteIndex 0, 0
        +tmsSpriteIndex 1, 4
        +tmsSpriteIndex 2, 8
        jmp .updateBertSpriteRest

.bertSpriteJumpDR
        +tmsSpriteIndex 0, 12
        +tmsSpriteIndex 1, 16
        +tmsSpriteIndex 2, 20
        jmp .updateBertSpriteJump

.bertSpriteRestDL:
        lda QBERT_Y
        cmp #170
        bcc +
        jsr resetBert
+

        +tmsSpriteIndex 0, 24
        +tmsSpriteIndex 1, 28
        +tmsSpriteIndex 2, 32
        jmp .updateBertSpriteRest

.bertSpriteJumpDL
        +tmsSpriteIndex 0, 36
        +tmsSpriteIndex 1, 40
        +tmsSpriteIndex 2, 44
        jmp .updateBertSpriteJump



.bertSpriteRestUR:
        +tmsSpriteIndex 0, 48+0
        +tmsSpriteIndex 1, 48+4
        +tmsSpriteIndex 2, 48+8
        jmp .updateBertSpriteRest

.bertSpriteJumpUR
        +tmsSpriteIndex 0, 48+12
        +tmsSpriteIndex 1, 48+16
        +tmsSpriteIndex 2, 48+20
        jmp .updateBertSpriteJump


.bertSpriteRestUL:
        +tmsSpriteIndex 0, 48+24
        +tmsSpriteIndex 1, 48+28
        +tmsSpriteIndex 2, 48+32
        jmp .updateBertSpriteRest

.bertSpriteJumpUL
        +tmsSpriteIndex 0, 48+36
        +tmsSpriteIndex 1, 48+40
        +tmsSpriteIndex 2, 48+44
        jmp .updateBertSpriteJump



.updateBertSpriteRest
        ldx QBERT_X
        ldy QBERT_Y
        +tmsSpritePosXYReg 1
        dey
        dey
        dey
        dey
        dey
        +tmsSpritePosXYReg 0
        lda QBERT_DIR
        bit #2
        clc
        beq +
        sec
+
        tya
        adc #-11
        tay
        +tmsSpritePosXYReg 2
        rts

.updateBertSpriteJump
        ldx QBERT_X
        ldy QBERT_Y
        +tmsSpritePosXYReg 1
        dey
        dey
        dey
        +tmsSpritePosXYReg 0
        lda QBERT_DIR
        bit #2
        clc
        beq +
        sec
+
        tya
        adc #-13
        tay
        +tmsSpritePosXYReg 2
        rts



.updatePos:
!if DEBUG {
        +tmsSetColorFgBg TMS_WHITE, TMS_DK_GREEN
}

        lda QBERT_ANIM
        beq .endAnim
        lda QBERT_ANIM
        dec
        tax

        lda QBERT_DIR
        bit #1
        bne +
        lda QBERT_X
        clc
        adc .bertJumpAnimX,X
        sta QBERT_X
        bra @endX
+
        lda QBERT_X
        sec
        sbc .bertJumpAnimX,X
        sta QBERT_X
@endX
        lda QBERT_DIR
        bit #2
        bne +

        lda QBERT_Y
        clc
        adc .bertJumpAnimY,X
        sta QBERT_Y
        bra @endY
+
        stx TMP
        lda #31
        sec
        sbc TMP
        tax
        lda QBERT_Y
        sec
        sbc .bertJumpAnimY,X
        sta QBERT_Y
@endY:

        jsr .updateBertSpriteJump
.endAnim

        inc QBERT_ANIM
        lda QBERT_ANIM
        cmp #33
        bne @endUpdate

        jsr audioPlayJump

!if DEBUG {
        +tmsSetColorFgBg TMS_WHITE, TMS_DK_BLUE
}
        stz QBERT_STATE
        stz QBERT_ANIM
        lda #$00
        sta TMP
        lda #$25
        jsr scoreAdd
        lda QBERT_DIR
        bne +
        jsr .bertSpriteRestDR
        bra @endSetRestSprite
+
        cmp #1
        bne +
        jsr .bertSpriteRestDL
        bra @endSetRestSprite
+
        cmp #2
        bne +
        jsr .bertSpriteRestUR
        bra @endSetRestSprite
+
        jsr .bertSpriteRestUL

@endSetRestSprite

        bra .updateCell

@endUpdate
        rts

.updateCell:
        lda #8
        sta TMP2
        ldx CELL_X
        ldy CELL_Y
        jsr tmsSetPosRead
        +tmsGet
        bmi +
        rts
+
        pha
        cmp #128+16
        bcc +
        lda #-8
        sta TMP2

+
        +tmsGet
        +tmsGet
        sta TMP
        jsr tmsSetAddressWrite
        pla
        clc
        adc TMP2
        +tmsPut
        inc
        +tmsPut
        
        clc
        lda TMP
        adc TMP2
        +tmsPut
        inc
        +tmsPut


        ldx CELL_X
        ldy CELL_Y
        iny
        jsr tmsSetPosRead
        +tmsGet
        pha
        +tmsGet
        +tmsGet
        sta TMP
        jsr tmsSetAddressWrite

        pla
        clc
        adc TMP2
        +tmsPut
        inc
        +tmsPut
        
        clc
        lda TMP
        adc TMP2
        +tmsPut
        inc
        +tmsPut

@endUpdateCell:
        rts

.bertJumpStart:
        lda #1
        sta QBERT_STATE
        rts

.moveDR:
        lda #0
        sta QBERT_DIR
        jsr .bertJumpStart
        jsr .bertSpriteJumpDR
        inc CELL_Y
        inc CELL_Y
        inc CELL_Y
        inc CELL_X
        inc CELL_X
        jmp .afterControl

.moveDL:
        lda #1
        sta QBERT_DIR
        jsr .bertJumpStart
        jsr .bertSpriteJumpDL
        inc CELL_Y
        inc CELL_Y
        inc CELL_Y
        dec CELL_X
        dec CELL_X
        jmp .afterControl

.moveUR:
        lda #2
        sta QBERT_DIR
        jsr .bertJumpStart
        jsr .bertSpriteJumpUR
        dec CELL_Y
        dec CELL_Y
        dec CELL_Y
        inc CELL_X
        inc CELL_X        
        jmp .afterControl

.moveUL:
        lda #3
        sta QBERT_DIR
        jsr .bertJumpStart
        jsr .bertSpriteJumpUL
        dec CELL_Y
        dec CELL_Y
        dec CELL_Y
        dec CELL_X
        dec CELL_X        
        jmp .afterControl


gameLoop:
!if DEBUG {
        +tmsSetColorFgBg TMS_WHITE, TMS_DK_YELLOW
}
        lda QBERT_STATE
        beq +
        jsr .updatePos
        bra .afterControl
+
        ; test NES controller
        lda NES1_IO_ADDR
        bit #NES_RIGHT
        beq .moveDR
        bit #NES_DOWN
        beq .moveDL
        bit #NES_LEFT
        beq .moveUL
        bit #NES_UP
        beq .moveUR

.afterControl

        jsr platformsTick
        jsr uiTick
        jsr badBallTick
        jsr coilyTick

!if DEBUG {
        +tmsSetColorFgBg TMS_WHITE, TMS_BLACK
}
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

        jsr uiInit
        jsr platformsInit
        jsr blocksInit

        jsr playerInit

        rts        


; 0-95 - bert (96)
;   8x orientations
;   4x 16px
;   3x layers

; coily  (32)
;   6x backgrounds (3x each direction) 2x for large and 1x for small
;   4x 16px
;   + 2x4 for eyes?

; balls (32)
;   3x sizes (small, med, large)
;   2x squish and expanded
;   4x 16px
;   2x4 for shine?

; exclamation (8)


!src "audio.asm"
!src "blocks.asm"
!src "platform.asm"
!src "player.asm"
!src "badball.asm"
!src "coily.asm"
!src "ui.asm"





.gameTable
!text "PLAYER 1"                     ,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,"LEVEL: 1"                     
!text $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,"ROUND: 1"                     
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$81,$82,$83,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$90,$93,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$b4,$b7,$00,$00,$00,$00,$00,$00,$00,$80,$81,$86,$87,$84,$85,$82,$83,$00,$01,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$a8,$ab,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$02,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $05,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $06,$08,$00,$00,$00,$00,$00,$00,$00,$00,$80,$81,$86,$87,$84,$85,$86,$87,$84,$85,$82,$83,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $05,$07,$00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $06,$08,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $05,$07,$00,$00,$00,$01,$03,$00,$80,$81,$86,$87,$84,$85,$86,$87,$84,$85,$86,$87,$84,$85,$82,$83,$00,$01,$03,$00,$00,$00,$00,$00
!byte $06,$08,$00,$00,$00,$02,$04,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$02,$04,$00,$00,$00,$00,$00
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

