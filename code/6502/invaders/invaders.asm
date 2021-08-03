!to "invaders.o", plain

HBC56_INT_VECTOR = onVSync

!source "../lib/hbc56.asm"

TMS_MODEL = 9929
!source "../lib/gfx/tms9918.asm"
!source "../lib/gfx/fonts/tms9918font1.asm"

!source "../lib/gfx/bitmap.asm"
!source "../lib/inp/nes.asm"
!source "../lib/ut/memory.asm"

TICKS_L = $48
TICKS_H = $49
V_SYNC  = $4a

FRAMES_PER_ANIM = 10
MAX_X           = 6

FRAMES_COUNTER = $4f
ANIM_FRAME     = $50 ; 0, 1, 2, 3, 0, 1, 2, 3
MOVE_FRAME     = $51 ; 0, 0, 0, 0, 1, 1, 1, 1, 
X_POSITION     = $52
Y_POSITION     = $53
TMP_X_POSITION = $54
TMP_Y_POSITION = $55
TMP_GAMEFIELD_OFFSET = $56
X_DIR = $57
Y_DIR = $58
PLAYER_X = $59

BULLET_X = $5a
BULLET_Y = $5b

HIT_TILE_X = $5c
HIT_TILE_Y = $5d
HIT_TILE_PIX_X = $5e
HIT_TILE_PIX_Y = $5f


; contants
BULLET_Y_LOADED = $D0
BULLET_SPEED = 4

GAMEFIELD = $1000

GAME_COLS = 11
GAME_ROWS  = 5

initialGameField:
!byte 160,160,160,160,144,160,160,160,160,160,160
!byte 144,144,144,144,144,144,144,144,144,144,144
!byte 144,144,144,144,144,160,144,144,144,144,144
!byte 128,128,128,128,128,128,128,128,128,128,128
!byte 128,128,128,128,128,128,128,128,128,128,128

; X/Y indexes as pixel location
; returns:
;  TILE in HIT_TILE_X/HIT_TILE_Y
;  TILE OFFSET in HIT_TILE_PIX_X/HIT_TILE_PIX_Y
pixelToTileXy
        txa
        lsr
        lsr
        lsr
        sta HIT_TILE_X
        txa
        and #$03
        sta HIT_TILE_PIX_X
        tya
        lsr
        lsr
        lsr
        sta HIT_TILE_Y
        tya
        and #$03
        sta HIT_TILE_PIX_Y
        rts




onVSync:
        pha
        lda TICKS_L
        clc
        adc #1
        cmp #TMS_FPS
        bne +
        lda #0
        inc TICKS_H
+  
        sta TICKS_L
        lda #1
        sta V_SYNC
        +tmsReadStatus
        pla      
        rti


main:

        sei
        +memcpy GAMEFIELD, initialGameField, 11 * 5

        lda BULLET_Y_LOADED
        sta BULLET_Y

        lda #0
        sta ANIM_FRAME
        sta MOVE_FRAME
        sta FRAMES_COUNTER
        sta Y_DIR

        lda #1
        sta X_POSITION
        sta X_DIR
        lda #4
        sta Y_POSITION

        jsr tmsInit

        lda #TMS_R1_SPRITE_MAG2
        jsr tmsReg1ClearFields
        lda #TMS_R1_SPRITE_16
        jsr tmsReg1SetFields

        +tmsCreateSpritePatternQuad 0, playerSprite
        +tmsCreateSprite 0, 0, 100, 160, TMS_LT_BLUE
        +tmsCreateSpritePatternQuad 1, bulletSprite
        +tmsCreateSprite 1, 4, 100, BULLET_Y_LOADED, TMS_WHITE

        lda #100
        sta PLAYER_X

        +tmsSetAddrColorTable
        +tmsSendData COLORTAB, 32

        +tmsSetAddrFontTableInd 128
        +tmsSendData INVADER1, 16 * 8 * 3  ; first 3 invaders

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground


        +tmsPrint "SCORE 00000   HI SCORE 00000", 2, 0

        lda #0
        sta V_SYNC
        cli

        +tmsEnableInterrupts

.loop:
        lda V_SYNC
        beq .loop
        jsr nextFrame


        +nesBranchIfNotPressed NES_B, +
        lda BULLET_Y
        cmp #BULLET_Y_LOADED
        bne +
        lda PLAYER_X
        clc
        adc #4
        tax
        stx BULLET_X
        ldy #164
        sty BULLET_Y
        +tmsSpritePosXYReg 1
+

        +nesBranchIfNotPressed NES_LEFT, +
        dec PLAYER_X
        dec PLAYER_X
+
        +nesBranchIfNotPressed NES_RIGHT, +
        inc PLAYER_X
        inc PLAYER_X
+

        lda BULLET_Y
        cmp #BULLET_Y_LOADED
        beq +
        sec
        sbc #BULLET_SPEED
        tay
        sty BULLET_Y
        ldx BULLET_X
        +tmsSpritePosXYReg 1
        jsr pixelToTileXy


        cpy #16
        bcs +
        ldy #BULLET_Y_LOADED
        sty BULLET_Y
        +tmsSpritePosXYReg 1
+

        ldx PLAYER_X
        ldy #160
        +tmsSpritePosXYReg 0

        lda #0
        sta Y_DIR

        lda #0
        sta V_SYNC

        inc FRAMES_COUNTER
        lda FRAMES_COUNTER
        cmp #FRAMES_PER_ANIM
        bne .goLoop

        lda #0
        sta FRAMES_COUNTER

        lda ANIM_FRAME
        clc
        adc X_DIR
        sta ANIM_FRAME
        cmp #255
        beq +
        cmp #4
        beq +
.goLoop
        jmp .loop        
+
        lda ANIM_FRAME
        and #$03
        sta ANIM_FRAME

        lda X_POSITION
        clc
        adc X_DIR
        sta X_POSITION
        cmp #6
        bne +
        lda #5
        sta X_POSITION
        lda #-1
        sta X_DIR
        lda #3
        sta ANIM_FRAME
        lda #1
        sta Y_DIR
        jmp .loop
+ 
        cmp #0
        bne +
        lda #1
        sta X_POSITION
        lda #1
        sta X_DIR
        lda #0
        sta ANIM_FRAME
        lda #1
        sta Y_DIR
+ 
        jmp .loop

; Called each frame (on VSYNC)
nextFrame:

        lda #0
        sta TMP_X_POSITION
        sta TMP_Y_POSITION
        sta TMP_GAMEFIELD_OFFSET

.startRow
        lda TMP_X_POSITION
        clc
        adc X_POSITION
        tax

        lda TMP_Y_POSITION
        asl
        clc
        adc Y_POSITION
        tay
        jsr tmsSetPos
        lda #32
        sta TMS9918_RAM
        +tmsWait
-
        lda Y_DIR
        beq +
        ldx TMP_GAMEFIELD_OFFSET
        lda initialGameField, x
        clc
        adc #10
        jmp ++
+
        ldx TMP_GAMEFIELD_OFFSET
        lda initialGameField, x
        clc
        adc ANIM_FRAME
        adc ANIM_FRAME
++
        sta TMS9918_RAM
        +tmsWait
        clc
        adc #1
        sta TMS9918_RAM
        +tmsWait
+

        inc TMP_GAMEFIELD_OFFSET
        inc TMP_X_POSITION
        lda TMP_X_POSITION
        cmp #GAME_COLS
        bne -
        lda #32
        sta TMS9918_RAM
        +tmsWait
        lda #0
        sta TMP_X_POSITION
        inc TMP_Y_POSITION
        lda TMP_Y_POSITION
        cmp #GAME_ROWS
        bne .startRow
        rts


medDelay:
	jsr delay
	jsr delay


delay:
	ldx #255
	ldy #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts

COLORTAB:
       !byte $00,$00,$00,$00
       !byte $F0,$F0,$F0,$00      ; SHIELDS
       !byte $F0,$F0            ; NUMBERS
       !byte $F0,$F0,$F0,$F0      ; LETTERS
       !byte $00,$00
;       !byte $30,$30            ; INVADER 3
;       !byte $50,$50            ; INVADER 2
;       !byte $60,$60            ; INVADER 1
       !byte $40,$40            ; INVADER 3
       !byte $50,$50            ; INVADER 2
       !byte $70,$70            ; INVADER 1
       !byte $40,$00            ; BOTTOM SCREEN
       !byte $00,$00,$00,$00      ; TOP SCREEN
       !byte $00,$00            ; TOP SCREEN

playerSprite:
       !byte $00,$00,$00,$00,$00,$00,$08,$08
       !byte $08,$08,$1C,$7F,$FF,$FF,$FF,$63
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$00,$80,$80,$80,$00

bulletSprite:
       !byte $80,$80,$80,$80,$80,$00,$00,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00


INVADER1:
IP10L  !byte $1E,$FF,$CC,$FF,$FF,$12,$21,$C0
IP10R  !byte $00,$C0,$C0,$C0,$C0,$00,$00,$C0
IP12L  !byte $07,$3F,$33,$3F,$3F,$04,$08,$0C
IP12R  !byte $80,$F0,$30,$F0,$F0,$80,$40,$C0
IP14L  !byte $01,$0F,$0C,$0F,$0F,$01,$02,$0C
IP14R  !byte $E0,$FC,$CC,$FC,$FC,$20,$10,$0C
IP16L  !byte $00,$03,$03,$03,$03,$00,$00,$00
IP16R  !byte $78,$FF,$33,$FF,$FF,$48,$84,$CC
IP18LT !byte $00,$00,$00,$00,$1E,$FF,$CC,$FF
IP18RT !byte $00,$00,$00,$00,$00,$C0,$C0,$C0
IP18LB !byte $FF,$12,$21,$33,$00,$00,$00,$00
IP18RB !byte $C0,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$33,$00,$00,$21,$1E,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$33,$00,$00,$00,$1E,$21
       !byte $00,$00,$00,$00,$00,$00,$00,$00

INVADER2:
IP20L  !byte $63,$22,$3E,$6B,$FF,$BE,$A2,$36
IP20R  !byte $00,$00,$00,$00,$80,$80,$80,$00
IP22L  !byte $18,$08,$2F,$2A,$3F,$0F,$08,$30
IP22R  !byte $C0,$80,$A0,$A0,$E0,$80,$80,$60
IP24L  !byte $06,$02,$03,$06,$0F,$0B,$0A,$03
IP24R  !byte $30,$20,$E0,$B0,$F8,$E8,$28,$60
IP26L  !byte $01,$00,$02,$02,$03,$00,$00,$03
IP26R  !byte $8C,$88,$FA,$AA,$FE,$F8,$88,$06
IP28LT !byte $00,$00,$00,$00,$63,$22,$BE,$AA
IP28RT !byte $00,$00,$00,$00,$00,$00,$80,$80
IP28LB !byte $FF,$3E,$22,$C1,$00,$00,$00,$00
IP28RB !byte $80,$00,$00,$80,$00,$00,$00,$00
       !byte $00,$00,$00,$14,$00,$22,$1C,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$14,$00,$00,$1C,$22
       !byte $00,$00,$00,$00,$00,$00,$00,$00

INVADER3:
IP30L  !byte $08,$1C,$3E,$6B,$7F,$14,$22,$41
IP30R  !byte $00,$00,$00,$00,$00,$00,$00,$00
IP32L  !byte $02,$07,$0F,$1A,$1F,$05,$08,$05
IP32R  !byte $00,$00,$80,$C0,$C0,$00,$80,$00
IP34L  !byte $00,$01,$03,$06,$07,$01,$02,$04
IP34R  !byte $80,$C0,$E0,$B0,$F0,$40,$20,$10
IP36L  !byte $00,$00,$00,$01,$01,$00,$00,$00
IP36R  !byte $20,$70,$F8,$AC,$FC,$50,$88,$50
IP38LT !byte $00,$00,$00,$00,$08,$1C,$3E,$6B
IP38RT !byte $00,$00,$00,$00,$00,$00,$00,$00
IP38LB !byte $7F,$14,$22,$14,$00,$00,$00,$00
IP38RB !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$14,$00,$22,$1C,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$14,$00,$00,$1C,$22
       !byte $00,$00,$00,$00,$00,$00,$00,$00

SHIELD !byte $30,$31,$32,$FE,$FF,3
       !byte $36,$37,$38,$FE,$FF,4
       !byte $3C,$3D,$3E,$FE,$FF,3
       !byte $42,$43,$44,$FE,$FF,10
       !byte $33,$34,$35,$FE,$FF,3
       !byte $39,$3A,$3B,$FE,$FF,4
       !byte $3F,$40,$41,$FE,$FF,3
       !byte $45,$46,$47,$FD
TITLES !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E4,$D9,$B0,$D9,$DE
       !byte $E6,$D1,$D4,$D5,$E2,$E3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$A0,$9F,$99
       !byte $9E,$A4,$A3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$22,$23,$85,$7F,$81,$80,$FF,$FF,$FF,$10,$11,$81,$80
       !byte $7F,$82,$80,$FF,$FF,$FF,$06,$07,$81,$85,$7F,$83,$80,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$98,$99,$A4,$70,$A4,$98,$95,$70,$A9,$95,$9C,$9C,$9F,$A7
       !byte $70,$A3,$91,$A5,$93,$95,$A2,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$99,$9E,$70,$A4,$98,$95,$70,$93,$95,$9E,$A4,$95,$A2,$70
       !byte $96,$9F,$A2,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$9D,$91,$A8,$99,$9D,$A5,$9D,$70,$A0,$9F,$99,$9E,$A4,$A3
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$8F,$8F,$8F,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$95,$A8,$A4,$A2,$91,$70,$9D,$99,$A3,$A3,$99,$9C,$95,$70
       !byte $92,$91,$A3,$95,$70,$91,$A7,$91,$A2,$94,$95,$94,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$91,$A4,$70,$83,$80,$80,$80,$70,$A0,$9F,$99,$9E,$A4,$A3
       !byte $7E,$70,$70,$9F,$9E,$95,$70,$92,$91,$A3,$95,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$A2,$95,$A0,$91,$99,$A2,$95,$94,$70,$95,$A6,$95,$A2,$A9
       !byte $70,$81,$80,$7C,$80,$80,$80,$70,$A0,$9F,$99,$9E,$A4,$A3,$7E,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$D9,$DE,$E6,$D1,$D4,$D5,$E2
       !byte $B0,$DF,$E0,$E4,$D9,$DF,$DE,$E3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$C1,$BE,$B0,$DD,$D5,$E2,$D5,$DC,$E9,$B0
       !byte $D1,$D7,$D7,$E2,$D5,$E3,$E3,$D9,$E6,$D5,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$C2,$BE,$B0,$D4,$DF,$E7,$DE,$E2,$D9,$D7
       !byte $D8,$E4,$B0,$DE,$D1,$E3,$E4,$E9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$69,$5F,$65,$62,$30,$53
       !byte $58,$5F,$59,$53,$55,$4F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$90,$81,$89,$88,$81,$70,$A4,$95,$A8,$91,$A3
       !byte $70,$99,$9E,$A3,$A4,$A2,$A5,$9D,$95,$9E,$A4,$A3,$FF,$FF,$FF,$FF