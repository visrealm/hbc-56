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

INVADERS_ZP_TOP         = HBC56_USER_ZP_START 

FRAMES_COUNTER          = INVADERS_ZP_TOP

ANIM_FRAME              = INVADERS_ZP_TOP + 1 ; 0, 1, 2, 3, 0, 1, 2, 3
MOVE_FRAME              = INVADERS_ZP_TOP + 2 ; 0, 0, 0, 0, 1, 1, 1, 1, 
GAMEFIELD_OFFSET_X      = INVADERS_ZP_TOP + 3
GAMEFIELD_OFFSET_Y      = INVADERS_ZP_TOP + 4
TMP_X_POSITION          = INVADERS_ZP_TOP + 5
TMP_Y_POSITION          = INVADERS_ZP_TOP + 6
TMP_GAMEFIELD_OFFSET    = INVADERS_ZP_TOP + 7

X_DIR                   = INVADERS_ZP_TOP + 8
Y_DIR                   = INVADERS_ZP_TOP + 9
PLAYER_X                = INVADERS_ZP_TOP + 10

BULLET_X                = INVADERS_ZP_TOP + 11
BULLET_Y                = INVADERS_ZP_TOP + 12

HIT_TILE_X              = INVADERS_ZP_TOP + 13
HIT_TILE_Y              = INVADERS_ZP_TOP + 14
HIT_TILE_PIX_X          = INVADERS_ZP_TOP + 15
HIT_TILE_PIX_Y          = INVADERS_ZP_TOP + 16

TONE0                   = INVADERS_ZP_TOP + 17
TONE1                   = INVADERS_ZP_TOP + 18
TONE0_                  = INVADERS_ZP_TOP + 19
TONE1_                  = INVADERS_ZP_TOP + 20

INVADER_PIXEL_OFFSET    = INVADERS_ZP_TOP + 21

GAMEFIELD_LAST_ROW      = INVADERS_ZP_TOP + 22
GAMEFIELD_LAST_COL      = INVADERS_ZP_TOP + 23
GAMEFIELD_FIRST_COL     = INVADERS_ZP_TOP + 24

INVADER_BOMB1_X         = INVADERS_ZP_TOP + 25
INVADER_BOMB1_Y         = INVADERS_ZP_TOP + 26

SCORE_BCD_L             = INVADERS_ZP_TOP + 27
SCORE_BCD_H             = INVADERS_ZP_TOP + 28

HI_SCORE_BCD_L          = INVADERS_ZP_TOP + 29
HI_SCORE_BCD_H          = INVADERS_ZP_TOP + 30


INV1_BASE_ADDR_L        = INVADERS_ZP_TOP + 31
INV1_BASE_ADDR_H        = INVADERS_ZP_TOP + 32
INV2_BASE_ADDR_L        = INVADERS_ZP_TOP + 33
INV2_BASE_ADDR_H        = INVADERS_ZP_TOP + 34
INV3_BASE_ADDR_L        = INVADERS_ZP_TOP + 35
INV3_BASE_ADDR_H        = INVADERS_ZP_TOP + 36

GAMEFIELD_TMP           = INVADERS_ZP_TOP + 37

TEMP1                   = INVADERS_ZP_TOP + 38
TEMP2                   = INVADERS_ZP_TOP + 39
TEMP3                   = INVADERS_ZP_TOP + 40
TEMP4                   = INVADERS_ZP_TOP + 41
TEMP5                   = INVADERS_ZP_TOP + 42

V_SYNC                  = INVADERS_ZP_TOP + 43