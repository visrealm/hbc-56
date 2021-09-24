; Troy's HBC-56 - 6502 - Invaders - Shields
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;


COLOR_SHIELD = TMS_WHITE << 4 | TMS_BLACK

shieldLayout:
!byte 8,9,10,0,0,0,14,15,16,0,0,0,0,20,21,22,0,0,0,26,27,28
!fill 10, 0
!byte 11,12,13,0,0,0,17,18,19,0,0,0,0,23,24,25,0,0,0,29,30,31
SHIELD_BYTES = * - shieldLayout


; -----------------------------------------------------------------------------
; Setup the shields
; -----------------------------------------------------------------------------
setupShield:
        +tmsSetAddrPattTableInd 8
        +tmsSendData SHIELD, 8 * 6  ; Shield1 8 - 13
        +tmsSendData SHIELD, 8 * 6  ; Shield2 14 - 18
        +tmsSendData SHIELD, 8 * 6  ; Shield3 20 - 25
        +tmsSendData SHIELD, 8 * 6  ; Shield4 26 - 31

        +tmsSetPosWrite 5, 17
        +tmsSendData shieldLayout, SHIELD_BYTES
        rts

; -----------------------------------------------------------------------------
; testShieldBombed: Shield bombed by alien
; -----------------------------------------------------------------------------
; Inputs:
;  A: Shield pattern index
;  HIT_TILE_X / HIT_TILE_Y shield tile location
;  HIT_TILE_PIX_X / HIT_TILE_PIX_Y pixel offset (hit location in tile)
; Outputs:
;  Carry: Set if hit, clear if no hit
; -----------------------------------------------------------------------------
testShieldBombed:
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead

        ; load the pattern row that was hit
        +tmsGet

        jsr patternHitTest
        beq .noBomb

        jsr clearShieldBombedPixels

        ; kill the bomb
        ldy #BULLET_Y_LOADED
        sty INVADER_BOMB1_Y
        sec
        rts
.noBomb
        clc
        rts

        
; -----------------------------------------------------------------------------
; testShieldPlayerBullet: Test shield hit by player bullet
; -----------------------------------------------------------------------------
; Inputs:
;  A: Shield pattern index
;  HIT_TILE_X / HIT_TILE_Y shield tile location
;  HIT_TILE_PIX_X / HIT_TILE_PIX_Y pixel offset (hit location in tile)
; Outputs:
;  Carry: Set if hit, clear if no hit
; -----------------------------------------------------------------------------
testShieldPlayerBullet:
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead

        ; load the pattern row that was hit
        +tmsGet

        jsr patternHitTest
        beq .noHit

        jsr clearShieldPlayerBulletPixels

        ; kill the bullet
        ldy #0
        sty BULLET_Y
        sec
        rts
.noHit
        clc
        rts

; -----------------------------------------------------------------------------
; clearShieldPlayerBulletPixels: Clear pixels in the following shape: X = HIT_TILE_PIX
; -----------------------------------------------------------------------------
;
;    O
;    OO
;   OX
;    O
;
clearShieldPlayerBulletPixels:
        jsr tileClearPixel       ; X
        jsr incTileHitY
        jsr tileClearPixel
        jsr decTileHitX
        jsr decTileHitY
        jsr tileClearPixel
        jsr decTileHitY
        jsr incTileHitX
        jsr tileClearPixel
        jsr incTileHitX
        jsr tileClearPixel
        jsr decTileHitY
        jsr decTileHitX
        jsr tileClearPixel
        rts

; -----------------------------------------------------------------------------
; clearShieldBombedPixels: Clear pixels in the following shape: X = HIT_TILE_PIX
; -----------------------------------------------------------------------------
;
;    OOO
;   OXO
;    OOO
;   OOO
;    OO
;
clearShieldBombedPixels:
        jsr tileClearPixel
        jsr decTileHitY
        jsr tileClearPixel
        jsr incTileHitX
        jsr tileClearPixel
        jsr incTileHitX
        jsr tileClearPixel
        jsr incTileHitY
        jsr decTileHitX
        jsr tileClearPixel
        jsr decTileHitX
        jsr decTileHitX
        jsr tileClearPixel
        jsr incTileHitY
        jsr incTileHitX
        jsr tileClearPixel
        jsr incTileHitX
        jsr tileClearPixel
        jsr incTileHitX
        jsr tileClearPixel
        jsr incTileHitY
        jsr decTileHitX
        jsr tileClearPixel
        jsr decTileHitX
        jsr tileClearPixel
        jsr decTileHitX
        jsr tileClearPixel
        jsr incTileHitY
        jsr incTileHitX
        jsr tileClearPixel
        jsr incTileHitX
        jsr tileClearPixel
        rts