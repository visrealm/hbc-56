; Troy's HBC-56 - 6502 - Invaders
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Game field definitions
;

GAMEFIELD = $6000

GAME_COLS  = 11
GAME_ROWS  = 10

; X/Y indexes as tile location in screeen tiles
; returns:
;  X/Y
tileXyToGameFieldXy:
        txa
        clc ; clear to subtract (offset + 1)
        sbc GAMEFIELD_OFFSET_X
        +div2
        tax

        tya
        sec
        sbc GAMEFIELD_OFFSET_Y
        +div2
        tay
        rts

randomBottomRowInvader:
        lda GAMEFIELD_LAST_ROW
        +div2
        sta TMP_Y_POSITION
        inc TMP_Y_POSITION

        lda HBC56_SECONDS_L
        eor HBC56_TICKS
        eor PLAYER_X
        eor SCORE_BCD_L
        and #$0f
        tay

        cmp #11
        bcc .inRange
        sec
        sbc #10
.inRange
        sta TMP_X_POSITION
-        
        dec TMP_Y_POSITION
        bmi +        

        jsr gameFieldObjectAt

        cmp #INVADER1_PATT
        bcc -
+
        ldx TMP_X_POSITION
        ldy TMP_Y_POSITION
        rts



; Sets the TMS location for the given gamefield offset
gameFieldRowSetTmsPos:
        lda TMP_X_POSITION
        +mul2
        clc
        adc GAMEFIELD_OFFSET_X
        tax

        lda TMP_Y_POSITION
        clc
        adc GAMEFIELD_OFFSET_Y
        tay
        jmp tmsSetPosWrite

; X/Y gamefield index
; returns:
;  screen pixel location of centre of the game object
gameFieldXyToPixelXy:
        txa 
        +mul2
        clc
        adc GAMEFIELD_OFFSET_X
        +mul8
        clc
        adc INVADER_PIXEL_OFFSET
        adc #6
        tax

        tya 
        +mul2
        clc
        adc GAMEFIELD_OFFSET_Y
        +mul8
        sec
        sbc #6
        tay
        rts
        

; -----------------------------------------------------------------------------
; gameFieldObjectAt: Return gamefield object at given location
; -----------------------------------------------------------------------------
; TMP_X_POSITION: X Offset into gamefield
; TMP_Y_POSITION: Y Offset into gamefield
; -----------------------------------------------------------------------------
gameFieldObjectAt:
        lda TMP_Y_POSITION
        and #$fe
        +mul8
        clc
        adc TMP_X_POSITION
        tax
        lda GAMEFIELD, x
        rts

; -----------------------------------------------------------------------------
; killObjectAt: Kill gamefield object at given location
; -----------------------------------------------------------------------------
; TMP_X_POSITION: X Offset into gamefield
; TMP_Y_POSITION: Y Offset into gamefield
; -----------------------------------------------------------------------------
killObjectAt:
        lda TMP_Y_POSITION
        +mul16
        clc
        adc TMP_X_POSITION
        tax
        lda GAMEFIELD, x
        pha
        lda #0
        sta GAMEFIELD, x
        ; return score in A
        pla
        +div8
        sec
        sbc #15
        sta GAMEFIELD_TMP
        sed
        clc
        adc GAMEFIELD_TMP
        adc GAMEFIELD_TMP
        adc GAMEFIELD_TMP
        adc GAMEFIELD_TMP
        cld
        rts

; Returns:
;  X/Y - pixel location of object that was killed

; Is the row at TMP_Y_POSITION clear?
gameFieldRowClear:
        lda #0
        sta TMP_X_POSITION
        jsr gameFieldObjectAt

        ldy #12
-
        inx
        lda GAMEFIELD, x
        bne .notClear
        dey
        bne -

        clc
        rts

.notClear
        sec
        rts




renderGameField:

        lda #0
        sta TMP_X_POSITION
        sta TMP_GAMEFIELD_OFFSET
        lda #255
        sta TMP_Y_POSITION

        jsr gameFieldRowSetTmsPos

        ; send a blank row
        ldx #GAME_COLS * 2 + 2
        lda #0
-
        +tmsPut
        dex
        bne -

        lda #0
        sta TMP_Y_POSITION

.startRow
        lda #0
        sta TMP_X_POSITION

        jsr gameFieldRowSetTmsPos
        +tmsPut 0 ; first col - 0
        
.renderGameObjRow0
        ; get the game object at TMP_X_POSITION, TMP_Y_POSITION
        jsr gameFieldObjectAt
        +tmsPut
        beq +
        clc
        adc #1
+
        +tmsPut

        inc TMP_X_POSITION
        lda TMP_X_POSITION
        cmp #GAME_COLS
        bne .renderGameObjRow0

        +tmsPut 0 ; last col - 0
        
        lda #0
        sta TMP_X_POSITION
        inc TMP_Y_POSITION
        jsr gameFieldRowSetTmsPos
        +tmsPut 0 ; first col - 0

        lda TMP_Y_POSITION
        cmp GAMEFIELD_LAST_ROW
        beq +
        bcc +
        rts
+

.renderGameObjRow1
        ; get the game object at TMP_X_POSITION, TMP_Y_POSITION
        jsr gameFieldObjectAt
        beq +
        clc
        adc #2
+
        +tmsPut
        beq +
        clc
        adc #1
+
        +tmsPut

        inc TMP_X_POSITION
        lda TMP_X_POSITION
        cmp #GAME_COLS
        bne .renderGameObjRow1

        +tmsPut 0 ; last col - 0

        jsr gameFieldRowClear
        bcs +
        lda TMP_Y_POSITION        
        sta GAMEFIELD_LAST_ROW
        dec GAMEFIELD_LAST_ROW
        rts
+
        inc TMP_Y_POSITION
        lda TMP_Y_POSITION
        cmp GAMEFIELD_LAST_ROW

        beq +
        bcs +
        jmp .startRow
+
        rts

initialGameField:
!fill 11, INVADER3_PATT
!fill 5, 0
!fill 11, INVADER2_PATT
!fill 5, 0
!fill 11, INVADER2_PATT
!fill 5, 0
!fill 11, INVADER1_PATT
!fill 5, 0
!fill 11, INVADER1_PATT
!fill 5, 0
!fill 11, 0

