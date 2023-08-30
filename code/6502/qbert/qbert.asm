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

RANDOM         = ZP0 + 16


BADBALL_X      = ZP0 + 32
BADBALL_Y      = ZP0 + 33
BADBALL_STATE  = ZP0 + 34
BADBALL_DIR    = ZP0 + 35
BADBALL_ANIM   = ZP0 + 36

COILY_X       = ZP0 + 37
COILY_Y       = ZP0 + 38
COILY_STATE   = ZP0 + 39
COILY_DIR     = ZP0 + 40
COILY_ANIM    = ZP0 + 41

AUDIO_CH0_PCM_STATE = ZP0 + 64
AUDIO_CH0_PCM_ADDR  = AUDIO_CH0_PCM_STATE + 1
AUDIO_CH0_PCM_BYTES = AUDIO_CH0_PCM_STATE + 3

AUDIO_CH1_PCM_STATE = AUDIO_CH0_PCM_STATE + 5
AUDIO_CH1_PCM_ADDR  = AUDIO_CH1_PCM_STATE + 1
AUDIO_CH1_PCM_BYTES = AUDIO_CH1_PCM_STATE + 3

AUDIO_CH2_PCM_STATE = AUDIO_CH1_PCM_STATE + 5
AUDIO_CH2_PCM_ADDR  = AUDIO_CH2_PCM_STATE + 1
AUDIO_CH2_PCM_BYTES = AUDIO_CH2_PCM_STATE + 3

COUNTDOWN_TICKS  = ZP0 + 80

COLOR_TOP1   = TMP
COLOR_TOP2   = TMP2
COLOR_TOP3   = TMP3
COLOR_LEFT   = TMP4
COLOR_RIGHT  = TMP5
COLOR_TMP    = TMP6

RAM_START       = $200

BLOCKS_ADDR = RAM_START + 0
BLOCKS_SIZE = $400

LEVEL           = BLOCKS_ADDR + BLOCKS_SIZE
ROUND           = LEVEL + 1

COUNTDOWN_CALL   = ROUND + 1
COUNTDOWN_CALL_H = COUNTDOWN_CALL + 1
MOVELOOP_CALL    = ROUND + 3
MOVELOOP_CALL_H  = MOVELOOP_CALL + 1



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
        sta COUNTDOWN_CALL_H
        sta COUNTDOWN_CALL
        sta COUNTDOWN_TICKS


        jsr clearVram

        +tmsSetPosWrite 0, 0
        +tmsSendData .levelTable, 32*24

        ;+tmsSetAddressWrite TMS_VRAM_NAME_ADDRESS2
        ;+tmsSendData .levelTable, 32*24

        jsr tilesToVram
        jsr uiInit

PLAYER_START_X = 120
PLAYER_START_Y = 7

        +tmsCreateSprite 0, 12, PLAYER_START_X, PLAYER_START_Y, TMS_DK_RED
        +tmsCreateSprite 1, 16, PLAYER_START_X, PLAYER_START_Y + 3, TMS_BLACK
        +tmsCreateSprite 2, 20, PLAYER_START_X, PLAYER_START_Y - 13, TMS_WHITE

        ;+tmsCreateSprite 7, 256-8, 124, 13, TMS_WHITE
        ;+tmsCreateSprite 8, 256-4, 140, 13, TMS_WHITE

        jsr resetBert

        jsr .bertSpriteRestDR

        jsr audioInit

        +hbc56SetViaCallback timerHandler
        +timer1SetContinuousHz 4096

        +hbc56SetVsyncCallback countdownLoop

        jsr initLevelStart
        
        stz HBC56_SECONDS_L
        stz HBC56_SECONDS_H

        
        +tmsEnableOutput
        +tmsEnableInterrupts

        ; setup complete - nothing else to do
        ; just sit wait for interrupts
        cli
        jmp hbc56Stop

; =============================================================================

!macro onCountdown .ticks, .fn {
        lda #.ticks
        sta COUNTDOWN_TICKS
        lda #<.fn
        sta COUNTDOWN_CALL
        lda #>.fn
        sta COUNTDOWN_CALL_H
}

!macro timerDelay .ticks {
        +onCountdown .ticks, .andThen
        rts
.andThen:
}


doCountdownFn:
        jmp (COUNTDOWN_CALL)

countdownLoop:
        ; handle various countdowns
        lda COUNTDOWN_CALL_H
        beq +
        dec COUNTDOWN_TICKS
        bne +
        jsr doCountdownFn
+
        rts

        ; 1s pause, flash number twice, then number on and start demo jumps

moveLoop:
        lda QBERT_STATE
        beq +
        jsr .updatePos
        +onCountdown 1, moveLoop
        rts
+
        jmp (MOVELOOP_CALL)

!macro doMoveLoop {
        lda #<.andThen
        sta MOVELOOP_CALL
        lda #>.andThen
        sta MOVELOOP_CALL + 1
        jmp moveLoop        
.andThen:
}

initLevelStart:
        +timerDelay 60
        jsr audioPlayLevelStart
        +tmsCreateSprite 3, 256-12, 119, 166, TMS_LT_YELLOW
        +tmsCreateSprite 4, 256-12, 120, 167, TMS_LT_RED
        
        +timerDelay 20
        
        +tmsSpriteColor 3, TMS_TRANSPARENT
        +tmsSpriteColor 4, TMS_TRANSPARENT
        
        +timerDelay 20
        
        +tmsSpriteColor 3, TMS_LT_YELLOW
        +tmsSpriteColor 4, TMS_LT_RED
        
        +timerDelay 20
        
        +tmsSpriteColor 3, TMS_TRANSPARENT
        +tmsSpriteColor 4, TMS_TRANSPARENT
        
        +timerDelay 20
        
        +tmsSpriteColor 3, TMS_LT_YELLOW
        +tmsSpriteColor 4, TMS_LT_RED

        jsr .doMoveDR
        +doMoveLoop

        +timerDelay 2

        jsr .doMoveUL
        +doMoveLoop

        +timerDelay 2

        jsr .doMoveDL
        +doMoveLoop

        +timerDelay 2

        jsr .doMoveUR
        +doMoveLoop

        +timerDelay 30

startGame:

        +tmsDisableOutput

        lda #0
        sta QBERT_STATE
        sta QBERT_DIR
        sta QBERT_ANIM
        sta SCORE_L
        sta SCORE_M
        sta SCORE_H

        jsr .bertSpriteRestDR

        +tmsSpriteColor 3, TMS_TRANSPARENT
        +tmsSpriteColor 4, TMS_TRANSPARENT
        +tmsSpritePos 0, PLAYER_START_X, $d0

        ; everthing paused for a second or so, then life icon disappears and becomes sprite
        ; game starts ~0.5s later

        +tmsSetPosWrite 0, 0
        +tmsSendData .gameTable, 32*24


        jsr uiStartGame

        +tmsEnableOutput

        +timerDelay 60

        +tmsSetPosWrite 0, 11
        lda #0
        +tmsPut
        +tmsPut
        +tmsSetPosWrite 0, 12
        lda #0
        +tmsPut
        +tmsPut

        +tmsSpritePos 0, PLAYER_START_X, PLAYER_START_Y

        +timerDelay 60

        jsr badBallInit
        jsr coilyInit

        +hbc56SetVsyncCallback gameLoop

        rts


timerHandler:
        bit VIA_IO_ADDR_T1C_L
        jsr audioTick

        lda NES1_IO_ADDR
        clc
        adc RANDOM
        sbc HBC56_TICKS
        sta RANDOM
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

.doMoveDR:
        lda #0
        sta QBERT_DIR
        jsr .bertJumpStart
        jsr .bertSpriteJumpDR
        inc CELL_Y
        inc CELL_Y
        inc CELL_Y
        inc CELL_X
        inc CELL_X
        rts

.doMoveDL:
        lda #1
        sta QBERT_DIR
        jsr .bertJumpStart
        jsr .bertSpriteJumpDL
        inc CELL_Y
        inc CELL_Y
        inc CELL_Y
        dec CELL_X
        dec CELL_X
        rts

.doMoveUR:
        lda #2
        sta QBERT_DIR
        jsr .bertJumpStart
        jsr .bertSpriteJumpUR
        dec CELL_Y
        dec CELL_Y
        dec CELL_Y
        inc CELL_X
        inc CELL_X        
        rts

.doMoveUL:
        lda #3
        sta QBERT_DIR
        jsr .bertJumpStart
        jsr .bertSpriteJumpUL
        dec CELL_Y
        dec CELL_Y
        dec CELL_Y
        dec CELL_X
        dec CELL_X        
        rts


.moveUL:
        jsr .doMoveUL
        jmp .afterControl

.moveUR:
        jsr .doMoveUR
        jmp .afterControl

.moveDL:
        jsr .doMoveDL
        jmp .afterControl

.moveDR:
        jsr .doMoveDR
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
        jsr blocksTick

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


.levelTable
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$81,$82,$83,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$81,$86,$87,$84,$85,$82,$83,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a8,$a9,$84,$85,$86,$87,$aa,$ab,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a4,$a5,$a6,$a7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a8,$a9,$aa,$ab,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$88,$89,$fd,$00,$88,$89,$fd,$fd,$fd,$88,$89,$00,$00,$8a,$8b,$fd,$fd,$fd,$8a,$8b,$8a,$8b,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$fe,$fd,$fd,$00,$fe,$fe,$fe,$fe,$fb,$fe,$fd,$00,$00,$fd,$ff,$fd,$ff,$ff,$ff,$ff,$fd,$ff,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$fe,$fd,$fd,$00,$fe,$fd,$fd,$fd,$00,$fe,$fd,$00,$00,$fd,$ff,$fd,$ff,$8a,$8b,$00,$fd,$ff,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$fe,$fd,$fd,$00,$fe,$fe,$fe,$fb,$00,$fe,$fd,$8b,$88,$fd,$ff,$fd,$ff,$ff,$ff,$00,$fd,$ff,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$fe,$fd,$fd,$fd,$fe,$fd,$fd,$fd,$fd,$fe,$ad,$fd,$fd,$ae,$ff,$fd,$ff,$fd,$8a,$8b,$fd,$ff,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$fe,$fe,$fe,$fb,$fe,$fe,$fe,$fe,$fb,$a8,$a9,$ac,$af,$aa,$ab,$fc,$ff,$ff,$ff,$ff,$fc,$ff,$ff,$ff,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$a8,$ab,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$c0,$c1,$c2,$c3,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$c4,$00,$00,$c5,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$c6,$00,$00,$c7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$c8,$c9,$ca,$cb,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


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


!warn "Total binary size: ", *-$8000