; Troy's HBC-56 - 6502 - Q*bert audio
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; plays 4-bit .pcm files which are generated from RAW 8-bit audio samples
; using: python ..\..\..\tools\raw2pcm.py *.raw
;

ENV_TEST_FREQ = 211.07992
ENV_TEST_PERIOD = 681*2


audioInit:
        jsr ayInit
        
        +ayWrite AY_PSG0, AY_CHA_AMPL, $00
        +ayWrite AY_PSG0, AY_CHB_AMPL, $00
        +ayWrite AY_PSG0, AY_CHC_AMPL, $00
        +ayWrite AY_PSG0, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG0, AY_ENV_PERIOD_H, $00
        +ayWrite AY_PSG0, AY_ENV_SHAPE, AY_ENV_SHAPE_FADE_OUT
        +ayWrite AY_PSG0, AY_ENABLES, $3e

        +ayWrite AY_PSG1, AY_CHA_AMPL, $00
        +ayWrite AY_PSG1, AY_CHB_AMPL, $00
        +ayWrite AY_PSG1, AY_CHC_AMPL, $00
        +ayWrite AY_PSG1, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG1, AY_ENV_PERIOD_H, $00
        +ayWrite AY_PSG1, AY_ENV_SHAPE, AY_ENV_SHAPE_FADE_OUT
        +ayWrite AY_PSG1, AY_ENABLES, $3e

        ; clear all AUDIO_* ZP
        +memset AUDIO_CH0_PCM_STATE, 0, 16

        rts

audioTick:
        jsr audioTickCh0
        jsr audioTickCh1
        jsr audioTickCh2
        rts


!macro audioPlayPcm .channel, .start, .size {
        lda .channel
        bne .end

!if .channel == AUDIO_CH0_PCM_STATE {
        +ayToneEnable AY_PSG0, AY_CHC
}
!if .channel == AUDIO_CH1_PCM_STATE {
        +ayToneEnable AY_PSG1, AY_CHC
}
!if .channel == AUDIO_CH2_PCM_STATE {
        +ayToneEnable AY_PSG0, AY_CHA
}
        +store16 .channel + 1, .start
        +store16 .channel + 3, .size

        lda #1
        sta .channel
.end:
}


!macro audioTickSubroutine .ayDev, .ayChan, .qbChanAddr {
        lda .qbChanAddr
        bne +
        rts
+
        bit #2
        beq .loadHighNibble
        bra .loadLowNibble

.loadHighNibble:
        inc .qbChanAddr
        lda (.qbChanAddr + 1)
        +lsr4
        bra .playNibble

.loadLowNibble:
        dec .qbChanAddr
        lda (.qbChanAddr + 1)
        and #$0f
        pha
        +inc16 .qbChanAddr + 1
        +dec16 .qbChanAddr + 3
        pla

.playNibble
        +aySetVolumeAcc .ayDev, .ayChan
        +beq16 .qbChanAddr + 3, .stop
        rts

.stop:
        lda #0
        sta .qbChanAddr
        +ayPlayNote .ayDev, .ayChan, 0
        +aySetVolumeAcc .ayDev, .ayChan
        +ayToneDisable .ayDev, .ayChan
        rts
}

audioPlayJump:
        +audioPlayPcm AUDIO_CH0_PCM_STATE, .jumpPcmStart, .jumpPcmSize
        jsr audioTickCh0

        ;ldx #2
        ;lda #TMS_VRAM_NAME_ADDRESS2 >> 10
        ;jsr tmsSetRegister

        rts

audioPlayLevelStart:
        +audioPlayPcm AUDIO_CH0_PCM_STATE, .levelStartPcmStart, .levelStartPcmSize
        jsr audioTickCh0
        rts

audioPlayBadBallJump:
        +audioPlayPcm AUDIO_CH1_PCM_STATE, .jumpBadBallPcmStart, .jumpBadBallPcmSize
        jsr audioTickCh1

        ;ldx #2
        ;lda #TMS_VRAM_NAME_ADDRESS >> 10
        ;jsr tmsSetRegister

        rts

audioPlayCoilyEggJump:
        +audioPlayPcm AUDIO_CH2_PCM_STATE, .jumpCoilyEggPcmStart, .jumpCoilyEggPcmSize
        jsr audioTickCh1
        rts

;audioPlayQbertFall:
        ;+audioPlayPcm AUDIO_CH2_PCM_STATE, .qbertFallPcmStart, .qbertFallPcmSize
        ;jsr audioTickCh2
        ;rts

audioTickCh0:
        +audioTickSubroutine AY_PSG0, AY_CHC, AUDIO_CH0_PCM_STATE

audioTickCh1:
        +audioTickSubroutine AY_PSG1, AY_CHC, AUDIO_CH1_PCM_STATE

audioTickCh2:
        +audioTickSubroutine AY_PSG0, AY_CHA, AUDIO_CH2_PCM_STATE


.jumpPcmStart
!bin "pcm/jump.pcm"
.jumpPcmEnd
.jumpPcmSize = * - .jumpPcmStart

.jumpBadBallPcmStart
!bin "pcm/jump-badball.pcm"
.jumpBadBallPcmEnd
.jumpBadBallPcmSize = * - .jumpBadBallPcmStart

.jumpCoilyEggPcmStart
!bin "pcm/jump-coily-egg.pcm"
.jumpCoilyEggPcmEnd
.jumpCoilyEggPcmSize = * - .jumpCoilyEggPcmStart

.levelStartPcmStart
!bin "pcm/level-start.pcm"
.levelStartPcmEnd
.levelStartPcmSize = * - .levelStartPcmStart

;.qbertFallPcmStart
;!bin "qbert-fall.pcm"
;.qbertFallPcmEnd
;.qbertFallPcmSize = * - .qbertFallPcmStart
