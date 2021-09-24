; Troy's HBC-56 - 6502 - Invaders - Score
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; -----------------------------------------------------------------------------
; Setup the score
; -----------------------------------------------------------------------------
setupScore:
        lda #0
        sta SCORE_BCD_L
        sta SCORE_BCD_H
        sta HI_SCORE_BCD_H
        sta HI_SCORE_BCD_L

        +tmsPrint "SCORE 00000   HI SCORE 00000", 2, 0
        rts        

; -----------------------------------------------------------------------------
; addScore: Add A to the score
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to increase the score by
; -----------------------------------------------------------------------------
addScore:
        clc
        sed
        adc SCORE_BCD_L
        sta SCORE_BCD_L
        bcc .skipUpdateScoreH
        lda SCORE_BCD_H
        adc #0 ; carry is set
        sta SCORE_BCD_H
.skipUpdateScoreH
        cld
        rts

; -----------------------------------------------------------------------------
; tmsOutputBcd: Output two bcd digits to the display
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to output
; Prerequisites:
;  TMS9918 output location set
; -----------------------------------------------------------------------------
tmsOutputBcd:
        pha
        +lsr4
        ora #$30
        +tmsPut
        pla
        and #$0f
        ora #$30
        +tmsPut
        rts

; -----------------------------------------------------------------------------
; updateScoreDisplay: Update the score display
; -----------------------------------------------------------------------------
updateScoreDisplay:
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

