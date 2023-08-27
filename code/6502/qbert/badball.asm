
BADBALL_PATT_IDX = 96

BADBALL_START_X = 136
BADBALL_START_Y = 33
BADBALL_HIGHLIGH_OFFSET = 8

badBallInit:
        +tmsSetAddrSpritePattTable BADBALL_PATT_IDX
        +tmsSendData .badBallSquatPatt, 8 * 4 * 3

        lda #0
        sta BADBALL_STATE
        sta BADBALL_DIR
        sta BADBALL_ANIM

        lda #BADBALL_START_X
        sta BADBALL_X
        lda #BADBALL_START_Y
        sta BADBALL_Y

        +tmsCreateSprite 3, BADBALL_PATT_IDX,     BADBALL_START_X, BADBALL_START_Y, TMS_DK_RED
        +tmsCreateSprite 4, BADBALL_PATT_IDX + 8, BADBALL_START_X, BADBALL_START_Y + BADBALL_HIGHLIGH_OFFSET, TMS_WHITE

        jsr .moveBall
        rts

.initJumpCountdown:
        lda #30
        sta BADBALL_STATE
        rts

.initJump:
        dec BADBALL_STATE
        stz BADBALL_ANIM
        +tmsSpriteIndex 3, BADBALL_PATT_IDX + 4
        rts

.jumpTick:
        ldx BADBALL_ANIM

        lda BADBALL_X
        sec
        sbc .bertJumpAnimX,X
        sta BADBALL_X

        lda BADBALL_Y
        clc
        adc .bertJumpAnimY,X
        sta BADBALL_Y

        jsr .moveBall

        inc BADBALL_ANIM
        lda BADBALL_ANIM
        cmp #32
        bne +
        lda #0
        sta BADBALL_STATE
        +tmsSpriteIndex 3, BADBALL_PATT_IDX
        jsr audioPlayBadBallJump
+

        rts

badBallTick:
        lda BADBALL_STATE
        beq .initJumpCountdown
        bmi .jumpTick
        dec BADBALL_STATE
        beq .initJump
        rts

.moveBall:
        ldx BADBALL_X
        ldy BADBALL_Y
        +tmsSpritePosXYReg 3
        tya
        clc
        adc #BADBALL_HIGHLIGH_OFFSET
        tay
        +tmsSpritePosXYReg 4        
        rts




.badBallSquatPatt
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $03,$0f,$1c,$3b,$3f,$3f,$1f,$07
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $e0,$f8,$fc,$fe,$fe,$fe,$fc,$f0

.badBallJumpPatt
!byte $00,$00,$00,$00,$00,$00,$03,$0f
!byte $1c,$3b,$3f,$3f,$3f,$1f,$0f,$03
!byte $00,$00,$00,$00,$00,$00,$e0,$f8
!byte $fc,$fe,$fe,$fe,$fe,$fc,$f8,$e0

.badBallHighlightPatt
!byte $03,$07,$07,$04,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00