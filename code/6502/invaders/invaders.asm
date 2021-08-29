; Troy's HBC-56 - 6502 - Invaders
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

!to "invaders.o", plain

HBC56_INT_VECTOR = onVSync

!source "../lib/hbc56.asm"

TMS_MODEL = 9918
!source "../lib/gfx/tms9918.asm"
!source "../lib/gfx/fonts/tms9918font1.asm"

!source "../lib/gfx/bitmap.asm"
!source "../lib/inp/nes.asm"
!source "../lib/ut/memory.asm"
!source "../lib/sfx/ay3891x.asm"

!src "zeropage.asm"

;
; contants
;

SPRITE_PLAYER    = 0
SPRITE_BULLET    = 4
SPRITE_SPLAT     = 3
SPRITE_LAST_LIFE = 1

SPRITE_HIDDEN_X  = $C0
SPRITE_HIDDEN_Y  = $00

BULLET_Y_LOADED = $D0
BULLET_SPEED = 1

PLAYER_POS_Y = 153
LIVES_POS_Y = 170

FRAMES_PER_ANIM = 12
MAX_X           = 6

!src "gamefield.asm"


;
; Memory address constants
;

ALIEN1    = $1200
ALIEN2    = $1300
ALIEN3    = $1400

SHIELD1   = $1500
SHIELD2   = $1540
SHIELD3   = $1580
SHIELD4   = $15C0

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
        and #$07
        sta HIT_TILE_PIX_X
        tya
        lsr
        lsr
        lsr
        sta HIT_TILE_Y
        tya
        and #$07
        sta HIT_TILE_PIX_Y
        rts

decTileHitX:
        lda HIT_TILE_PIX_X
        beq +
        dec HIT_TILE_PIX_X
        rts
+
        dec HIT_TILE_X
        lda #7
        sta HIT_TILE_PIX_X
        rts

incTileHitX:
        lda HIT_TILE_PIX_X
        cmp #7
        beq +
        inc HIT_TILE_PIX_X
        rts
+
        inc HIT_TILE_X
        lda #0
        sta HIT_TILE_PIX_X
        rts

decTileHitY:
        lda HIT_TILE_PIX_Y
        beq +
        dec HIT_TILE_PIX_Y
        rts
+
        dec HIT_TILE_Y
        lda #7
        sta HIT_TILE_PIX_Y
        rts

incTileHitY:
        lda HIT_TILE_PIX_Y
        cmp #7
        beq +
        inc HIT_TILE_PIX_Y
        rts
+
        inc HIT_TILE_Y
        lda #0
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

; Add A to the score
addScore:
        clc
        sed
        adc SCORE_BCD_L
        cld
        sta SCORE_BCD_L
        bcc +
        inc SCORE_BCD_H
+
        rts

tmsOutputBcd:
        pha
        lsr
        lsr
        lsr
        lsr
        ora #$30
        sta TMS9918_RAM
        +tmsWait
        pla
        and #$0f
        ora #$30
        sta TMS9918_RAM
        +tmsWait
        rts


updateScore:
        +tmsSetPosWrite 9, 0
        lda SCORE_BCD_H
        jsr tmsOutputBcd
        lda SCORE_BCD_L
        jsr tmsOutputBcd

        +tmsSetPosWrite 26, 0
        lda HI_SCORE_BCD_H
        jsr tmsOutputBcd
        lda HI_SCORE_BCD_L
        jsr tmsOutputBcd

        rts

main:
       

        jsr tmsInit

restartGame:
        sei

        +tmsDisableInterrupts

        jsr ay3891Init

        +ay3891Write AY3891X_PSG0, AY3891X_CHA_AMPL, $0a
        +ay3891Write AY3891X_PSG0, AY3891X_CHB_AMPL, $0a
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_AMPL, $1f
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_H, $10
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_SHAPE, $09
        +ay3891Write AY3891X_PSG0, AY3891X_ENABLES, $38

        +ay3891Write AY3891X_PSG1, AY3891X_CHC_AMPL, $1f
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_H, $08
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_SHAPE, $0e

        jsr tmsInitTextTable

        +memcpy GAMEFIELD, initialGameField, 5 * 16
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
        lda #0
        sta INVADER_PIXEL_OFFSET
        lda #0
        sta SCORE_BCD_L
        sta SCORE_BCD_H

        lda #1
        sta GAMEFIELD_OFFSET_X
        sta X_DIR
        lda #4
        sta GAMEFIELD_OFFSET_Y

        lda #$03
        sta HI_SCORE_BCD_H
        lda #$45
        sta HI_SCORE_BCD_L

        lda #TMS_R1_SPRITE_MAG2
        jsr tmsReg1ClearFields
        lda #TMS_R1_SPRITE_16
        jsr tmsReg1SetFields

        +tmsCreateSpritePatternQuad 0, playerSprite
        +tmsCreateSprite SPRITE_PLAYER, 0, 124, PLAYER_POS_Y, TMS_CYAN
        +tmsCreateSpritePatternQuad 1, bulletSprite
        +tmsCreateSprite SPRITE_BULLET, 4, 124, BULLET_Y_LOADED, TMS_WHITE
        +tmsCreateSpritePatternQuad 2, explodeSprite
        +tmsCreateSprite SPRITE_SPLAT, 8, SPRITE_HIDDEN_X, SPRITE_HIDDEN_Y, TMS_TRANSPARENT

        +tmsCreateSprite SPRITE_LAST_LIFE, 0, 48, LIVES_POS_Y, TMS_DK_BLUE
        +tmsCreateSprite SPRITE_LAST_LIFE + 1, 0, 72, LIVES_POS_Y, TMS_DK_BLUE

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
        +tmsSendData ALIEN1, 8 * 4
        +tmsSendData ALIEN2, 8 * 4
        +tmsSendData ALIEN2, 8 * 4
        +tmsSendData ALIEN3, 8 * 4
        +tmsSendData ALIEN3, 8 * 4

        +tmsSetAddrFontTableInd 176
        +tmsSendData BBORDR, 8 * 8

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        +tmsPrint "SCORE 00000   HI SCORE 00000", 2, 0
        +tmsSetPosWrite 5, 17
        +tmsSendData shieldLayout, SHIELD_BYTES
        +tmsSetPosWrite 4, 21
        +tmsSendData bunkerLayout, BUNKER_BYTES

        lda #0
        sta SCORE_BCD_L
        sta SCORE_BCD_H
        sta V_SYNC

        +tmsEnableInterrupts

        cli

.loop:
        lda V_SYNC
        beq .loop

        +nesBranchIfNotPressed NES_B, +
        lda BULLET_Y
        cmp #BULLET_Y_LOADED
        bne +

        +ay3891Write AY3891X_PSG0, AY3891X_CHC_AMPL, $1f
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_H, $10
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_SHAPE, $09
        +ay3891Write AY3891X_PSG0, AY3891X_ENABLES, $38
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
        beq ++
        cmp #32
        bcs ++

        ; shield tile hit
        jsr shieldHit
+
-
        jmp .testBulletPos
++
        cmp #128
        bcc -

        ; pixel-level collision with invader?
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead

        ; load the pattern row to test
        lda TMS9918_RAM
        +tmsWait
        sta TMP_PATTERN

        ; was an invader pixel hit?
        jsr patternHitTest
        beq -

        ; hit an invader tile
        ldx HIT_TILE_X
        ldy HIT_TILE_Y
        jsr tileXyToGameFieldXy
        
        stx TMP_X_POSITION
        sty TMP_Y_POSITION

        jsr gameFieldXyToPixelXy

        +tmsSpriteColor SPRITE_SPLAT, TMS_MED_RED
        +tmsSpritePosXYReg SPRITE_SPLAT

        jsr killObjectAt ; returns score for hit object

        jsr addScore
        jsr updateScore

        +ay3891Write AY3891X_PSG1, AY3891X_CHC_AMPL, $1f
        +ay3891Write AY3891X_PSG1, AY3891X_NOISE_GEN, $06
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_H, $10
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_SHAPE, $09
        +ay3891Write AY3891X_PSG1, AY3891X_ENABLES, $1f

        ; make sure he disappears.. now
        jsr nextFrame

        ldy #0
        sty BULLET_Y
        

.testBulletPos
        ldy BULLET_Y
        cpy #16
        bcs +
        ldy #BULLET_Y_LOADED
        sty BULLET_Y
        +tmsSpritePosXYReg SPRITE_BULLET

        jsr stopBulletSound
+

.afterBulletCheck:

        ldx PLAYER_X
        ldy #PLAYER_POS_Y
        +tmsSpritePosXYReg SPRITE_PLAYER

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
        jmp .loop
+

        +tmsSpriteColor SPRITE_SPLAT, TMS_TRANSPARENT
        +tmsSpritePos SPRITE_SPLAT, SPRITE_HIDDEN_X, SPRITE_HIDDEN_Y
        +ay3891Write AY3891X_PSG1, AY3891X_ENABLES, $3f

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

        and #$03
        bne +
        +tmsSetAddrFontTableInd 128
        +tmsSendData INVADER1, 16
        +tmsSetAddrFontTableInd 136
        +tmsSendData INVADER2, 16
        +tmsSetAddrFontTableInd 144
        +tmsSendData INVADER3, 16

        lda #0
        sta INVADER_PIXEL_OFFSET

        lda X_DIR
        bpl .moveRight
-
        jmp .endLoop


.moveRight
        inc GAMEFIELD_OFFSET_X
        lda GAMEFIELD_OFFSET_X
        cmp #8
        bne -
        lda #-1
        sta X_DIR
        inc GAMEFIELD_OFFSET_Y
        jmp .endLoop

+      
        cmp #1
        bne +
        +tmsSetAddrFontTableInd 128
        +tmsSendData IP12L, 16
        +tmsSetAddrFontTableInd 136
        +tmsSendData IP22L, 16
        +tmsSetAddrFontTableInd 144
        +tmsSendData IP32L, 16
        lda #2
        sta INVADER_PIXEL_OFFSET
        jmp .endLoop        
+
        cmp #2
        bne +
        +tmsSetAddrFontTableInd 128
        +tmsSendData IP14L, 16
        +tmsSetAddrFontTableInd 136
        +tmsSendData IP24L, 16
        +tmsSetAddrFontTableInd 144
        +tmsSendData IP34L, 16
        lda #4
        sta INVADER_PIXEL_OFFSET
        jmp .endLoop        
+
        +tmsSetAddrFontTableInd 128
        +tmsSendData IP16L, 16
        +tmsSetAddrFontTableInd 136
        +tmsSendData IP26L, 16
        +tmsSetAddrFontTableInd 144
        +tmsSendData IP36L, 16
        lda #6
        sta INVADER_PIXEL_OFFSET
        lda X_DIR
        bmi .moveLeft

.endLoop:
        jsr nextFrame

jmp .loop

.moveLeft
        dec GAMEFIELD_OFFSET_X
        lda GAMEFIELD_OFFSET_X
        cmp #1
        bne .endLoop
        lda #1
        sta X_DIR
        inc GAMEFIELD_OFFSET_Y
        lda #10
        cmp GAMEFIELD_OFFSET_Y
        bne +
        jmp restartGame
+
        jmp .endLoop


hitTestMasks:
!byte $80, $40, $20, $10, $08, $04, $02, $01
killBitMasks:
!byte $7f, $bf, $df, $ef, $f7, $fb, $fd, $fe

; Test a pattern row for a pixel hit
; Inputs:
;  A = The row pattern. Pixel bits.
;  HIT_TILE_PIX_X = The offset to check (0 - 7)
; Returns
;  Zero flag set if pixel not hit.
;  Zero flag clear id pixel hit
patternHitTest:
        ldx HIT_TILE_PIX_X
        and hitTestMasks, x
        rts

patternHit:
        ldx HIT_TILE_PIX_X
        and killBitMasks, x
        rts

; Clear a pixel at
; HIT_TILE_X, HIT_TILE_Y, HIT_TILE_PIX_X, HIT_TILE_PIX_Y
clearPixel:
        ldx HIT_TILE_X
        ldy HIT_TILE_Y
        jsr tmsSetPosRead
        lda TMS9918_RAM
        +tmsWait
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead
        lda TMS9918_RAM
        +tmsWait
        sta TMP_PATTERN

        jsr tmsSetAddressWrite ; TMS_TMP_ADDRESS is already set

        lda TMP_PATTERN
        jsr patternHit
        sta TMS9918_RAM
        +tmsWait
        rts




; Shield hit by player bullet
; Here, HIT_TILE_X, HIT_TILE_Y, HIT_TILE_PIX_X, HIT_TILE_PIX_Y are already set
; A is the pattern number at that location
; And X/Y are set to equal HIT_TILE_X and HIT_TILE_Y
shieldHit:
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead

        ; load the pattern row that was hit
        lda TMS9918_RAM
        +tmsWait
        sta TMP_PATTERN

        jsr patternHitTest
        beq .noHit

        jsr clearPixel
        jsr decTileHitX
        jsr clearPixel
        jsr decTileHitY
        jsr incTileHitX
        jsr clearPixel
        jsr incTileHitX
        jsr clearPixel
        jsr decTileHitY
        jsr decTileHitX
        jsr clearPixel

        ; kill the bullet
        ldy #0
        sty BULLET_Y
.noHit
        rts



stopBulletSound:
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_TONE_L, 0
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_TONE_H, 0
        rts


; Called each frame (on VSYNC)
nextFrame:
        sei
        jsr renderGameField
        cli
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
       !byte $60,$50            ; INVADER 3
       !byte $30,$50            ; INVADER 2
       !byte $70,$70            ; INVADER 1
       !byte $40,$00            ; BOTTOM SCREEN
       !byte $00,$00,$00,$00      ; TOP SCREEN
       !byte $00,$00            ; TOP SCREEN

!src "patterns.asm"