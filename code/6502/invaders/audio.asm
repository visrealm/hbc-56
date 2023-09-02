; Troy's HBC-56 - 6502 - Invaders audio
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;



audioInit:
        jsr ayInit
        rts

audioAlienToneLeft:
        +ayWrite AY_PSG0, AY_CHA_TONE_H, 8
        +ayWrite AY_PSG0, AY_CHB_TONE_H, 0
        rts

audioAlienToneRight:
        +ayWrite AY_PSG0, AY_CHA_TONE_H, 0
        +ayWrite AY_PSG0, AY_CHB_TONE_H, 10
        rts

audioAlienTonePause:
        +ayWrite AY_PSG0, AY_CHA_TONE_H, 0
        +ayWrite AY_PSG0, AY_CHB_TONE_H, 0
        rts

audioFireBullet:
        +ayWrite AY_PSG0, AY_CHC_AMPL, $1f
        +ayWrite AY_PSG0, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG0, AY_ENV_PERIOD_H, $08
        +ayWrite AY_PSG0, AY_ENV_SHAPE, $09
        +ayWrite AY_PSG0, AY_ENABLES, $38
        lda #$08
        sta TONE1
        +ayWriteA AY_PSG0, AY_CHC_TONE_L
        rts

audioBulletIncreasePitch:
        lda TONE1
        clc
        adc #8
        sta TONE1
        +ayWriteA AY_PSG0, AY_CHC_TONE_L
        rts

audioBulletStop:
        +ayWrite AY_PSG0, AY_CHC_TONE_L, 0
        +ayWrite AY_PSG0, AY_CHC_TONE_H, 0
        rts

audioBombHit:
        +ayWrite AY_PSG1, AY_CHC_AMPL, $1f
        +ayWrite AY_PSG1, AY_NOISE_GEN, $06
        +ayWrite AY_PSG1, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG1, AY_ENV_PERIOD_H, $0a
        +ayWrite AY_PSG1, AY_ENV_SHAPE, $09
        +ayWrite AY_PSG1, AY_ENABLES, $1f
        rts

audioAlienHit:
        +ayWrite AY_PSG1, AY_CHC_AMPL, $1f
        +ayWrite AY_PSG1, AY_NOISE_GEN, $1f
        +ayWrite AY_PSG1, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG1, AY_ENV_PERIOD_H, $0f
        +ayWrite AY_PSG1, AY_ENV_SHAPE, $09
        +ayWrite AY_PSG1, AY_ENABLES, $1f
        rts
