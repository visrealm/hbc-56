!to "invaders.o", plain

HBC56_INT_VECTOR = onVSync

!source "../lib/hbc56.asm"

TMS_MODEL = 9929
!source "../lib/gfx/tms9918.asm"
!source "../lib/gfx/fonts/tms9918font1.asm"

!source "../lib/gfx/bitmap.asm"
!source "../lib/inp/nes.asm"
!source "../lib/ut/memory.asm"
!source "../lib/sfx/ay3891x.asm"

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

TONE0 = $60
TONE1 = $61
TONE0_ = $62
TONE1_ = $63

SPRITE_PLAYER    = 0
SPRITE_BULLET    = 3
SPRITE_LAST_LIFE = 1


; contants
BULLET_Y_LOADED = $D0
BULLET_SPEED = 4

GAMEFIELD = $1000
ALIEN1    = $1200
ALIEN2    = $1300
ALIEN3    = $1400

SHIELD1   = $1500
SHIELD2   = $1540
SHIELD3   = $1580
SHIELD4   = $15C0

GAME_COLS  = 24
GAME_ROWS  = 11

initialGameField:
!byte 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
!byte 0,136,137,136,137,136,137,136,137,136,137,136,137,136,137,136,137,136,137,136,137,136,137,  0
!byte 0,138,139,138,139,138,139,138,139,138,139,138,139,138,139,138,139,138,139,138,139,138,139,  0
!byte 0,132,133,132,133,132,133,132,133,132,133,132,133,132,133,132,133,132,133,132,133,132,133,  0
!byte 0,134,135,134,135,134,135,134,135,134,135,134,135,134,135,134,135,134,135,134,135,134,135,  0
!byte 0,132,133,132,133,132,133,132,133,132,133,132,133,132,133,132,133,132,133,132,133,132,133,  0
!byte 0,134,135,134,135,134,135,134,135,134,135,134,135,134,135,134,135,134,135,134,135,134,135,  0
!byte 0,128,129,128,129,128,129,128,129,128,129,128,129,128,129,128,129,128,129,128,129,128,129,  0
!byte 0,130,131,130,131,130,131,130,131,130,131,130,131,130,131,130,131,130,131,130,131,130,131,  0
!byte 0,128,129,128,129,128,129,128,129,128,129,128,129,128,129,128,129,128,129,128,129,128,129,  0
!byte 0,130,131,130,131,130,131,130,131,130,131,130,131,130,131,130,131,130,131,130,131,130,131,  0

shieldLayout:
!byte 8,9,10,0,0,0,14,15,16,0,0,0,0,20,21,22,0,0,0,26,27,28
!fill 10, 0
!byte 11,12,13,0,0,0,17,18,19,0,0,0,0,23,24,25,0,0,0,29,30,31
SHIELD_BYTES = * - shieldLayout

bunkerLayout:
!byte 176
!fill 22, 177
!byte 178
!fill 8, 0
!byte 179
!fill 22, 0
!byte 180
!fill 8, 0
!byte 181
!fill 22, 182
!byte 183
BUNKER_BYTES = * - bunkerLayout

ROTATE_ADDR = R8

rotate1:
        ldx #8
-
        dex
        lda ALIEN1 + 8, X
        ror     ; Get carry
        ror ALIEN1, X
        ror ALIEN1 + 8, X
        cpx #0
        bne -
        rts



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
        +memcpy GAMEFIELD, initialGameField, 24 * 11
        +memcpy ALIEN1, INVADER1, 8 * 2
        +memset ALIEN1 + 16, 0, 8 * 2
        +memcpy ALIEN2, INVADER2, 8 * 2
        +memset ALIEN2 + 16, 0, 8 * 2
        +memcpy ALIEN3, INVADER3, 8 * 2
        +memset ALIEN3 + 16, 0, 8 * 2
        +memcpy SHIELD1, SHIELD, 8 * 6
        +memcpy SHIELD2, SHIELD, 8 * 6
        +memcpy SHIELD3, SHIELD, 8 * 6
        +memcpy SHIELD4, SHIELD, 8 * 6

        lda BULLET_Y_LOADED
        sta BULLET_Y

        lda #0
        sta ANIM_FRAME
        sta MOVE_FRAME
        sta FRAMES_COUNTER
        sta Y_DIR
        sta TONE0

        lda #1
        sta X_POSITION
        sta X_DIR
        lda #3
        sta Y_POSITION

        jsr tmsInit

        lda #TMS_R1_SPRITE_MAG2
        jsr tmsReg1ClearFields
        lda #TMS_R1_SPRITE_16
        jsr tmsReg1SetFields

        +tmsCreateSpritePatternQuad 0, playerSprite
        +tmsCreateSprite SPRITE_PLAYER, 0, 100, 151, TMS_LT_BLUE
        +tmsCreateSpritePatternQuad 1, bulletSprite
        +tmsCreateSprite SPRITE_BULLET, 4, 100, BULLET_Y_LOADED, TMS_WHITE

        +tmsCreateSprite SPRITE_LAST_LIFE, 0, 50, 169, TMS_DK_BLUE
        +tmsCreateSprite SPRITE_LAST_LIFE + 1, 0, 70, 169, TMS_DK_BLUE

        lda #100
        sta PLAYER_X

        +tmsSetAddrColorTable
        +tmsSendData COLORTAB, 32

        +tmsSetAddrFontTableInd 8
        +tmsSendData SHIELD1, 8 * 6  ; Shield1 8 - 13
        +tmsSendData SHIELD2, 8 * 6  ; Shield2 14 - 18
        +tmsSendData SHIELD3, 8 * 6  ; Shield3 20 - 25
        +tmsSendData SHIELD4, 8 * 6  ; Shield4 26 - 31

        +tmsSetAddrFontTableInd 128
        +tmsSendData ALIEN1, 8 * 4
        +tmsSendData ALIEN2, 8 * 4
        +tmsSendData ALIEN3, 8 * 4

        +tmsSetAddrFontTableInd 176
        +tmsSendData BBORDR, 8 * 8

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        +tmsPrint "SCORE 00000   HI SCORE 00000", 2, 0
        +tmsSetPos 5, 17
        +tmsSendData shieldLayout, SHIELD_BYTES
        +tmsSetPos 4, 21
        +tmsSendData bunkerLayout, BUNKER_BYTES


        lda #0
        sta V_SYNC
        cli

        +tmsEnableInterrupts

        jsr ay3891Init

        +ay3891Write AY3891X_PSG1, AY3891X_ENABLES, $3e
        +ay3891Write AY3891X_PSG1, AY3891X_CHA_AMPL, $14
        +ay3891Write AY3891X_PSG1, AY3891X_CHB_AMPL, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHC_AMPL, $00
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_H, $08
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_SHAPE, $0e
        ;+ay3891PlayNote AY3891X_PSG1, AY3891X_CHA, NOTE_Gs


.loop:
        lda V_SYNC
        beq .loop
        jsr nextFrame

        +nesBranchIfNotPressed NES_B, +
        lda BULLET_Y
        cmp #BULLET_Y_LOADED
        bne +

        +ay3891Write AY3891X_PSG0, AY3891X_ENABLES, $38
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_AMPL, $1f
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_H, $10
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_SHAPE, $09
        lda #$08
        sta TONE1
        +ay3891WriteA AY3891X_PSG0, AY3891X_CHC_TONE_L

        lda PLAYER_X
        clc
        adc #4
        tax
        stx BULLET_X
        ldy #157
        sty BULLET_Y
        +tmsSpritePosXYReg SPRITE_BULLET
+


        +nesBranchIfPressed NES_A, +
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_H, $08
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_SHAPE, $0e
        +ay3891PlayNote AY3891X_PSG1, AY3891X_CHA, NOTE_Gs
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
        +tmsSpritePosXYReg SPRITE_BULLET
        
        jsr pixelToTileXy
        
        ldx HIT_TILE_X
        ldy HIT_TILE_Y
        jsr tmsSetPosRead
        lda TMS9918_RAM
        +tmsWait

        cmp #0
        beq +
        cmp #32
        bcs +
        ; tile hit
        jsr tmsSetPos
        +tmsPut 0
        ldy 0
        sty BULLET_Y

+
        ldy BULLET_Y
        cpy #16
        bcs +
        ldy #BULLET_Y_LOADED
        sty BULLET_Y
        +tmsSpritePosXYReg SPRITE_BULLET

        jsr stopBulletSound
+

        ldx PLAYER_X
        ldy #151
        +tmsSpritePosXYReg SPRITE_PLAYER

        lda #0
        sta Y_DIR

        lda #0
        sta V_SYNC

        lda TONE1
        clc
        adc #8
        sta TONE1
        +ay3891WriteA AY3891X_PSG0, AY3891X_CHC_TONE_L

        inc FRAMES_COUNTER
        lda FRAMES_COUNTER
        cmp #FRAMES_PER_ANIM
        beq +
        jmp .goLoop
+


        inc TONE0
        lda TONE0
        and #$03

        cmp #0
        bne +
        +ay3891Write AY3891X_PSG0, AY3891X_CHA_TONE_H, 8
        +ay3891Write AY3891X_PSG0, AY3891X_CHB_TONE_H, 0
        jmp ++
+
        cmp #2
        bne +
        +ay3891Write AY3891X_PSG0, AY3891X_CHA_TONE_H, 0
        +ay3891Write AY3891X_PSG0, AY3891X_CHB_TONE_H, 10
        jmp ++
+
        +ay3891Write AY3891X_PSG0, AY3891X_CHA_TONE_H, 0
        +ay3891Write AY3891X_PSG0, AY3891X_CHB_TONE_H, 0
        bne ++

++


        lda #0
        sta FRAMES_COUNTER

        lda ANIM_FRAME
        clc
        adc X_DIR
        sta ANIM_FRAME

        and #1
        beq +
        jsr rotate1
        +tmsSetAddrFontTableInd 128
        +tmsSendData ALIEN1, 16
        +tmsSetAddrFontTableInd 132
        +tmsSendData INVADER2, 16
        +tmsSetAddrFontTableInd 136
        +tmsSendData INVADER3, 16
        jmp .loop  
+      
        jsr rotate1
        +tmsSetAddrFontTableInd 128
        +tmsSendData ALIEN1, 16
        +tmsSetAddrFontTableInd 132
        +tmsSendData IP22L, 16
        +tmsSetAddrFontTableInd 136
        +tmsSendData IP32L, 16
        jmp .loop        

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


stopBulletSound:
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_AMPL, $00
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_H, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_TONE_L, 0
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_TONE_H, 0
        rts





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
        clc
        adc Y_POSITION
        tay
        jsr tmsSetPos
-
        ldx TMP_GAMEFIELD_OFFSET
        lda initialGameField, x
        sta TMS9918_RAM
        +tmsWait

        inc TMP_GAMEFIELD_OFFSET
        inc TMP_X_POSITION
        lda TMP_X_POSITION
        cmp #GAME_COLS
        bne -
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
       !byte $00
       !byte $F0,$F0,$F0,$00      ; SHIELDS
       !byte $F0,$F0            ; NUMBERS
       !byte $F0,$F0,$F0,$F0      ; LETTERS
       !byte $00,$00,$00,$00,$00
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

EMPTY:
       !byte $00,$00,$00,$00,$00,$00,$00,$00

INVADER1:
IP10L  !byte $1E,$FF,$CC,$FF,$FF,$12,$21,$C0
IP10R  !byte $00,$C0,$C0,$C0,$C0,$00,$00,$C0
IP12L  !byte $1E,$FF,$CC,$FF,$FF,$12,$21,$33
IP12R  !byte $00,$C0,$C0,$C0,$C0,$00,$00,$00

INVADER2:
IP20L  !byte $63,$22,$3E,$6B,$FF,$BE,$A2,$36
IP20R  !byte $00,$00,$00,$00,$80,$80,$80,$00
IP22L  !byte $63,$22,$BE,$AB,$FF,$3E,$22,$C1
IP22R  !byte $00,$00,$80,$80,$80,$00,$00,$80

INVADER3:
IP30L  !byte $08,$1C,$3E,$6B,$7F,$14,$22,$41
IP30R  !byte $00,$00,$00,$00,$00,$00,$00,$00
IP32L  !byte $08,$1C,$3E,$6B,$7F,$14,$22,$14
IP32R  !byte $00,$00,$00,$00,$00,$00,$00,$00

BBORDR !byte $00,$00,$1F,$3F,$7F,$78,$70,$70
       !byte $00,$00,$FF,$FF,$FF,$00,$00,$00
       !byte $00,$00,$FC,$FE,$FF,$0F,$07,$07
       !byte $70,$70,$70,$70,$70,$70,$70,$70
       !byte $07,$07,$07,$07,$07,$07,$07,$07
       !byte $70,$70,$70,$70,$78,$7F,$3F,$1F
       !byte $00,$00,$00,$00,$00,$FF,$FF,$FF
       !byte $07,$07,$07,$07,$0F,$FF,$FE,$FC

SHIELD !byte $00,$03,$07,$0F,$1F,$3F,$3F,$3F
       !byte $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $00,$C0,$E0,$F0,$F8,$FC,$FC,$FC
       !byte $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
       !byte $FF,$FF,$FF,$FF,$C3,$81,$81,$81
       !byte $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
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