; 6502 - Sound manager
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;
; Dependencies:
;  - hbc56.asm
;  - lib/sfx/ayx.asm
;  - lib/ut/memory.asm
;  - lib/ut/util.asm


SFXMAN_BASE_ADDR = $1200

CH0_TIMEOUT = SFXMAN_BASE_ADDR
CH0_TIMEOUT_L = CH0_TIMEOUT
CH0_TIMEOUT_H = CH0_TIMEOUT + 1
CH1_TIMEOUT   = CH0_TIMEOUT + 2
CH1_TIMEOUT_L = CH1_TIMEOUT
CH1_TIMEOUT_H = CH1_TIMEOUT + 1
CH2_TIMEOUT   = CH1_TIMEOUT + 2
CH2_TIMEOUT_L = CH2_TIMEOUT
CH2_TIMEOUT_H = CH2_TIMEOUT + 1
CH3_TIMEOUT   = CH2_TIMEOUT + 2
CH3_TIMEOUT_L = CH3_TIMEOUT
CH3_TIMEOUT_H = CH3_TIMEOUT + 1
CH4_TIMEOUT   = CH3_TIMEOUT + 2
CH4_TIMEOUT_L = CH4_TIMEOUT
CH4_TIMEOUT_H = CH4_TIMEOUT + 1
CH5_TIMEOUT   = CH4_TIMEOUT + 2
CH5_TIMEOUT_L = CH5_TIMEOUT
CH5_TIMEOUT_H = CH5_TIMEOUT + 1
NOISE0_TIMEOUT    = CH5_TIMEOUT + 2
NOISE0_TIMEOUT_L  = NOISE0_TIMEOUT
NOISE0_TIMEOUTT_H = NOISE0_TIMEOUT + 1
NOISE1_TIMEOUT    = NOISE0_TIMEOUT + 2
NOISE1_TIMEOUT_L  = NOISE1_TIMEOUT
NOISE1_TIMEOUTT_H = NOISE1_TIMEOUT + 1


sfxManInit:
        +memset SFXMAN_BASE_ADDR, 0, (NOISE1_TIMEOUTT_H + 1) - SFXMAN_BASE_ADDR
        rts

!macro sfxManTestChannelTimeout .timeout, .psg, .channel {
        lda .timeout   ; check for 0
        bne .nextCheck
        lda .timeout + 1
        beq .endCheck
.nextCheck
        +cmp16 .timeout, TICKS_L
        bcs .endCheck
        ;!byte $db

        +ayWrite .psg, AY_CHC_AMPL, $0

        !if .channel != 3 {
                +ayWrite .psg, .channel * 2 + 1, $00
        }

        lda #0
        sta .timeout
        sta .timeout + 1
.endCheck:
}

!macro sfxManSetChannelTimeout ticks, timeout {
        ;!byte $db
        +add16Imm TICKS_L, ticks, timeout
}

!macro sfxManSetPsg0ChATimeout seconds {
        +sfxManSetChannelTimeout (seconds * TMS_FPS), CH0_TIMEOUT
}
!macro sfxManSetPsg0ChBTimeout seconds {
        +sfxManSetChannelTimeout (seconds * TMS_FPS), CH1_TIMEOUT
}
!macro sfxManSetPsg0ChCTimeout seconds {
        +sfxManSetChannelTimeout (seconds * TMS_FPS), CH2_TIMEOUT
}
!macro sfxManSetPsg0NoiseTimeout seconds {
        +sfxManSetChannelTimeout (seconds * TMS_FPS), NOISE0_TIMEOUT
}
!macro sfxManSetPsg1ChATimeout seconds {
        +sfxManSetChannelTimeout (seconds * TMS_FPS), CH3_TIMEOUT
}
!macro sfxManSetPsg1ChBTimeout seconds {
        +sfxManSetChannelTimeout (seconds * TMS_FPS), CH4_TIMEOUT
}
!macro sfxManSetPsg1ChCTimeout seconds {
        +sfxManSetChannelTimeout (seconds * TMS_FPS), CH5_TIMEOUT
}
!macro sfxManSetPsg1NoiseTimeout seconds {
        +sfxManSetChannelTimeout (seconds * TMS_FPS), NOISE1_TIMEOUT
}

sfxManTick:
        +sfxManTestChannelTimeout CH0_TIMEOUT, AY_PSG0, AY_CHA
        +sfxManTestChannelTimeout CH1_TIMEOUT, AY_PSG0, AY_CHB
        +sfxManTestChannelTimeout CH2_TIMEOUT, AY_PSG0, AY_CHC
        +sfxManTestChannelTimeout NOISE0_TIMEOUT, AY_PSG0, AY_CHN

        +sfxManTestChannelTimeout CH3_TIMEOUT, AY_PSG1, AY_CHA
        +sfxManTestChannelTimeout CH4_TIMEOUT, AY_PSG1, AY_CHB
        +sfxManTestChannelTimeout CH5_TIMEOUT, AY_PSG1, AY_CHC
        +sfxManTestChannelTimeout NOISE1_TIMEOUT, AY_PSG1, AY_CHN
        rts

