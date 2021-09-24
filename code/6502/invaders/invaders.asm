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
!sl "invaders.lmap"

HBC56_SKIP_POST = 1

HBC56_INT_VECTOR = onVSync
!src "../lib/ut/math_macros.asm"
!src "../lib/hbc56.asm"

!src "zeropage.asm"
!src "../lib/ut/memory.asm"
!src "../lib/ut/util.asm"

TMS_MODEL = 9918
!src "../lib/gfx/tms9918.asm"

TMS_FONT_DATA: !bin "../lib/gfx/fonts/tms9918font1.o"

!src "../lib/gfx/bitmap.asm"
!src "../lib/inp/nes.asm"
!src "../lib/sfx/ay3891x.asm"
!src "../lib/sfx/sfxman.asm"

+hbc56Title "6502 INVADERS"

;
; contants
;

SPRITE_PLAYER    = 0
SPRITE_BULLET    = 4
SPRITE_BOMB1     = 5
SPRITE_SPLAT     = 3
SPRITE_LAST_LIFE = 1

SPRITE_HIDDEN_X  = $C0
SPRITE_HIDDEN_Y  = $00

BULLET_Y_LOADED = $D1
BULLET_SPEED = 3
BOMB_SPEED = 2

PLAYER_POS_Y = 153
LIVES_POS_Y = 170
BOMB_END_POS_Y = 152

FRAMES_PER_ANIM = 12
MAX_X           = 6

!src "gamefield.asm"
!src "tile.asm"
!src "score.asm"
!src "audio.asm"

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

INVADER1_TYPE = INVADER1
INVADER2_TYPE = INVADER2 
INVADER3_TYPE = INVADER3

INVADER1_PATT = 128
INVADER2_PATT = 136
INVADER3_PATT = 144

onVSync:
        pha
        +tmsDisableInterrupts ; this is just for the emulator...
        lda TICKS_L
        clc
        adc #1
        cmp #TMS_FPS
        bne writeTicksL
        inc TICKS_H
        lda #0
writeTicksL:
        sta TICKS_L
        lda #1
        sta V_SYNC
        +tmsReadStatus
        pla      
        rti

main:

        ; program entry point
        lda #<INVADER1_TYPE
        sta INV1_BASE_ADDR_L
        lda #>INVADER1_TYPE
        sta INV1_BASE_ADDR_H

        lda #<INVADER2_TYPE
        sta INV2_BASE_ADDR_L
        lda #>INVADER2_TYPE
        sta INV2_BASE_ADDR_H

        lda #<INVADER3_TYPE
        sta INV3_BASE_ADDR_L
        lda #>INVADER3_TYPE
        sta INV3_BASE_ADDR_H

restartGame:
        +tmsDisableOutput

        jsr sfxManInit:
        sei

        +tmsDisableInterrupts

        jsr audioInit

        jsr tmsInitTextTable

        +memcpy GAMEFIELD, initialGameField, 5 * 16

        +setMemCpyDst ALIEN1
        +setMemCpySrcInd INV1_BASE_ADDR_L
        +memcpySinglePage 8 * 2 
        +memset ALIEN1 + 16, 0, 8 * 2
        +setMemCpyDst ALIEN2
        +setMemCpySrcInd INV2_BASE_ADDR_L
        +memcpySinglePage 8 * 2 
        +memset ALIEN2 + 16, 0, 8 * 2
        +setMemCpyDst ALIEN3
        +setMemCpySrcInd INV3_BASE_ADDR_L
        +memcpySinglePage 8 * 2 
        +memset ALIEN3 + 16, 0, 8 * 2
        +memcpy SHIELD1, SHIELD, 8 * 6
        +memcpy SHIELD2, SHIELD, 8 * 6
        +memcpy SHIELD3, SHIELD, 8 * 6
        +memcpy SHIELD4, SHIELD, 8 * 6

        lda #9
        sta GAMEFIELD_LAST_ROW
        lda #10
        sta GAMEFIELD_LAST_COL
        lda #0
        sta GAMEFIELD_FIRST_COL


        lda #BULLET_Y_LOADED
        sta BULLET_Y
        sta INVADER_BOMB1_Y

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
        +tmsCreateSprite SPRITE_PLAYER, 0, 124, PLAYER_POS_Y, COLOR_SHIP
        +tmsCreateSpritePatternQuad 1, bulletSprite
        +tmsCreateSprite SPRITE_BULLET, 4, 124, BULLET_Y_LOADED, COLOR_BULLET
        +tmsCreateSpritePatternQuad 2, explodeSprite
        +tmsCreateSprite SPRITE_SPLAT, 8, SPRITE_HIDDEN_X, SPRITE_HIDDEN_Y, TMS_TRANSPARENT
        +tmsCreateSpritePatternQuad 3, invaderBomb
        +tmsCreateSprite SPRITE_BOMB1, 12, 124, BULLET_Y_LOADED, COLOR_BOMB

        +tmsCreateSprite SPRITE_LAST_LIFE, 0, 48, LIVES_POS_Y, COLOR_LIVES
        +tmsCreateSprite SPRITE_LAST_LIFE + 1, 0, 72, LIVES_POS_Y, COLOR_LIVES

        lda #(TMS_GFX_PIXELS_X - TMS_SPRITE_SIZE2X) / 2 + 4
        sta PLAYER_X

        +tmsSetAddrColorTable
        +tmsSendData COLORTAB, 16
        ldy #INVADER_OFFSET_COLOR
        lda (INV1_BASE_ADDR_L), y
        +tmsPut
        lda (INV2_BASE_ADDR_L), y
        +tmsPut
        lda (INV3_BASE_ADDR_L), y
        +tmsPut
        +tmsSendData COLORTAB + 19, 32-19

        +tmsSetAddrPattTableInd 8
        +tmsSendData SHIELD1, 8 * 6  ; Shield1 8 - 13
        +tmsSendData SHIELD2, 8 * 6  ; Shield2 14 - 18
        +tmsSendData SHIELD3, 8 * 6  ; Shield3 20 - 25
        +tmsSendData SHIELD4, 8 * 6  ; Shield4 26 - 31

        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSendData ALIEN1, 8 * 4
        +tmsSendData ALIEN1, 8 * 4
        +tmsSendData ALIEN2, 8 * 4
        +tmsSendData ALIEN2, 8 * 4
        +tmsSendData ALIEN3, 8 * 4
        +tmsSendData ALIEN3, 8 * 4

        +tmsSetAddrPattTableInd 176
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

        +tmsEnableOutput

        cli

nextFrame:
        jsr sfxManTick
        cli
        +tmsEnableInterrupts

gameLoop:
        lda V_SYNC
        beq gameLoop
        sei
        +tmsDisableInterrupts

        +nesBranchIfNotPressed NES_B, skipFire
        lda BULLET_Y
        cmp #BULLET_Y_LOADED
        bne skipFire

        jsr audioFireBullet

        lda PLAYER_X
        clc
        adc #4
        tax
        stx BULLET_X
        ldy #PLAYER_POS_Y
        sty BULLET_Y
        +tmsSpritePosXYReg SPRITE_BULLET
skipFire

        +nesBranchIfNotPressed NES_LEFT, skipMoveLeft
        dec PLAYER_X
        dec PLAYER_X
skipMoveLeft
        +nesBranchIfNotPressed NES_RIGHT, skipMoveRight
        inc PLAYER_X
        inc PLAYER_X
skipMoveRight

        ldx INVADER_BOMB1_X
        clc
        lda #BOMB_SPEED
        adc INVADER_BOMB1_Y
        sta INVADER_BOMB1_Y
        tay

        cpy #BOMB_END_POS_Y
        bcc afterBombEnded
        ldy #BULLET_Y_LOADED
        sty INVADER_BOMB1_Y
afterBombEnded
        +tmsSpritePosXYReg SPRITE_BOMB1

        ; set position to the bottom of the bomb
        tya
        clc
        adc #14
        tay

        jsr pixelToTileXy
        jsr tmsSetPosRead
        +tmsGet

        cmp #0
        beq shieldNotBombed
        cmp #32
        bcs shieldNotBombed

        ; shield tile hit
        jsr shieldBombed
        bcc shieldNotBombed

        jsr audioBombHit

shieldNotBombed

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
        jsr tmsSetPosRead
        +tmsGet

        cmp #0
        beq +
        cmp #32
        bcs ++

        ; shield tile hit
        jsr shieldHit
+
-
        jmp .testBulletPos
++
        cmp #INVADER1_PATT ; is it an alien?
        bcc -

        ; pixel-level collision with invader?
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead

        ; load the pattern row to test
        +tmsGet
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
        jsr updateScoreDisplay

        jsr audioAlienHit

        ; make sure he disappears.. now
        jsr renderGameField

        ldy #0
        sty BULLET_Y
        

.testBulletPos
        ldy BULLET_Y
        cpy #16
        bcs +
        ldy #BULLET_Y_LOADED
        sty BULLET_Y
        +tmsSpritePosXYReg SPRITE_BULLET

        jsr audioBulletStop
+

.afterBulletCheck:

        ldx PLAYER_X
        ldy #PLAYER_POS_Y
        +tmsSpritePosXYReg SPRITE_PLAYER

        lda #0
        sta V_SYNC

        jsr audioBulletIncreasePitch

        inc FRAMES_COUNTER
        lda FRAMES_COUNTER
        cmp #FRAMES_PER_ANIM
        beq +
        jmp nextFrame
+

        +tmsSpriteColor SPRITE_SPLAT, TMS_TRANSPARENT
        +tmsSpritePos SPRITE_SPLAT, SPRITE_HIDDEN_X, SPRITE_HIDDEN_Y

        inc TONE0
        lda TONE0
        and #$03

        cmp #0
        bne +
        jsr audioAlienToneLeft
        jmp ++
+
        cmp #2
        bne +
        jsr audioAlienToneRight
        jmp ++
+
        jsr audioAlienTonePause
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
        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSetSourceAddressInd INV1_BASE_ADDR_L
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER2_PATT
        +tmsSetSourceAddressInd INV2_BASE_ADDR_L
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER3_PATT
        +tmsSetSourceAddressInd INV3_BASE_ADDR_L
        +tmsSendBytes 16

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
        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSetSourceAddressIndOffset INV1_BASE_ADDR_L, INVADER_OFFSET_2
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER2_PATT
        +tmsSetSourceAddressIndOffset INV2_BASE_ADDR_L, INVADER_OFFSET_2
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER3_PATT
        +tmsSetSourceAddressIndOffset INV3_BASE_ADDR_L, INVADER_OFFSET_2
        +tmsSendBytes 16
        lda #2
        sta INVADER_PIXEL_OFFSET
        jmp .endLoop        
+
        cmp #2
        bne +
        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSetSourceAddressIndOffset INV1_BASE_ADDR_L, INVADER_OFFSET_4
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER2_PATT
        +tmsSetSourceAddressIndOffset INV2_BASE_ADDR_L, INVADER_OFFSET_4
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER3_PATT
        +tmsSetSourceAddressIndOffset INV3_BASE_ADDR_L, INVADER_OFFSET_4
        +tmsSendBytes 16
        lda #4
        sta INVADER_PIXEL_OFFSET
        jmp .endLoop        
+
        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSetSourceAddressIndOffset INV1_BASE_ADDR_L, INVADER_OFFSET_6
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER2_PATT
        +tmsSetSourceAddressIndOffset INV2_BASE_ADDR_L, INVADER_OFFSET_6
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER3_PATT
        +tmsSetSourceAddressIndOffset INV3_BASE_ADDR_L, INVADER_OFFSET_6
        +tmsSendBytes 16
        lda #6
        sta INVADER_PIXEL_OFFSET
        lda X_DIR
        bmi .moveLeft
        
.endLoop:
        lda INVADER_BOMB1_Y
        cmp #BULLET_Y_LOADED
        bne +
        jsr randomBottomRowInvader
        jsr gameFieldXyToPixelXy
        stx INVADER_BOMB1_X
        sty INVADER_BOMB1_Y
+
        jsr renderGameField

jmp nextFrame

.moveLeft
        dec GAMEFIELD_OFFSET_X
        lda GAMEFIELD_OFFSET_X
        cmp #1
        bne .endLoop
        lda #1
        sta X_DIR
        inc GAMEFIELD_OFFSET_Y


        bne +
        jmp restartGame
+
        jmp .endLoop


BIT0 = $80
BIT1 = $40
BIT2 = $20
BIT3 = $10
BIT4 = $08
BIT5 = $04
BIT6 = $02
BIT7 = $01

hitTestBits:
!byte  BIT0, BIT1, BIT2, BIT3, BIT4, BIT5, BIT6, BIT7
hitTestMasks:
!byte  !BIT0 & $ff, !BIT1, !BIT2, !BIT3, !BIT4, !BIT5, !BIT6, !BIT7

; Test a pattern row for a pixel hit
; Inputs:
;  A = The row pattern. Pixel bits.
;  HIT_TILE_PIX_X = The offset to check (0 - 7)
; Returns
;  Zero flag set if pixel not hit.
;  Zero flag clear id pixel hit
patternHitTest:
        ldx HIT_TILE_PIX_X
        and hitTestBits, x
        rts

patternHit:
        ldx HIT_TILE_PIX_X
        and hitTestMasks, x
        rts

; Clear a pixel at
; HIT_TILE_X, HIT_TILE_Y, HIT_TILE_PIX_X, HIT_TILE_PIX_Y
clearPixel:
        ldx HIT_TILE_X
        ldy HIT_TILE_Y
        jsr tmsSetPosRead
        +tmsGet
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead
        +tmsGet
        sta TMP_PATTERN

        jsr tmsSetAddressWrite ; TMS_TMP_ADDRESS is already set

        lda TMP_PATTERN
        jsr patternHit
        +tmsPut
        rts


shieldBombed:
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead

        ; load the pattern row that was hit
        +tmsGet
        sta TMP_PATTERN

        jsr patternHitTest
        beq .noBomb

        jsr clearPixel
        jsr decTileHitY
        jsr clearPixel
        jsr incTileHitX
        jsr clearPixel
        jsr incTileHitX
        jsr clearPixel
        jsr incTileHitY
        jsr decTileHitX
        jsr clearPixel
        jsr decTileHitX
        jsr decTileHitX
        jsr clearPixel
        jsr incTileHitY
        jsr incTileHitX
        jsr clearPixel
        jsr incTileHitX
        jsr clearPixel
        jsr incTileHitX
        jsr clearPixel
        jsr incTileHitY
        jsr decTileHitX
        jsr clearPixel
        jsr decTileHitX
        jsr clearPixel
        jsr decTileHitX
        jsr clearPixel
        jsr incTileHitY
        jsr incTileHitX
        jsr clearPixel
        jsr incTileHitX
        jsr clearPixel

        ; kill the bullet
        ldy #BULLET_Y_LOADED
        sty INVADER_BOMB1_Y
        sec
        rts
.noBomb
        clc
        rts

        
; Shield hit by player bullet
; Here, HIT_TILE_X, HIT_TILE_Y, HIT_TILE_PIX_X, HIT_TILE_PIX_Y are already set
; A is the pattern number at that location
; And X/Y are set to equal HIT_TILE_X and HIT_TILE_Y
shieldHit:
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead

        ; load the pattern row that was hit
        +tmsGet
        sta TMP_PATTERN

        jsr patternHitTest
        beq .noHit

        jsr clearPixel
        jsr incTileHitY
        jsr clearPixel
        jsr decTileHitX
        jsr decTileHitY
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

COLOR_SHIELD = TMS_WHITE << 4 | TMS_BLACK
COLOR_TEXT   = TMS_WHITE << 4 | TMS_BLACK
COLOR_SHIP   = TMS_CYAN
COLOR_BULLET = TMS_WHITE
COLOR_BOMB   = TMS_MAGENTA
COLOR_LIVES  = TMS_DK_BLUE
COLOR_BUNKER = TMS_DK_BLUE << 4 | TMS_BLACK

COLORTAB:
       !byte $00
       !byte COLOR_SHIELD, COLOR_SHIELD, COLOR_SHIELD, $00       ; SHIELDS
       !byte COLOR_TEXT, COLOR_TEXT                              ; NUMBERS
       !byte COLOR_TEXT, COLOR_TEXT, COLOR_TEXT, COLOR_TEXT      ; LETTERS
       !byte $00,$00,$00,$00,$00
       !byte $00                 ; INVADER 1
       !byte $00                 ; INVADER 2
       !byte $00                 ; INVADER 3
       !byte $00,$00,$00            
       !byte COLOR_BUNKER,$00            ; BOTTOM SCREEN
       !byte $00,$00,$00,$00      ; TOP SCREEN
       !byte $00,$00            ; TOP SCREEN


!src "patterns.asm"
