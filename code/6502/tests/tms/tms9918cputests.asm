; Troy's HBC-56 - CPU tests (degugging emulator issues)
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

hbc56Main:
        sei
        jsr kbInit

        jsr tmsModeText

        +tmsSetAddrNameTable
        lda #' '
        ldx #(40 * 25 / 8)
        jsr _tmsSendX8

        +tmsSetColorFgBg TMS_LT_GREEN, TMS_BLACK
        +tmsEnableOutput
        cli

        +tmsEnableInterrupts

        clc
        lda #$30
        adc #$10
        bvs FAIL

        clc
        lda #$50
        adc #$50
        bvc FAIL

        clc
        lda #$50
        adc #$90
        bvs FAIL

        clc
        lda #$50
        adc #$D0
        bvs FAIL

        clc
        lda #$D0
        adc #$10
        bvs FAIL

        clc
        lda #$D0
        adc #$50
        bvs FAIL

        clc
        lda #$D0
        adc #$90
        bvc FAIL

        clc
        lda #$D0
        adc #$D0
        bvs FAIL


        sec
        lda #$50
        sbc #$F0
        bvs FAIL


        sec
        lda #$50
        sbc #$B0
        bvc FAIL


        sec
        lda #$50
        sbc #$70
        bvs FAIL


        sec
        lda #$50
        sbc #$30
        bvs FAIL


        sec
        lda #$D0
        sbc #$F0
        bvs FAIL


        sec
        lda #$D0
        sbc #$B0
        bvs FAIL


        sec
        lda #$D0
        sbc #$70
        bvc FAIL


        sec
        lda #$D0
        sbc #$30
        bvs FAIL

        jmp success

FAIL:
        +tmsPrint "FAILED",2,0
-
        jmp -

success:
        +tmsPrint "PASSED",2,0
-
        jmp -
