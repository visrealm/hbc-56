
COILY_PATT_IDX = 108

COILY_MAIN_SPRITE_NUMBER      = 4
COILY_HIGHLIGHT_SPRITE_NUMBER = 6

COILY_JUMP_DELAY     = 33

COILY_START_X = 104
COILY_START_Y = 33
COILY_HIGHLIGH_OFFSET = 6

coilyInit:
        +tmsSetAddrSpritePattTable COILY_PATT_IDX
        +tmsSendData .coilyEggSquatPatt, 8 * 4 * 3

        +tmsSendData .coilySquatDLPatt, 8 * 4 * 3

        +tmsSendData .coilyJumpLBottomPatt, 8 * 4 * 3

        lda #0
        sta COILY_STATE
        sta COILY_DIR
        sta COILY_ANIM

        lda #COILY_START_X
        sta COILY_X
        lda #COILY_START_Y
        sta COILY_Y

        +tmsCreateSprite COILY_MAIN_SPRITE_NUMBER, COILY_PATT_IDX,     COILY_START_X, COILY_START_Y, TMS_MAGENTA
        +tmsCreateSprite COILY_HIGHLIGHT_SPRITE_NUMBER, COILY_PATT_IDX + 8, COILY_START_X, COILY_START_Y + COILY_HIGHLIGH_OFFSET, TMS_WHITE


        +tmsCreateSprite 7, COILY_PATT_IDX + 12, COILY_START_X,      48 + COILY_START_Y, TMS_MAGENTA
        +tmsCreateSprite 8, COILY_PATT_IDX + 16, COILY_START_X,     48 + COILY_START_Y, TMS_BLACK
        +tmsCreateSprite 9, COILY_PATT_IDX + 20, COILY_START_X - 9, 48 + COILY_START_Y - 8, TMS_WHITE

        +tmsCreateSprite 10, COILY_PATT_IDX + 24, 32+ COILY_START_X,     96 + COILY_START_Y, TMS_MAGENTA
        +tmsCreateSprite 11, COILY_PATT_IDX + 28, 32+ COILY_START_X,     80 + COILY_START_Y, TMS_MAGENTA
        +tmsCreateSprite 12, COILY_PATT_IDX + 32, 32+ COILY_START_X - 8, 80 + COILY_START_Y - 13, TMS_BLACK
        +tmsCreateSprite 13, COILY_PATT_IDX + 20, 32+ COILY_START_X - 9, 80 + COILY_START_Y - 8, TMS_WHITE

        jsr .moveBall
        rts

.initCoilyJump:
        lda COILY_Y
        cmp #150
        bcc +
        inc COILY_STATE
        rts
+
        dec COILY_STATE
        stz COILY_ANIM
        +tmsSpriteIndex COILY_MAIN_SPRITE_NUMBER, COILY_PATT_IDX + 4
        lda RANDOM
        and #2
        sta COILY_DIR

        rts

.jumpCoilyTick:
        ldx COILY_ANIM

        lda COILY_DIR
        beq @moveRight
        lda COILY_X
        sec
        sbc .bertJumpAnimX,X
        sta COILY_X
        bra @afterMoveX

@moveRight:
        lda COILY_X
        clc
        adc .bertJumpAnimX,X
        sta COILY_X
@afterMoveX:

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
        +tmsSpriteIndex COILY_MAIN_SPRITE_NUMBER, COILY_PATT_IDX
        jsr .moveCoily
        jsr audioPlayCoilyEggJump
+

        rts

coilyTick:

        lda COILY_STATE
        beq .initCoilyJumpCountdown
        bmi .jumpCoilyTick
        dec COILY_STATE
        bne +
        jmp .initCoilyJump
+ 
        rts

.initCoilyJumpCountdown:
        lda #COILY_JUMP_DELAY
        sta COILY_STATE
        rts

.moveCoily:
        ldx COILY_X
        ldy COILY_Y
        +tmsSpritePosXYReg COILY_MAIN_SPRITE_NUMBER
        tya
        clc
        adc #COILY_HIGHLIGH_OFFSET
        ldy COILY_ANIM
        beq +
        dec
+                
        tay
        +tmsSpritePosXYReg COILY_HIGHLIGHT_SPRITE_NUMBER
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


.coilySquatDRPatt
!byte $01,$03,$07,$0f,$1c,$1e,$1f,$0f
!byte $1f,$1d,$1e,$0f,$1f,$3f,$31,$10
!byte $ec,$fe,$c0,$e2,$ff,$7f,$be,$fc
!byte $fc,$fc,$fc,$1c,$f8,$f0,$e0,$00

.coilySquatBlackDRPatt:
!byte $00,$00,$00,$00,$03,$01,$00,$00
!byte $00,$02,$01,$00,$00,$00,$00,$00
!byte $00,$00,$14,$00,$00,$80,$40,$00
!byte $00,$00,$00,$e0,$00,$00,$00,$00


.coilySquatDLPatt
!byte $37,$7f,$03,$47,$ff,$fe,$7d,$17
!byte $3f,$3f,$3f,$38,$1f,$0f,$07,$00
!byte $80,$c0,$e0,$f0,$38,$78,$f8,$f0
!byte $f8,$b8,$78,$f0,$f8,$fc,$8c,$08

.coilySquatBlackDLPatt:
!byte $00,$00,$28,$00,$00,$01,$02,$00
!byte $00,$00,$00,$07,$00,$00,$00,$00
!byte $00,$00,$00,$00,$c0,$80,$00,$00
!byte $00,$40,$80,$00,$00,$00,$00,$00

.coilyFaceWhitePatt:    ; eyes and teeth (only BR pattern used. could combine with one where only top pattern(s) used)
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$2a,$1c,$00,$00,$00,$14




.coilyJumpRBottomPatt:
!byte $7f,$78,$f0,$f1,$f3,$ff,$7f,$3f
!byte $1f,$3f,$3c,$3c,$3c,$1e,$0f,$07
!byte $f8,$e0,$00,$fc,$fe,$fe,$1e,$fe
!byte $fc,$f0,$00,$00,$08,$18,$f0,$c0

.coilyJumpDRTopPatt:
!byte $00,$00,$07,$0f,$3f,$3f,$7c,$78
!byte $f0,$f0,$fb,$7f,$7f,$3f,$3f,$3f
!byte $6c,$fe,$c0,$e2,$ff,$ff,$3e,$00
!byte $00,$f0,$fc,$fe,$9f,$1f,$fe,$fc

.coilyJumpLBottomPatt:
!byte $1f,$07,$00,$3f,$7f,$7f,$78,$7f
!byte $3f,$0f,$00,$00,$10,$18,$0f,$03
!byte $fe,$1e,$0f,$8f,$cf,$ff,$fe,$fc
!byte $f8,$fc,$3c,$3c,$3c,$78,$f0,$e0

.coilyJumpDLTopPatt:
!byte $36,$7f,$03,$47,$ff,$ff,$7c,$00
!byte $00,$0f,$3f,$7f,$f9,$f8,$7f,$3f
!byte $00,$00,$e0,$f0,$fc,$fc,$3e,$1e
!byte $0f,$0f,$df,$fe,$fe,$fc,$fc,$fc

.coilyJumpDTopBlackPatt:        ; eye balls (in bottom-right quadrant)
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$28




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