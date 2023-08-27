; Troy's HBC-56 - 6502 - Q*bert audio
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

PCM_PLAYING  = ZP0 +32

SAMPLE_ADDR_L = ZP0 + 33
SAMPLE_ADDR_H = ZP0 + 34

SAMPLE_ADDR = SAMPLE_ADDR_L

ENV_TEST_FREQ = 211.07992
ENV_TEST_PERIOD = 681*2


audioInit:
        jsr ayInit
        +ayWrite AY_PSG0, AY_CHA_AMPL, $0a
        +ayWrite AY_PSG0, AY_CHB_AMPL, $0a
        +ayWrite AY_PSG0, AY_CHC_AMPL, $00
        +ayWrite AY_PSG0, AY_ENV_PERIOD_L, 0
        +ayWrite AY_PSG0, AY_ENV_PERIOD_H, 0
        +ayWrite AY_PSG0, AY_ENV_SHAPE, AY_ENV_SHAPE_SAW1
        +ayWrite AY_PSG0, AY_ENABLES, $3e

        +ayWrite AY_PSG1, AY_CHC_AMPL, $00
        +ayWrite AY_PSG1, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG1, AY_ENV_PERIOD_H, $08
        +ayWrite AY_PSG1, AY_ENV_SHAPE, $0e
        +ayWrite AY_PSG1, AY_ENABLES, $3e

        lda #0
        sta PCM_PLAYING
        rts

.pcmAudio
!bin "jump.pcm"
.pcmAudioEnd

audioJumpInit:
        lda PCM_PLAYING
        beq +
        rts
+
        +ayWrite AY_PSG0, AY_CHC_TONE_L,0
        +ayWrite AY_PSG0, AY_CHC_TONE_H,0
        +ayWrite AY_PSG0, AY_ENABLES, $3a

        +store16 SAMPLE_ADDR, .pcmAudio

        lda #1
        sta PCM_PLAYING
        rts


audioEnvTest:
        +ayWrite AY_PSG0, AY_CHA_TONE_L, 211
        +ayWrite AY_PSG0, AY_CHA_TONE_H, 0
        +ayWrite AY_PSG0, AY_CHA_AMPL, $10
        +ayWrite AY_PSG0, AY_ENV_PERIOD_L, <ENV_TEST_PERIOD
        +ayWrite AY_PSG0, AY_ENV_PERIOD_H, >ENV_TEST_PERIOD
        +ayWrite AY_PSG0, AY_ENV_SHAPE, AY_ENV_SHAPE_FADE_OUT
        +ayWrite AY_PSG0, AY_ENABLES, $3a
        rts



audioJumpTick:
        lda PCM_PLAYING
        bne +
        rts
+

        lda (SAMPLE_ADDR)
        +lsr4

        +ayWriteA AY_PSG0, AY_CHC_AMPL

        +inc16 SAMPLE_ADDR

        +cmp16i SAMPLE_ADDR, .pcmAudioEnd
        bne +
        beq audioJumpStop
+
        rts

audioJumpStop:
        lda #0
        sta PCM_PLAYING
        +ayWrite AY_PSG0, AY_CHC_TONE_L,0
        +ayWrite AY_PSG0, AY_CHC_TONE_H,0
        +ayWrite AY_PSG1, AY_CHA_AMPL, $00
        +ayWrite AY_PSG1, AY_ENABLES, $3e
        rts