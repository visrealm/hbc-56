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
!src "shield.asm"
!src "bunker.asm"
!src "aliens.asm"

;
; Memory address constants
;

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



; -----------------------------------------------------------------------------
; main entry point
; -----------------------------------------------------------------------------
main:

        ; any single-time setup?

restartGame:
        +tmsDisableOutput

        jsr sfxManInit:
        sei

        +tmsDisableInterrupts

        jsr audioInit

        jsr tmsInitTextTable

        +memcpy GAMEFIELD, initialGameField, 5 * 16

        
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

        lda #1
        sta GAMEFIELD_OFFSET_X
        sta X_DIR
        lda #4
        sta GAMEFIELD_OFFSET_Y

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
        +tmsSendData COLORTAB, 32

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        jsr setupAliens
        jsr setupScore
        jsr setupShield
        jsr setupBunker

        jsr renderGameField

        lda #0
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
        jsr testShieldBombed
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
        jsr testShieldPlayerBullet
+
-
        jmp .testBulletPos
++
        cmp #INVADER1_PATT ; is it an alien?
        bcc -

        ; pixel-level collision with invader?
        ldy HIT_TILE_PIX_Y
        pha
        jsr tmsSetPatternRead

        ; load the pattern row to test
        +tmsGet

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
        
        +tmsSpritePosXYReg SPRITE_SPLAT

        +tmsSetAddrSpriteColor SPRITE_SPLAT
        pla
        jsr alienColor
        +tmsPut

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

        jsr aliensSetTiles0

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
        jsr aliensSetTiles1
        jmp .endLoop        
+
        cmp #2
        bne +
        jsr aliensSetTiles2
        jmp .endLoop        
+
        jsr aliensSetTiles3
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


COLOR_TEXT   = TMS_WHITE << 4 | TMS_BLACK
COLOR_SHIP   = TMS_CYAN
COLOR_BULLET = TMS_WHITE
COLOR_BOMB   = TMS_MAGENTA
COLOR_LIVES  = TMS_DK_BLUE

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
       !byte COLOR_BUNKER,$00    ; BOTTOM SCREEN
       !byte $00,$00,$00,$00     ; TOP SCREEN
       !byte $00,$00             ; TOP SCREEN


!src "patterns.asm"
