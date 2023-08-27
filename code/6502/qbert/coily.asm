
COILY_PATT_IDX = 108

COILY_START_X = 104
COILY_START_Y = 33
COILY_HIGHLIGH_OFFSET = 6

coilyInit:
        +tmsSetAddrSpritePattTable COILY_PATT_IDX
        +tmsSendData .coilyEggSquatPatt, 8 * 4 * 3

        lda #0
        sta COILY_STATE
        sta COILY_DIR
        sta COILY_ANIM

        lda #COILY_START_X
        sta COILY_X
        lda #COILY_START_Y
        sta COILY_Y

        +tmsCreateSprite 5, COILY_PATT_IDX,     COILY_START_X, COILY_START_Y, TMS_MAGENTA
        +tmsCreateSprite 6, COILY_PATT_IDX + 8, COILY_START_X, COILY_START_Y + COILY_HIGHLIGH_OFFSET, TMS_WHITE

        jsr .moveBall
        rts

.initCoilyJumpCountdown:
        lda #33
        sta COILY_STATE
        rts

.initCoilyJump:
        dec COILY_STATE
        stz COILY_ANIM
        +tmsSpriteIndex 5, COILY_PATT_IDX + 4
        rts

.jumpCoilyTick:
        ldx COILY_ANIM

        lda COILY_X
        clc
        adc .bertJumpAnimX,X
        sta COILY_X

        lda COILY_Y
        clc
        adc .bertJumpAnimY,X
        sta COILY_Y

        jsr .moveCoily

        inc COILY_ANIM
        lda COILY_ANIM
        cmp #32
        bne +
        lda #0
        sta COILY_ANIM
        sta COILY_STATE
        +tmsSpriteIndex 5, COILY_PATT_IDX
        jsr .moveCoily
        jsr audioPlayCoilyEggJump
+

        rts

coilyTick:
        lda COILY_STATE
        beq .initCoilyJumpCountdown
        bmi .jumpCoilyTick
        dec COILY_STATE
        beq .initCoilyJump
        rts

.moveCoily:
        ldx COILY_X
        ldy COILY_Y
        +tmsSpritePosXYReg 5
        tya
        clc
        adc #COILY_HIGHLIGH_OFFSET
        ldy COILY_ANIM
        beq +
        dec
+                
        tay
        +tmsSpritePosXYReg 6        
        rts




.coilyEggSquatPatt
!byte $00,$00,$00,$00,$00,$00,$07,$1f
!byte $38,$73,$ef,$ff,$ff,$7f,$3f,$0f
!byte $00,$00,$00,$00,$00,$00,$e0,$f8
!byte $fc,$fe,$ff,$ff,$ff,$fe,$fc,$f0

.coilyEggJumpPatt
!byte $00,$00,$00,$07,$1f,$38,$73,$ef
!byte $ff,$ff,$ff,$ff,$7f,$3f,$1f,$07
!byte $00,$00,$00,$e0,$f8,$fc,$fe,$ff
!byte $ff,$ff,$ff,$ff,$fe,$fc,$f8,$e0

.coilyHighlightPatt
!byte $07,$0f,$1f,$1f,$18,$10,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00


.greenBallSquatPatt
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$03,$0f,$1d,$1b,$1f,$0f
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$c0,$f0,$f8,$f8,$f8,$f0

.greenBallJumpPatt
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $03,$0f,$1d,$1b,$1f,$1f,$0f,$03
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $c0,$f0,$f8,$f8,$f8,$f8,$f0,$c0