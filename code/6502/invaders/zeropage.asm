; Troy's HBC-56 - 6502 - Invaders
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Zero page addresses
;

TICKS_L = $48
TICKS_H = $49
V_SYNC  = $4a

FRAMES_COUNTER = $4f
ANIM_FRAME     = $50 ; 0, 1, 2, 3, 0, 1, 2, 3
MOVE_FRAME     = $51 ; 0, 0, 0, 0, 1, 1, 1, 1, 
GAMEFIELD_OFFSET_X     = $52
GAMEFIELD_OFFSET_Y     = $53
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

INVADER_PIXEL_OFFSET = $64

TMP_PATTERN = $65

SCORE_BCD_L = $70
SCORE_BCD_H = $71

HI_SCORE_BCD_L = $72
HI_SCORE_BCD_H = $73