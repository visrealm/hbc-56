; Troy's HBC-56 - 6502 - Q*bert audio
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

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

        +memset AUDIO_PCM_STATE, 0, 16

        rts

.pcmAudio
!bin "jump.pcm"
.pcmAudioEnd

audioJumpInit:
        lda AUDIO_PCM_STATE
        beq +
        rts
+
        +ayWrite AY_PSG0, AY_CHC_TONE_L,0
        +ayWrite AY_PSG0, AY_CHC_TONE_H,0
        +ayWrite AY_PSG0, AY_ENABLES, $3a

        +store16 AUDIO_CH0_PCM_ADDR_L, .pcmAudio

        lda #1
        sta AUDIO_PCM_STATE
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

.loadHighNibble:
        inc AUDIO_PCM_STATE
        lda (AUDIO_CH0_PCM_ADDR_L)
        +lsr4
        bra .playNibble

.loadLowNibble
        dec AUDIO_PCM_STATE
        lda (AUDIO_CH0_PCM_ADDR_L)
        and #$0f
        +inc16 AUDIO_CH0_PCM_ADDR_L
        bra .playNibble

audioJumpTick:
        lda AUDIO_PCM_STATE
        bne +
        rts
+
        bit #2
        beq .loadHighNibble
        bra .loadLowNibble
.playNibble

        +ayWriteA AY_PSG0, AY_CHC_AMPL

        +cmp16i AUDIO_CH0_PCM_ADDR_L, .pcmAudioEnd
        bne +
        beq audioJumpStop
+
        rts

audioJumpStop:
        lda #0
        sta AUDIO_PCM_STATE
        +ayWrite AY_PSG0, AY_CHC_TONE_L,0
        +ayWrite AY_PSG0, AY_CHC_TONE_H,0
        +ayWrite AY_PSG1, AY_CHA_AMPL, $00
        +ayWrite AY_PSG1, AY_ENABLES, $3e
        rts