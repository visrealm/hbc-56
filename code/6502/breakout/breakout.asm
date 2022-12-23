; Troy's HBC-56 - Breakout
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

; Zero page addresses
; -------------------------
ZP0 = HBC56_USER_ZP_START

; ball position
POSX        = ZP0
POSX_SUB    = ZP0 + 1
POSY        = ZP0 + 2
POSY_SUB    = ZP0 + 3

; ball speed
SPDX        = ZP0 + 4
SPDX_SUB    = ZP0 + 5
SPDY        = ZP0 + 6
SPDY_SUB    = ZP0 + 7

; ball direction
DIRX        = ZP0 + 8
DIRY        = ZP0 + 9

; paddle position and width
PADX        = ZP0 + 10
PADW        = ZP0 + 11

; current level
LEVEL       = ZP0 + 12

; current score
SCORE_H     = ZP0 + 13
SCORE_M     = ZP0 + 14
SCORE_L     = ZP0 + 15

; ball count
BALLS       = ZP0 + 16

; score multiplier (number of blocks hit since paddle)
MULT        = ZP0 + 17

; blocks remaining
BLOCKS_LEFT = ZP0 + 18

; paddle speed (for ball acceleration)
PADSPD     = ZP0 + 19
PADSPD_SUB = ZP0 + 20

START_TIME = ZP0 + 21

; temporary storage
TMP        = ZP0 + 22
TMP_SIZE   = 10

; Ball constants
; -------------------------
BALL_BASE         = TMS_WHITE
BALL_SHADE        = TMS_GREY
BALL_SIZE         = 6
BALL_SPRITE_INDEX = 0
BALL_SHADOW_INDEX = 1

INITIAL_BALLS = 4

; Paddle constants
; -------------------------
PADDLE_WIDTH       = 32
PADDLE_SPEED       = 1
PADDLE_SPEED_SUB   = 0
PADDLE_L_SPRITE_INDEX = 2
PADDLE_R_SPRITE_INDEX = 3
PADDLE_ROW         = 23
PADDLE_SPRITE_Y    = PADDLE_ROW * 8 + 3

PADDLE_COLOR_HIGH  = TMS_WHITE
PADDLE_COLOR_BASE  = TMS_CYAN
PADDLE_COLOR_SHADE = TMS_LT_BLUE

; Level constants
; -------------------------
BRICKS_TILE_INDEX = 12
BRICKS_WIDTH      = 3
BRICK_TYPES       = 4
LEVEL_HEIGHT      = 12
LEVEL_WIDTH       = 7
LEVEL_STRIDE      = 8
NO_BRICK          = 255

GAME_AREA_LEFT    = 8
GAME_AREA_WIDTH   = 8 * BRICKS_WIDTH * LEVEL_WIDTH
GAME_AREA_RIGHT   = GAME_AREA_LEFT + GAME_AREA_WIDTH
LEVEL_SIZE        = LEVEL_HEIGHT * LEVEL_STRIDE

; UI constants
; -------------------------
TITLE_WIDTH        = 9
TITLE_HEIGHT       = 2
TITLE_TILE_INDEX   = 128
TITLE_X            = 23
TITLE_Y            = 0

LABEL_WIDTH        = 7

LEVEL_TILE_INDEX   = 146
LEVEL_LABEL_X      = 24
LEVEL_LABEL_Y      = 5
LEVEL_X            = 26
LEVEL_Y            = LEVEL_LABEL_Y + 2

SCORE_TILE_INDEX   = LEVEL_TILE_INDEX + LABEL_WIDTH
SCORE_LABEL_X      = 24
SCORE_LABEL_Y      = 10
SCORE_X            = 25
SCORE_Y            = SCORE_LABEL_Y + 2

BALLS_TILE_INDEX   = SCORE_TILE_INDEX + LABEL_WIDTH
BALLS_LABEL_X      = 24
BALLS_LABEL_Y      = 15
BALLS_X            = 26
BALLS_Y            = BALLS_LABEL_Y + 2

BORDER_TILE_INDEX = 26
BORDER_TL_INDEX   = BORDER_TILE_INDEX
BORDER_TOP_INDEX  = BORDER_TILE_INDEX + 1
BORDER_TR_INDEX   = BORDER_TILE_INDEX + 2
BORDER_L_INDEX    = BORDER_TILE_INDEX + 3
BORDER_R_INDEX    = BORDER_TILE_INDEX + 4
BORDER_LB_INDEX   = BORDER_TILE_INDEX + 5
BORDER_RB_INDEX   = BORDER_TILE_INDEX + 6
BORDER_BL_INDEX   = BORDER_TILE_INDEX + 7
BORDER_BR_INDEX   = BORDER_TILE_INDEX + 8
BORDER_B_INDEX    = BORDER_TILE_INDEX + 9
BORDER_TILES      = 7
BORDER_X          = 0
BORDER_Y          = 0
BORDER_WIDTH      = (BRICKS_WIDTH * LEVEL_WIDTH) + 2
BORDER_HEIGHT     = 24

BOX_X             = 4
BOX_Y             = 7
BOX_W             = 15
BOX_H             = 10

BOX_TITLE_X       = BOX_X + 3
BOX_TITLE_Y       = BOX_Y + 2
BOX_LABEL_X       = BOX_TITLE_X + 1
BOX_LABEL_Y       = BOX_TITLE_Y + 3

NEW_LEVEL_TIMEOUT = 2


; Audio constants
; -------------------------
TONE_PADDLE       = 6
TONE_WALL         = 2
TONE_BRICK        = 4
AUDIO_TONE_PERIOD = 400

; RAM locations
; -------------------------
LEVEL_DATA   = $0400


; -----------------------------------------------------------------------------
; HBC-56 Program Metadata
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "BREAKOUT-56"
        +setHbcMetaNES
        rts

; -----------------------------------------------------------------------------
; HBC-56 Program Entry
; -----------------------------------------------------------------------------
hbc56Main:

        sei

        ; go to graphics II mode
        jsr tmsModeGraphicsII

        ; disable display durint init
        +tmsDisableInterrupts
        +tmsDisableOutput

        ; set backrground
        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        ; set up graphics
        jsr initVram

        ; set up audio
        jsr initAudio

        ; reset the game
        jsr resetGame

        cli

        jmp hbc56Stop


; -----------------------------------------------------------------------------
; Initialise TMS9918 VRAM
; -----------------------------------------------------------------------------
initVram:

        jsr clearVram

        ; load the brick graphics
        jsr brickTilesToVram

        ; load the ui graphics
        jsr uiTilesToVram

        jsr initSprites

        jsr generatePaddleGlyphs

        rts

; -----------------------------------------------------------------------------
; Clear/reset VRAM
; -----------------------------------------------------------------------------
clearVram:
        ; clear the name table
        +tmsSetAddrNameTable
        lda #0
        jsr _tmsSendPage        
        jsr _tmsSendPage
        jsr _tmsSendPage

        ; set all color table entries to transparent
        +tmsSetAddrColorTable
        +tmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb        

        ; clear the pattern table
        +tmsSetAddrPattTable
        lda #0
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        jsr _tmsSendKb
        rts

; -----------------------------------------------------------------------------
; Write brick data to VRAM
; -----------------------------------------------------------------------------
brickTilesToVram:

        ; brick patterns (for each bank)
        +tmsSetAddrPattTableIIBank0 BRICKS_TILE_INDEX
        +tmsSendDataRpt block, 8 * BRICKS_WIDTH, BRICK_TYPES

        +tmsSetAddrPattTableIIBank1 BRICKS_TILE_INDEX
        +tmsSendDataRpt block, 8 * BRICKS_WIDTH, BRICK_TYPES

        +tmsSetAddrPattTableIIBank2 BRICKS_TILE_INDEX
        +tmsSendDataRpt block, 8 * BRICKS_WIDTH, BRICK_TYPES

        ; brick colors (for each bank)
        +tmsSetAddrColorTableIIBank0 BRICKS_TILE_INDEX
        jsr @sendBlocksPal

        +tmsSetAddrColorTableIIBank1 BRICKS_TILE_INDEX
        jsr @sendBlocksPal

        +tmsSetAddrColorTableIIBank2 BRICKS_TILE_INDEX
        jsr @sendBlocksPal

        rts

@sendBlocksPal:
        +tmsSendData    redBlockPal, 8
        +tmsSendDataRpt redBlockPal + 8, 8, 2
        +tmsSendData    yellowBlockPal, 8
        +tmsSendDataRpt yellowBlockPal + 8, 8, 2
        +tmsSendData    greenBlockPal, 8
        +tmsSendDataRpt greenBlockPal + 8, 8, 2
        +tmsSendData    blueBlockPal, 8
        +tmsSendDataRpt blueBlockPal + 8, 8, 2
        rts

; -----------------------------------------------------------------------------
; Generate paddle graphics
; -----------------------------------------------------------------------------
generatePaddleGlyphs:
        +tmsSetAddrPattTableIIBank2 256 - 32

        ; copy paddle left to ram
        +memcpy TMP, paddlePatt, 8

        ldy #8
@generateNextPaddleLeft
        ; store in vram
        phy
        +tmsSendData TMP, 8
        ply
        ldx #0

        ; shift each row right one pixel
@nextPaddleRowL
        lsr TMP, x
        inx
        cpx #8
        bne @nextPaddleRowL

        ; next tile?
        dey
        bne @generateNextPaddleLeft

        ; send paddle centre to vram
        +tmsSendData paddlePatt + 8, 8

        ; copy paddle right to ram
        +memcpy TMP, paddlePatt + 16, 8


        ldy #8
@generateNextPaddleRight

        ; store in vram
        phy
        +tmsSendData TMP, 8
        ply
        ldx #0

        ; shift each row left one pixel
@nextPaddleRow
        asl TMP, x
        inx
        cpx #8
        bne @nextPaddleRow

        ; next tile?
        dey
        bne @generateNextPaddleRight

        ; set up paddle row colors
        +tmsSetAddrColorTableIIBank2 256 - 32
        +tmsSendDataRpt paddlePal, 8, 32
        rts

; -----------------------------------------------------------------------------
; Initialise sprites
; -----------------------------------------------------------------------------
initSprites:
        ; create ball pattern
        +tmsCreateSpritePattern BALL_SPRITE_INDEX, ballPattern
        +tmsCreateSpritePattern BALL_SHADOW_INDEX, ballPattern + 8

        ; create paddle highlight patterns
        +tmsCreateSpritePattern PADDLE_L_SPRITE_INDEX, paddleLeftSpr
        +tmsCreateSpritePattern PADDLE_R_SPRITE_INDEX, paddleRightSpr
        
        ; create ball sprites
        +tmsCreateSprite 0, 0, 0, $d0, BALL_BASE
        +tmsCreateSprite 1, 1, 0, $d0, BALL_SHADE

        ; create paddle highlight sprites
        +tmsCreateSprite 2, 2, 0, 0, PADDLE_COLOR_HIGH
        +tmsCreateSprite 3, 3, 0, 0, PADDLE_COLOR_SHADE

        +tmsSetLastSprite 3
        rts

; -----------------------------------------------------------------------------
; Write UI elements to VRAM
; -----------------------------------------------------------------------------
uiTilesToVram:
        ; border patterns
        +tmsSetAddrPattTableIIBank0 BORDER_TILE_INDEX
        +tmsSendData borderTL, 10 * 8
        +tmsSetAddrPattTableIIBank1 BORDER_TILE_INDEX
        +tmsSendData borderTL, 10 * 8
        +tmsSetAddrPattTableIIBank2 BORDER_TILE_INDEX
        +tmsSendData borderTL, 10 * 8

        ; border palette
        +tmsSetAddrColorTableIIBank0 BORDER_TILE_INDEX
        jsr @sendBorderPal
        +tmsSetAddrColorTableIIBank1 BORDER_TILE_INDEX
        jsr @sendBorderPal
        +tmsSetAddrColorTableIIBank2 BORDER_TILE_INDEX
        jsr @sendBorderPal

        ; title data
        +tmsSetAddrPattTableIIBank0 TITLE_TILE_INDEX
        +tmsSendData titlePatt, 8 * TITLE_WIDTH * TITLE_HEIGHT

        +tmsSetAddrPattTableIIBank1 TITLE_TILE_INDEX
        +tmsSendData titlePatt, 8 * TITLE_WIDTH * TITLE_HEIGHT

        +tmsSetAddrColorTableIIBank0 128
        +tmsSendDataRpt titlePal, 8, TITLE_WIDTH
        +tmsSendDataRpt titlePal + 8, 8, TITLE_WIDTH

        +tmsSetAddrColorTableIIBank1 128
        +tmsSendDataRpt titlePal, 8, TITLE_WIDTH
        +tmsSendDataRpt titlePal + 8, 8, TITLE_WIDTH

        ; label data
        +tmsSetAddrPattTableIIBank0 LEVEL_TILE_INDEX
        +tmsSendData levelPatt, 8 *LABEL_WIDTH * 3

        +tmsSetAddrPattTableIIBank1 LEVEL_TILE_INDEX
        +tmsSendData levelPatt, 8 * LABEL_WIDTH * 3

        +tmsSetAddrColorTableIIBank0 LEVEL_TILE_INDEX
        +tmsSendDataRpt labelPal, 8, LABEL_WIDTH * 3

        +tmsSetAddrColorTableIIBank1 LEVEL_TILE_INDEX
        +tmsSendDataRpt labelPal, 8, LABEL_WIDTH * 3

        ; digits data
        NUM_DIGITS = 10
        +tmsSetAddrPattTableIIBank0 '0'
        +tmsSendData digitsPatt, 8 * NUM_DIGITS
        +tmsSetAddrPattTableIIBank1 '0'
        +tmsSendData digitsPatt, 8 * NUM_DIGITS
        +tmsSetAddrPattTableIIBank2 '0'
        +tmsSendData digitsPatt, 8 * NUM_DIGITS

        +tmsSetAddrColorTableIIBank0 '0'
        +tmsSendDataRpt digitsPal, 8, NUM_DIGITS

        +tmsSetAddrColorTableIIBank1 '0'
        +tmsSendDataRpt digitsPal, 8, NUM_DIGITS

        +tmsSetAddrColorTableIIBank2 '0'
        +tmsSendDataRpt digitsPal, 8, NUM_DIGITS
        rts

@sendBorderPal
        +tmsSendDataRpt borderPal + 1, 8, 3
        +tmsSendDataRpt borderPal + 2, 8, 6
        +tmsSendDataRpt borderPal,     8, 1
        rts

; -----------------------------------------------------------------------------
; Add two subpixel values
; -----------------------------------------------------------------------------
!macro addSubPixel pos, spd, dir {
        bit dir
        bpl @posDir
@negDir
        clc
        lda pos + 1
        adc spd + 1
        sta pos + 1
        lda pos
        bcs +
        dec
+
        sec
        sbc spd
        sta pos
        bra @end
@posDir
        clc
        lda pos + 1
        adc spd + 1
        sta pos + 1
        
        lda pos
        adc spd
        sta pos
@end
}

; -----------------------------------------------------------------------------
; Initialise audio
; -----------------------------------------------------------------------------
initAudio:
        +ayToneEnable AY_PSG0, AY_CHC
        +aySetVolume AY_PSG0, AY_CHC, $00
        +aySetEnvShape AY_PSG0,AY_ENV_SHAPE_FADE_OUT
        rts

; -----------------------------------------------------------------------------
; Play a note from the notes tables
; Inputs:
;   X = index into notes tables
; -----------------------------------------------------------------------------
playNote:
        sta TMP

        lda #0
        +ayWriteA AY_PSG0, AY_CHC_TONE_L
        +ayWriteA AY_PSG0, AY_CHC_TONE_H

        ldx TMP
        lda notesL, x
        +ayWriteA AY_PSG0, AY_CHC_TONE_L
        lda notesH, x
        +ayWriteA AY_PSG0, AY_CHC_TONE_H

        +aySetVolumeEnvelope AY_PSG0, AY_CHC
        +aySetEnvShape AY_PSG0,AY_ENV_SHAPE_FADE_OUT
        +aySetEnvelopePeriod AY_PSG0, AUDIO_TONE_PERIOD

        rts


; -----------------------------------------------------------------------------
; Load level data from ROM
; Inputs:
;   LEVEL = level number to load
; -----------------------------------------------------------------------------
loadLevel:
        lda LEVEL
        dec
        and #$03
        asl
        tax

        lda levelMap, x
        sta MEM_SRC
        inx
        lda levelMap, X
        sta MEM_SRC + 1

        +setMemCpyDst LEVEL_DATA

        ldy #LEVEL_SIZE

        jsr memcpySinglePage

        rts

; -----------------------------------------------------------------------------
; Render the level
; -----------------------------------------------------------------------------
renderLevel:
        stz BLOCKS_LEFT

        ldx #0
-
        jsr renderBlock
        lda LEVEL_DATA, x
        beq +
        inc BLOCKS_LEFT
+
        inx
        cpx #LEVEL_SIZE
        bne -
        rts


; -----------------------------------------------------------------------------
; Render a level brick
; Inputs:
;   X = level brick index
; -----------------------------------------------------------------------------
renderBlock:
        phx

        ; calculate y tile
        stx TMP
        txa
        +div8   ; divide by level stride
        inc ; start at row 1
        tay

        ; calculate x tile
        lda TMP
        and #$07
        cmp #LEVEL_WIDTH
        bcs @endRender
        sta TMP
        asl
        sec
        adc TMP
        tax

        ; set tms address
        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite

        plx
        phx

        ; get brick type
        lda LEVEL_DATA, x
        tax

        ; get brick tile index
        lda tileData, x

        ; render the three brick tiles
        +tmsPut
        inc
        +tmsPut
        inc
        +tmsPut

@endRender:
        plx
        rts

; -----------------------------------------------------------------------------
; Reset paddle and ball - start a round
; -----------------------------------------------------------------------------
resetPaddle:

        ; reset paddle position an dsize
        lda #(GAME_AREA_WIDTH - PADDLE_WIDTH) / 2 + GAME_AREA_LEFT
        sta PADX
        lda #PADDLE_WIDTH
        sta PADW

        ; reset ball position and speed
        stz POSX_SUB
        stz POSY_SUB

        stz SPDX
        lda #2
        sta SPDY

        stz SPDX_SUB
        stz SPDY_SUB

        lda #1
        sta DIRX
        lda #-1
        sta DIRY

        lda #GAME_AREA_WIDTH / 2 + GAME_AREA_LEFT - 3
        sta POSX

        lda #PADDLE_SPRITE_Y - 6
        sta POSY

        ; clear the paddle row
        +tmsSetPosWrite 1, PADDLE_ROW
        +tmsPutRpt 0, LEVEL_WIDTH * BRICKS_WIDTH

        jsr renderPaddle

        ; output ball count
        +tmsSetPosWrite BALLS_X, BALLS_Y
        +tmsPut '0'
        lda BALLS
        jsr outputBCD

        rts

; -----------------------------------------------------------------------------
; Ball lost
; -----------------------------------------------------------------------------
loseBall:
        ; reset multiplier
        lda #1
        sta MULT
        
        ; lose a ball
        dec BALLS

        ; last ball?
        bmi endGame

        jsr resetPaddle

        +hbc56SetVsyncCallback gameLoopWaitForStart

        rts

; -----------------------------------------------------------------------------
; Advance a level
; -----------------------------------------------------------------------------
nextLevel
        inc LEVEL
        bra startGameLevel


; -----------------------------------------------------------------------------
; End game
; -----------------------------------------------------------------------------
endGame:
        jsr renderEndGameBox
        +hbc56SetVsyncCallback gameLoopGameOver
        rts


; -----------------------------------------------------------------------------
; Reset the game - new game
; -----------------------------------------------------------------------------
resetGame:
        ; level 1
        lda #1
        sta LEVEL

        ; score 0
        lda #0
        sta SCORE_L
        sta SCORE_M
        sta SCORE_H

        ; ball count
        lda #INITIAL_BALLS
        sta BALLS

        lda #PADDLE_SPEED
        sta PADSPD
        lda #PADDLE_SPEED_SUB
        sta PADSPD_SUB

; -----------------------------------------------------------------------------
; Start a new level
; -----------------------------------------------------------------------------
startGameLevel:

        +tmsDisableInterrupts
        +tmsDisableOutput

        +tmsSpritePos 0, 0, $d0
        +tmsSpritePos 1, 0, $d0

        jsr resetPaddle

        jsr loadLevel

        jsr renderLevel

        jsr renderBorder

        jsr renderLevelBox

        ; output level number
        +tmsSetPosWrite LEVEL_X, LEVEL_Y
        +tmsPut '0'
        lda LEVEL
        jsr outputBCD

        lda #0
        jsr addScore

        ; set up game loop as vsync callback
        lda HBC56_SECONDS_L
        sta START_TIME

        +hbc56SetVsyncCallback gameLoopNewLevel

        +tmsEnableOutput
        +tmsEnableInterrupts

        rts

; -----------------------------------------------------------------------------
; Add to the score
; Inputs:
;   A = BCD encoded points to add
; -----------------------------------------------------------------------------
addScore:
        sed
        adc SCORE_L
        sta SCORE_L
        bcc @endAddScore
        lda #0
        adc SCORE_M
        sta SCORE_M
        bcc @endAddScore
        lda #0
        adc SCORE_H
        sta SCORE_H

@endAddScore
        cld

        ; output score
        +tmsSetPosWrite SCORE_X, SCORE_Y
        lda SCORE_H
        jsr outputBCDLow
        lda SCORE_M
        jsr outputBCD
        lda SCORE_L
        jsr outputBCD
        rts

; -----------------------------------------------------------------------------
; Output two BCD digits to current location
; Inputs:
;   A = BCD encoded value
; -----------------------------------------------------------------------------
outputBCD:
        sta TMP
        +lsr4
        ora #'0'
        +tmsPut
        lda TMP
outputBCDLow:
        and #$0f
        ora #'0'
        +tmsPut
        rts

; -----------------------------------------------------------------------------
; Render the game border and ui
; -----------------------------------------------------------------------------
renderBorder:
        ; border top
        +tmsSetPosWrite BORDER_X, BORDER_Y
        +tmsPut BORDER_TL_INDEX
        +tmsPutRpt BORDER_TOP_INDEX, BORDER_WIDTH - 2
        +tmsPut BORDER_TR_INDEX

        ; left border
        ldx #BORDER_X
        ldy #BORDER_Y + 1
        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite
        ldx #BORDER_HEIGHT - 2
-
        +tmsPut BORDER_L_INDEX
        jsr tmsSetAddressNextRow
        jsr tmsSetAddressWrite
        dex
        bne -
        +tmsPut BORDER_LB_INDEX

        ; right border
        ldx #BORDER_X + BORDER_WIDTH - 1
        ldy #BORDER_Y + 1
        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite
        ldx #BORDER_HEIGHT - 2
-
        +tmsPut BORDER_R_INDEX
        jsr tmsSetAddressNextRow
        jsr tmsSetAddressWrite
        dex
        bne -
        +tmsPut BORDER_RB_INDEX

        ; render title
        +tmsSetPosWrite TITLE_X, TITLE_Y
        +tmsPutSeq TITLE_TILE_INDEX, TITLE_WIDTH
        +tmsSetPosWrite TITLE_X, TITLE_Y + 1
        +tmsPutSeq TITLE_TILE_INDEX + TITLE_WIDTH, TITLE_WIDTH

        ; render labels
        +tmsSetPosWrite LEVEL_LABEL_X, LEVEL_LABEL_Y
        +tmsPutSeq LEVEL_TILE_INDEX, LABEL_WIDTH

        +tmsSetPosWrite SCORE_LABEL_X, SCORE_LABEL_Y
        +tmsPutSeq SCORE_TILE_INDEX, LABEL_WIDTH

        +tmsSetPosWrite BALLS_LABEL_X, BALLS_LABEL_Y
        +tmsPutSeq BALLS_TILE_INDEX, LABEL_WIDTH

        rts

; -----------------------------------------------------------------------------
; Render dialog box
; -----------------------------------------------------------------------------
renderBox:
        ; border top
        +tmsSetPosWrite BOX_X, BOX_Y
        +tmsPut BORDER_TL_INDEX
        +tmsPutRpt BORDER_TOP_INDEX, BOX_W - 2
        +tmsPut BORDER_TR_INDEX

        lda #BOX_H - 2
        sta TMP

        ldx #BOX_X
        ldy #BOX_Y + 1
        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite
-
        +tmsPut BORDER_L_INDEX
        +tmsPutRpt 0, BOX_W - 2
        +tmsPut BORDER_R_INDEX

        jsr tmsSetAddressNextRow
        jsr tmsSetAddressWrite

        dec TMP
        bne -

        ; border bottom
        +tmsSetPosWrite BOX_X, BOX_Y + BOX_H - 1
        +tmsPut BORDER_BL_INDEX
        +tmsPutRpt BORDER_B_INDEX, BOX_W - 2
        +tmsPut BORDER_BR_INDEX
        rts

; -----------------------------------------------------------------------------
; Clear the dialog box
; -----------------------------------------------------------------------------
clearBox:
        lda #BOX_H
        sta TMP

        ldx #BOX_X
        ldy #BOX_Y
        jsr tmsSetPosTmpAddress
        jsr tmsSetAddressWrite
-
        +tmsPutRpt 0, BOX_W

        jsr tmsSetAddressNextRow
        jsr tmsSetAddressWrite

        dec TMP
        bne -

        rts

; -----------------------------------------------------------------------------
; Render the level dialog box
; -----------------------------------------------------------------------------
renderLevelBox:
        jsr renderBox

        +tmsSetPosWrite BOX_TITLE_X, BOX_TITLE_Y
        +tmsPutSeq TITLE_TILE_INDEX, TITLE_WIDTH
        +tmsSetPosWrite BOX_TITLE_X, BOX_TITLE_Y + 1
        +tmsPutSeq TITLE_TILE_INDEX + TITLE_WIDTH, TITLE_WIDTH

        +tmsSetPosWrite BOX_LABEL_X, BOX_LABEL_Y
        +tmsPutSeq LEVEL_TILE_INDEX, LABEL_WIDTH

        +tmsSetPosWrite BOX_LABEL_X + 2, BOX_LABEL_Y + 2
        +tmsPut '0'
        lda LEVEL
        jsr outputBCD

        rts

; -----------------------------------------------------------------------------
; Render the end game dialog box
; -----------------------------------------------------------------------------
renderEndGameBox:
        jsr renderBox

        +tmsSetPosWrite BOX_TITLE_X, BOX_TITLE_Y
        +tmsPutSeq TITLE_TILE_INDEX, TITLE_WIDTH
        +tmsSetPosWrite BOX_TITLE_X, BOX_TITLE_Y + 1
        +tmsPutSeq TITLE_TILE_INDEX + TITLE_WIDTH, TITLE_WIDTH

        +tmsSetPosWrite BOX_LABEL_X, BOX_LABEL_Y
        +tmsPutSeq SCORE_TILE_INDEX, LABEL_WIDTH

        +tmsSetPosWrite BOX_LABEL_X + 1, BOX_LABEL_Y + 2

        lda SCORE_H
        jsr outputBCDLow
        lda SCORE_M
        jsr outputBCD
        lda SCORE_L
        jsr outputBCD

        rts

; -----------------------------------------------------------------------------
; Render the paddle
; -----------------------------------------------------------------------------
renderPaddle:

        ; only support paddles > 8 pixels
        lda PADW
        cmp #8
        bcs +
        rts
+

        ; find paddle offset tile (x tile)
        lda PADX
        +div8
        sta TMP
        cmp #1
        beq +
        dec
+
        ; set tms address
        tax
        ldy #PADDLE_ROW
        jsr tmsSetPosWrite

        ; output a blank tile
        lda TMP
        cmp #1
        beq +
        +tmsPut 0
+
        ; find paddle pixel offset within the start tile
        ; and store in x        
        lda PADX
        and #$07
        tax

        ; store pixels remaining in TMP
        clc
        adc PADW
        sec
        sbc #8
        sta TMP

        ; find the correct tile index
        lda leftPatterns, x
        +tmsPut

@loop
        ; home many pixels left?
        lda TMP
        beq @doneDraw

        ; get pixel count for this tile
        ; 9 or more? call it 8
        cmp #9
        bcc +
        lda #8
+
        ; compute remaining pixels
        tax
        lda TMP
        stx TMP
        sec
        sbc TMP
        sta TMP

        ; find the correct tile index
        lda rightPatterns, x
        +tmsPut
        bra @loop

@doneDraw:

        ; output an empty tile
        lda PADX
        clc
        adc PADW
        cmp #GAME_AREA_RIGHT-8
        bcs +
        +tmsPut 0
+

        ; reposition the paddle highlight sprites
        ldx PADX
        ldy #PADDLE_SPRITE_Y
        +tmsSpritePosXYReg PADDLE_L_SPRITE_INDEX
        clc
        txa
        adc PADW
        dec
        tax
        +tmsSpritePosXYReg PADDLE_R_SPRITE_INDEX
        rts

; -----------------------------------------------------------------------------
; Render the ball
; -----------------------------------------------------------------------------
renderBall:
        ; get ball pixel position (rounding subpixel)
        ldx POSX
        bit POSX_SUB
        bpl +
        inx
+
        ldy POSY
        bit POSY_SUB
        bpl +
        iny
+
        ; update ball sprite locations
        +tmsSpritePosXYReg BALL_SPRITE_INDEX
        +tmsSpritePosXYReg BALL_SHADOW_INDEX
        rts

; -----------------------------------------------------------------------------
; convert a pixel position to a game brick index
; Inputs:
;   X = x location (in pixels)
;   Y = y location (in pixels)
; Returns;
;   A = Game brick / level index
; -----------------------------------------------------------------------------
posToLevelCell:

        ; compute offset for x tile index
        txa
        +div8
        tax
        lda @xPosToLevelCell, x

        ; not valid? bail
        cmp #NO_BRICK
        beq @outOfBounds

        sta TMP

        ; compute offset for y tile index
        tya
        +div8
        tay
        lda @yPosToLevelCell, y

        ; not valid? bail
        cmp #NO_BRICK
        beq @outOfBounds

        ; both valid. sum them to get a level index
        clc
        adc TMP

@outOfBounds:
        rts

; convert x tile index to level offset
@xPosToLevelCell:
!byte NO_BRICK, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, NO_BRICK, NO_BRICK, NO_BRICK

; convert y tile index to level offset
@yPosToLevelCell:
!byte NO_BRICK, 0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, NO_BRICK        


; -----------------------------------------------------------------------------
; negate a number (-ve to +ve and vice-versa)
; -----------------------------------------------------------------------------
!macro negate val {
        lda val
        eor #$ff
        inc
        sta val
}


; -----------------------------------------------------------------------------
; Call when we hit a brick.
; Inputs:
;   X = game brick index
; -----------------------------------------------------------------------------
hitBrick:
        lda #0
        sta LEVEL_DATA, x

        ; clear brick
        jsr renderBlock

        ; bounce ball
        +negate DIRY

        ; add to score (multiplier times)
        ldx MULT
-
        ; increment score
        lda #$25
        jsr addScore
        dex
        bne -

        ; increment multiplier
        inc MULT

        ; play a tone based on multiplier
        lda MULT
        inc
        inc
        jsr playNote
        rts

; -----------------------------------------------------------------------------
; Call when we hit the paddle
; -----------------------------------------------------------------------------
hitPaddle:
        
        ; paddle hit
        +negate DIRY

        ; accelerate ball
        +kbBranchIfPressed KB_SCANCODE_ARROW_LEFT, @leftPressed
        +nes1BranchIfPressed NES_LEFT, @leftPressed
@doneLeftCheck:

        +kbBranchIfPressed KB_SCANCODE_ARROW_RIGHT, @rightPressed
        +nes1BranchIfPressed NES_RIGHT, @rightPressed
@doneRightCheck:

        ; reset multiplier
        lda #1
        sta MULT

        lda #TONE_PADDLE
        jsr playNote
        rts

@leftPressed:
        jsr @pushLeft
        bra @doneLeftCheck

@rightPressed:
        jsr @pushRight
        bra @doneRightCheck



; -----------------------------------------------------------------------------
; Accelerate ball left based on paddle movement
; -----------------------------------------------------------------------------
@pushLeft:
        lda #-1
        sta TMP
        +addSubPixel SPDX, PADSPD, TMP

        lda SPDX
        bpl +
        +negate SPDX
        +negate DIRX
+
        rts

; -----------------------------------------------------------------------------
; Accelerate ball right based on paddle movement
; -----------------------------------------------------------------------------
@pushRight:
        lda #1
        sta TMP
        +addSubPixel SPDX, PADSPD, TMP

        lda SPDX
        bpl +
        +negate SPDX
        +negate DIRX
+
        rts

; -----------------------------------------------------------------------------
; Handle paddle input. Affect position
; -----------------------------------------------------------------------------
handlePaddleInput:

        ; left?
        +kbBranchIfPressed KB_SCANCODE_A, @leftPressed
        +nes1BranchIfPressed NES_LEFT, @leftPressed
@doneLeftCheck:

        ; right?
        +kbBranchIfPressed KB_SCANCODE_D, @rightPressed
        +nes1BranchIfPressed NES_RIGHT, @rightPressed

@doneRightCheck:


        rts

@leftPressed:
        lda PADX
        cmp #GAME_AREA_LEFT + 2
        bcc @doneLeftCheck
        dec PADX
        dec PADX
        bra @doneLeftCheck

@rightPressed:
        lda PADX
        clc
        adc PADW
        cmp #GAME_AREA_RIGHT-2
        bcs @doneRightCheck
        inc PADX
        inc PADX
        bra @doneRightCheck


; -----------------------------------------------------------------------------
; New level started - wait a couple of seconds (tied to VSYNC interrupt)
; -----------------------------------------------------------------------------
gameLoopNewLevel:

        lda START_TIME
        clc
        adc #NEW_LEVEL_TIMEOUT
        cmp HBC56_SECONDS_L
        bne @nextFrame

        +tmsDisableOutput
        jsr clearBox
        jsr renderLevel
        +tmsEnableOutput

        +hbc56SetVsyncCallback gameLoopWaitForStart

@nextFrame
        rts

; -----------------------------------------------------------------------------
; Wait for user input (tied to VSYNC interrupt)
; -----------------------------------------------------------------------------
gameLoopWaitForStart:
        
        jsr handlePaddleInput

        ; render the paddle
        jsr renderPaddle

        lda PADW
        lsr
        clc
        adc PADX
        dec
        dec
        sta POSX        

        jsr renderBall

        +kbBranchIfPressed KB_SCANCODE_SPACEBAR, @startGame
        +nes1BranchIfPressed NES_A, @startGame
        +nes1BranchIfPressed NES_B, @startGame
        +nes1BranchIfPressed NES_START, @startGame

        rts

@startGame
        jsr hitPaddle

        +hbc56SetVsyncCallback gameLoopRunning

        rts


; -----------------------------------------------------------------------------
; Game over - Wait for user input (tied to VSYNC interrupt)
; -----------------------------------------------------------------------------
gameLoopGameOver:
        +kbBranchIfPressed KB_SCANCODE_SPACEBAR,  @nextGame
        +nes1BranchIfPressed NES_A, @nextGame
        +nes1BranchIfPressed NES_B, @nextGame
        +nes1BranchIfPressed NES_START, @nextGame
        rts

@nextGame
        jmp resetGame

; -----------------------------------------------------------------------------
; Main game loop
; -----------------------------------------------------------------------------
gameLoopRunning:
        lda POSY
        cmp #(LEVEL_HEIGHT) * 8
        bcs @noHit

        ; convert ball position to tile x/y
        ldx POSX
        inx
        inx
        ldy POSY
        iny
        iny

        ; convert tile x/y to level index
        jsr posToLevelCell
        cmp #NO_BRICK
        beq @noHit

        ; locate brick type at level index
        tax
        lda LEVEL_DATA, x

        ; is it empty?
        beq @noHit

        jsr hitBrick

        ; any blocks left?
        dec BLOCKS_LEFT
        bne +
        jmp nextLevel
+

@noHit:

        ; paddle input
        jsr handlePaddleInput

        ; render the paddle
        jsr renderPaddle

        ; move the ball
        +addSubPixel POSX, SPDX, DIRX
        +addSubPixel POSY, SPDY, DIRY

        ; check for ball bounces
        bit DIRX
        bmi @checkLeft

        ; check right wall
        lda POSX
        cmp #GAME_AREA_RIGHT-5
        bcc @doneXCheck

        +negate DIRX
        lda #TONE_WALL
        jsr playNote

        bra @doneXCheck

        ; check left wall
@checkLeft
        lda POSX
        cmp #GAME_AREA_LEFT
        bcs @doneXCheck

        +negate DIRX
        lda #TONE_WALL
        jsr playNote

@doneXCheck

        bit DIRY
        bmi @checkTop

        ; check paddle
        lda POSY
        cmp #PADDLE_SPRITE_Y
        bcc @checkPaddle

        ; check out of bounds
        cmp #240
        bcc @doneYCheck
        jmp loseBall

@checkPaddle
        cmp #PADDLE_SPRITE_Y - 5
        bcc  @doneYCheck

        lda PADX
        cmp #BALL_SIZE
        bcc +
        sec
        sbc #BALL_SIZE - 1
+
        cmp POSX
        bcs @doneYCheck
        lda PADX
        clc
        adc PADW
        cmp POSX
        bcc @doneYCheck

        jsr hitPaddle

        bra @doneYCheck

        ; check top wall
@checkTop
        lda POSY
        cmp #9
        bcs @doneYCheck

        +negate DIRY
        lda #TONE_WALL
        jsr playNote

@doneYCheck

        jsr renderBall
        rts



; BALL
; ----------

ballPattern:
!byte $70,$f8,$f8,$f8,$70,$00,$00,$00   ; base
!byte $00,$18,$28,$58,$70,$00,$00,$00   ; shading


; PADDLE
; ----------

paddlePal: ; paddle colors
+byteTmsColorFgBg TMS_TRANSPARENT,    TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT,    TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT,    TMS_TRANSPARENT
+byteTmsColorFgBg PADDLE_COLOR_HIGH,  TMS_TRANSPARENT
+byteTmsColorFgBg PADDLE_COLOR_BASE,  TMS_TRANSPARENT
+byteTmsColorFgBg PADDLE_COLOR_BASE,  TMS_TRANSPARENT
+byteTmsColorFgBg PADDLE_COLOR_BASE,  TMS_TRANSPARENT
+byteTmsColorFgBg PADDLE_COLOR_SHADE, TMS_TRANSPARENT

paddleLeftSpr:
!byte $c0,$80,$80,$00,$00,$00,$00,$00
paddleRightSpr:
!byte $40,$40,$c0,$00,$00,$00,$00,$00
paddlePatt:
!byte $00,$00,$00,$7f,$ff,$ff,$ff,$7f   ; left
!byte $00,$00,$00,$ff,$ff,$ff,$ff,$ff   ; centre
!byte $00,$00,$00,$fe,$ff,$ff,$ff,$fe   ; right

; pattern indexes to paddle left/right tiles for a given pixel offset
leftPatterns:
!byte 224,225,226,227,228,229,230,231

rightPatterns:
!byte 240,239,238,237,236,235,234,233,232


; BLOCKS
; ----------

block:
!byte $7f,$3f,$7f,$7f,$7f,$7f,$7f,$00   ; left
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00   ; centre
!byte $fc,$fe,$fe,$fe,$fe,$fe,$fc,$00   ; right

BLUE_HIGH       = TMS_CYAN    << 4   | TMS_TRANSPARENT
BLUE_BASE       = TMS_LT_BLUE << 4   | TMS_TRANSPARENT
BLUE_BASEH      = TMS_LT_BLUE << 4   | TMS_CYAN
BLUE_SHADE      = TMS_DK_BLUE << 4   | TMS_TRANSPARENT

GREEN_HIGH      = TMS_LT_GREEN  << 4 | TMS_TRANSPARENT
GREEN_BASE      = TMS_MED_GREEN << 4 | TMS_TRANSPARENT
GREEN_BASEH     = TMS_MED_GREEN << 4 | TMS_LT_GREEN
GREEN_SHADE     = TMS_DK_GREEN  << 4 | TMS_TRANSPARENT

YELLOW_HIGH     = TMS_WHITE     << 4 | TMS_TRANSPARENT
YELLOW_BASE     = TMS_LT_YELLOW << 4 | TMS_TRANSPARENT
YELLOW_BASEH    = TMS_LT_YELLOW << 4 | TMS_WHITE
YELLOW_SHADE    = TMS_DK_YELLOW << 4 | TMS_TRANSPARENT

RED_HIGH        = TMS_LT_RED  << 4 | TMS_TRANSPARENT
RED_BASE        = TMS_MED_RED << 4 | TMS_TRANSPARENT
RED_BASEH       = TMS_MED_RED << 4 | TMS_LT_RED
RED_SHADE       = TMS_DK_RED  << 4 | TMS_TRANSPARENT

; block palettes. first tile and remaining tiles
blueBlockPal:
!byte BLUE_HIGH,BLUE_BASEH,BLUE_BASEH,BLUE_BASEH,BLUE_BASEH,BLUE_BASEH,BLUE_SHADE,TMS_TRANSPARENT
!byte BLUE_HIGH,BLUE_BASE,BLUE_BASE,BLUE_BASE,BLUE_BASE,BLUE_BASE,BLUE_SHADE,TMS_TRANSPARENT

greenBlockPal:
!byte GREEN_HIGH,GREEN_BASEH,GREEN_BASEH,GREEN_BASEH,GREEN_BASEH,GREEN_BASEH,GREEN_SHADE,TMS_TRANSPARENT
!byte GREEN_HIGH,GREEN_BASE,GREEN_BASE,GREEN_BASE,GREEN_BASE,GREEN_BASE,GREEN_SHADE,TMS_TRANSPARENT

yellowBlockPal:
!byte YELLOW_HIGH,YELLOW_BASEH,YELLOW_BASEH,YELLOW_BASEH,YELLOW_BASEH,YELLOW_BASEH,YELLOW_SHADE,TMS_TRANSPARENT
!byte YELLOW_HIGH,YELLOW_BASE,YELLOW_BASE,YELLOW_BASE,YELLOW_BASE,YELLOW_BASE,YELLOW_SHADE,TMS_TRANSPARENT

redBlockPal:
!byte RED_HIGH,RED_BASEH,RED_BASEH,RED_BASEH,RED_BASEH,RED_BASEH,RED_SHADE,TMS_TRANSPARENT
!byte RED_HIGH,RED_BASE,RED_BASE,RED_BASE,RED_BASE,RED_BASE,RED_SHADE,TMS_TRANSPARENT

tileData:
!byte 0,12,15,18,21

; BORDER
; ----------

borderTL:
!byte $3f,$7f,$ff,$ff,$ff,$ff,$ff,$ff
borderT:
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
borderTR:
!byte $f8,$fc,$fe,$fe,$fe,$fe,$fe,$fe
borderL:
!byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
borderR:
!byte $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
borderLB:
!byte $fe,$fe,$fe,$fe,$fe,$7c,$7c,$38
borderRB:
!byte $fe,$fe,$fe,$fe,$fe,$7c,$7c,$38
borderBL:
!byte $ff,$ff,$ff,$ff,$ff,$ff,$7f,$3f
borderBR:
!byte $fe,$fe,$fe,$fe,$fe,$fe,$fc,$f8
borderB:
!byte $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff


borderPal:
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE,   TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MAGENTA, TMS_TRANSPARENT


; TITLE
; ----------

titlePatt:
!byte $00,$1e,$3f,$7f,$03,$01,$03,$7f,$00,$0f,$1f,$bf,$81,$80,$81,$bf,$00,$1f,$9f,$df,$d8,$d8,$d8,$df,$00,$e1,$c1,$83,$03,$07,$06,$e6,$00,$86,$86,$c6,$c6,$e6,$66,$67,$00,$18,$39,$33,$63,$67,$c6,$c6,$00,$c3,$e3,$f3,$33,$3b,$1b,$1b,$00,$0c,$0c,$0d,$0c,$0c,$0c,$0c,$00,$7f,$fe,$fc,$30,$30,$30,$30
!byte $7f,$7f,$63,$61,$63,$7f,$7f,$7f,$3f,$bf,$be,$b7,$b3,$b1,$b0,$30,$df,$9f,$18,$18,$98,$df,$df,$df,$c6,$86,$06,$0e,$0c,$ec,$cd,$8d,$67,$67,$66,$76,$36,$36,$f6,$f6,$86,$c6,$c6,$67,$63,$33,$39,$18,$1b,$1b,$1b,$3b,$31,$f1,$e0,$c0,$0c,$0c,$0c,$9c,$98,$f8,$f0,$60,$30,$30,$30,$30,$30,$30,$30,$30

titlePal:
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_GREY, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_GREY, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_GREY, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MED_RED, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_YELLOW, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MED_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_BLUE, TMS_TRANSPARENT

; LABELS
; ----------

levelPatt:
!byte $0c,$0c,$0c,$0c,$0c,$0c,$0f,$0f,$07,$07,$06,$07,$07,$06,$f7,$e7,$fb,$f3,$01,$f9,$f0,$00,$f8,$f0,$01,$83,$83,$c7,$c6,$6c,$7c,$38,$bf,$bf,$30,$3f,$3f,$30,$3f,$3f,$d8,$98,$18,$d8,$98,$18,$df,$9f,$00,$00,$00,$00,$00,$00,$e0,$c0
scorePatt:
!byte $1f,$3f,$30,$3f,$3f,$00,$1f,$3f,$e3,$c7,$07,$ce,$ee,$67,$e7,$c3,$fc,$f8,$01,$01,$01,$01,$fc,$f8,$7e,$ff,$c3,$81,$81,$c3,$ff,$7e,$0f,$1f,$80,$80,$9f,$9f,$18,$18,$e3,$f3,$3b,$3b,$f3,$e3,$73,$3b,$fc,$f8,$00,$fc,$f8,$00,$fc,$f8
ballsPatt:
!byte $0f,$1f,$00,$1f,$1f,$18,$1f,$1f,$e0,$f0,$30,$f1,$f3,$33,$f6,$e6,$60,$f0,$f0,$98,$9c,$0c,$7e,$fe,$c0,$c0,$c0,$c0,$c0,$c0,$ff,$fe,$60,$60,$60,$60,$60,$60,$7f,$7f,$1f,$3f,$30,$3f,$3f,$00,$9f,$3f,$e0,$c0,$00,$c0,$e0,$60,$e0,$c0

labelPal:
+byteTmsColorFgBg TMS_DK_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_CYAN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_CYAN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_BLUE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_BLUE, TMS_TRANSPARENT

; FONT
; ----------

digitsPatt:
!byte $7C,$CE,$DE,$F6,$E6,$C6,$7C,$00 ; 0
!byte $18,$38,$18,$18,$18,$18,$7E,$00 ; 1
!byte $7C,$C6,$06,$7C,$C0,$C0,$FE,$00 ; 2
!byte $FC,$06,$06,$3C,$06,$06,$FC,$00 ; 3
!byte $0C,$CC,$CC,$CC,$FE,$0C,$0C,$00 ; 4
!byte $FE,$C0,$FC,$06,$06,$C6,$7C,$00 ; 5
!byte $7C,$C0,$C0,$FC,$C6,$C6,$7C,$00 ; 6
!byte $FE,$06,$06,$0C,$18,$30,$30,$00 ; 7
!byte $7C,$C6,$C6,$7C,$C6,$C6,$7C,$00 ; 8
!byte $7C,$C6,$C6,$7E,$06,$06,$7C,$00 ; 9

digitsPal:
+byteTmsColorFgBg TMS_DK_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MED_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_WHITE, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_LT_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_MED_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_GREEN, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_DK_GREEN, TMS_TRANSPARENT


; AUDIO DATA
; ----------

notesL:
!byte 0
+ayToneByteL NOTE_FREQ_FS4
+ayToneByteL NOTE_FREQ_G4
+ayToneByteL NOTE_FREQ_GS4
+ayToneByteL NOTE_FREQ_A4
+ayToneByteL NOTE_FREQ_AS4
+ayToneByteL NOTE_FREQ_B4
+ayToneByteL NOTE_FREQ_C5
+ayToneByteL NOTE_FREQ_CS5
+ayToneByteL NOTE_FREQ_D5
+ayToneByteL NOTE_FREQ_DS5
+ayToneByteL NOTE_FREQ_E5
+ayToneByteL NOTE_FREQ_F5
+ayToneByteL NOTE_FREQ_FS5
+ayToneByteL NOTE_FREQ_G5
+ayToneByteL NOTE_FREQ_GS5
+ayToneByteL NOTE_FREQ_A5
+ayToneByteL NOTE_FREQ_AS5
+ayToneByteL NOTE_FREQ_B5
+ayToneByteL NOTE_FREQ_C6
+ayToneByteL NOTE_FREQ_CS6
+ayToneByteL NOTE_FREQ_D6
+ayToneByteL NOTE_FREQ_DS6
+ayToneByteL NOTE_FREQ_E6
+ayToneByteL NOTE_FREQ_F6
+ayToneByteL NOTE_FREQ_FS6
+ayToneByteL NOTE_FREQ_G6
+ayToneByteL NOTE_FREQ_GS6
+ayToneByteL NOTE_FREQ_A6
+ayToneByteL NOTE_FREQ_AS6

notesH:
!byte 0
+ayToneByteH NOTE_FREQ_FS4
+ayToneByteH NOTE_FREQ_G4
+ayToneByteH NOTE_FREQ_GS4
+ayToneByteH NOTE_FREQ_A4
+ayToneByteH NOTE_FREQ_AS4
+ayToneByteH NOTE_FREQ_B4
+ayToneByteH NOTE_FREQ_C5
+ayToneByteH NOTE_FREQ_CS5
+ayToneByteH NOTE_FREQ_D5
+ayToneByteH NOTE_FREQ_DS5
+ayToneByteH NOTE_FREQ_E5
+ayToneByteH NOTE_FREQ_F5 
+ayToneByteH NOTE_FREQ_FS5
+ayToneByteH NOTE_FREQ_G5
+ayToneByteH NOTE_FREQ_GS5
+ayToneByteH NOTE_FREQ_A5
+ayToneByteH NOTE_FREQ_AS5
+ayToneByteH NOTE_FREQ_B5
+ayToneByteH NOTE_FREQ_C6
+ayToneByteH NOTE_FREQ_CS6
+ayToneByteH NOTE_FREQ_D6
+ayToneByteH NOTE_FREQ_DS6
+ayToneByteH NOTE_FREQ_E6
+ayToneByteH NOTE_FREQ_F6
+ayToneByteH NOTE_FREQ_FS6
+ayToneByteH NOTE_FREQ_G6
+ayToneByteH NOTE_FREQ_GS6
+ayToneByteH NOTE_FREQ_A6
+ayToneByteH NOTE_FREQ_AS6

; LEVEL DATA
; ----------

levelMap:
!word level1, level2, level3, level4


level1: 
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 1,1,1,1,1,1,1,0
!byte 2,2,2,2,2,2,2,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 3,3,3,3,3,3,3,0
!byte 4,4,4,4,4,4,4,0


level2: 
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 1,1,1,1,1,1,1,0
!byte 1,1,1,1,1,1,1,0
!byte 2,2,2,2,2,2,2,0
!byte 2,2,2,2,2,2,2,0
!byte 3,3,3,3,3,3,3,0
!byte 3,3,3,3,3,3,3,0
!byte 4,4,4,4,4,4,4,0
!byte 4,4,4,4,4,4,4,0


level3: 
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 1,1,1,1,1,1,1,0
!byte 0,0,0,0,0,0,0,0
!byte 2,2,2,2,2,2,2,0
!byte 0,0,0,0,0,0,0,0
!byte 3,3,3,3,3,3,3,0
!byte 0,0,0,0,0,0,0,0
!byte 4,4,4,4,4,4,4,0
!byte 0,0,0,0,0,0,0,0


level4: 
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0
!byte 0,0,0,1,0,0,0,0
!byte 0,0,1,2,1,0,0,0
!byte 0,1,2,0,2,1,0,0
!byte 1,2,0,0,0,2,1,0
!byte 2,0,0,3,0,0,2,0
!byte 0,0,3,4,3,0,0,0
!byte 0,3,4,0,4,3,0,0
!byte 3,4,0,0,0,4,3,0
!byte 4,0,0,0,0,0,4,0
!byte 0,0,0,0,0,0,0,0
