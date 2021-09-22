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
        lsr
        lsr
        lsr
        lsr
        ora #$30
        sta TMS9918_RAM
        +tmsWaitData
        pla
        and #$0f
        ora #$30
        sta TMS9918_RAM
        +tmsWaitData
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

