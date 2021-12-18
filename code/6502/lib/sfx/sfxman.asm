; 6502 - Sound manager
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "sfx/sfxman.inc"

!ifndef SFXMAN_RAM_START { SFXMAN_RAM_START = $7600
        !warn "SFXMAN_RAM_START not provided. Defaulting to ", SFXMAN_RAM_START
}

HAVE_SFX_MAN = 1

CH0_TIMEOUT     = SFXMAN_RAM_START
CH1_TIMEOUT     = SFXMAN_RAM_START + 2
CH2_TIMEOUT     = SFXMAN_RAM_START + 4
CH3_TIMEOUT     = SFXMAN_RAM_START + 6
CH4_TIMEOUT     = SFXMAN_RAM_START + 8
CH5_TIMEOUT     = SFXMAN_RAM_START + 10
NOISE0_TIMEOUT  = SFXMAN_RAM_START + 12
NOISE1_TIMEOUT  = SFXMAN_RAM_START + 14

SFXMAN_TICKS    = SFXMAN_RAM_START + 16

SFXMAN_RAM_SIZE	= 18


!if SFXMAN_RAM_END < (SFXMAN_RAM_START + SFXMAN_RAM_SIZE) {
	!error "SFXMAN_RAM requires ",SFXMAN_RAM_SIZE," bytes. Allocated ",SFXMAN_RAM_END - SFXMAN_RAM_START
}


!macro sfxManTestChannelTimeout .timeout, .psg, .channel {
        lda .timeout   ; check for 0
        bne .nextCheck
        lda .timeout + 1
        beq .endCheck
.nextCheck
        +cmp16 .timeout, SFXMAN_TICKS
        bcs .endCheck

        +ayWrite .psg, AY_CHA_AMPL + .channel, $0

        lda #0
        sta .timeout
        sta .timeout + 1
.endCheck:
}

sfxManInit:
        lda #0
        sta SFXMAN_TICKS
        sta SFXMAN_TICKS + 1
        +memset SFXMAN_RAM_START, 0, SFXMAN_RAM_SIZE
        rts

sfxManTick:
        +inc16 SFXMAN_TICKS

        +sfxManTestChannelTimeout CH0_TIMEOUT, AY_PSG0, AY_CHA
        +sfxManTestChannelTimeout CH1_TIMEOUT, AY_PSG0, AY_CHB
        +sfxManTestChannelTimeout CH2_TIMEOUT, AY_PSG0, AY_CHC
        +sfxManTestChannelTimeout NOISE0_TIMEOUT, AY_PSG0, AY_CHN

        +sfxManTestChannelTimeout CH3_TIMEOUT, AY_PSG1, AY_CHA
        +sfxManTestChannelTimeout CH4_TIMEOUT, AY_PSG1, AY_CHB
        +sfxManTestChannelTimeout CH5_TIMEOUT, AY_PSG1, AY_CHC
        +sfxManTestChannelTimeout NOISE1_TIMEOUT, AY_PSG1, AY_CHN
        rts

