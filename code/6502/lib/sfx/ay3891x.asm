; 6502 - AY-3-819x PSG
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


; -------------------------
; Constants
; -------------------------
AY_IO_ADDR = $40

AY_PSG0 = $00
AY_PSG1 = $04

; IO Ports
AY_S0 = IO_PORT_BASE_ADDRESS | AY_IO_ADDR | AY_PSG0
AY_S1 = IO_PORT_BASE_ADDRESS | AY_IO_ADDR | AY_PSG1

AY_INACTIVE = $03
AY_READ     = $02
AY_WRITE    = $01
AY_ADDR     = $00

AY_S0_READ  = AY_S0 | AY_READ
AY_S0_WRITE = AY_S0 | AY_WRITE
AY_S0_ADDR  = AY_S0 | AY_ADDR

AY_S1_READ  = AY_S1 | AY_READ
AY_S1_WRITE = AY_S1 | AY_WRITE
AY_S1_ADDR  = AY_S1 | AY_ADDR

; Registers
AY_R0 = 0
AY_R1 = 1
AY_R2 = 2
AY_R3 = 3
AY_R4 = 4
AY_R5 = 5
AY_R6 = 6
AY_R7 = 7
AY_R8 = 8
AY_R9 = 9
AY_R10 = 10
AY_R11 = 11
AY_R12 = 12
AY_R13 = 13
AY_R14 = 14
AY_R15 = 15
AY_R16 = 16
AY_R17 = 17

AY_CHA = 0
AY_CHB = 1
AY_CHC = 2
AY_CHN = 3

AY_CHA_TONE_L   = AY_R0
AY_CHA_TONE_H   = AY_R1
AY_CHB_TONE_L   = AY_R2
AY_CHB_TONE_H   = AY_R3
AY_CHC_TONE_L   = AY_R4
AY_CHC_TONE_H   = AY_R5
AY_NOISE_GEN    = AY_R6
AY_ENABLES      = AY_R7
AY_CHA_AMPL     = AY_R8
AY_CHB_AMPL     = AY_R9
AY_CHC_AMPL     = AY_R10
AY_ENV_PERIOD_L = AY_R11
AY_ENV_PERIOD_H = AY_R12
AY_ENV_SHAPE    = AY_R13
AY_PORTA        = AY_R14
AY_PORTB        = AY_R15

AY_CLOCK_FREQ   = 2000000

!macro ayWrite .dev, .reg, .val {

        lda #.reg
        sta IO_PORT_BASE_ADDRESS | AY_IO_ADDR | AY_ADDR | .dev
        lda #.val
        sta IO_PORT_BASE_ADDRESS | AY_IO_ADDR | AY_WRITE | .dev
}        


!macro ayWriteX .dev, .reg, .val {

        lda #.reg
        sta IO_PORT_BASE_ADDRESS | AY_IO_ADDR | AY_ADDR | .dev
        lda #.val
        sta IO_PORT_BASE_ADDRESS | AY_IO_ADDR | AY_WRITE | .dev
}

!macro ayWriteA .dev, .reg {
        pha
        lda #.reg
        sta IO_PORT_BASE_ADDRESS | AY_IO_ADDR | AY_ADDR | .dev
        pla
        sta IO_PORT_BASE_ADDRESS | AY_IO_ADDR | AY_WRITE | .dev
}

!macro ayPlayNote .dev, .chan, .freq {
        .val = AY_CLOCK_FREQ / (16.0 * .freq)
        +ayWrite .dev, AY_CHA_TONE_L + (.chan * 2), <.val
        +ayWrite .dev, AY_CHA_TONE_H + (.chan * 2), >.val
}

!macro ayStop .dev, .chan{
        +ayWrite .dev, AY_CHA_TONE_L + (.chan * 2), 0
        +ayWrite .dev, AY_CHA_TONE_H + (.chan * 2), 0
}

NOTE_A  = 440
NOTE_As = 466.16
NOTE_B  = 493.88
NOTE_C  = 523.25
NOTE_Cs = 554.37
NOTE_D  = 587.33
NOTE_Ds = 622.25
NOTE_E  = 659.25
NOTE_F  = 698.46
NOTE_Fs = 739.99
NOTE_G  = 783.99
NOTE_Gs = 830.61
NOTE_0  = 0


ayInit:
        +ayWrite AY_PSG0, AY_ENABLES, $ff
        +ayWrite AY_PSG1, AY_ENABLES, $ff


        +ayWrite AY_PSG0, AY_CHA_AMPL, $00
        +ayWrite AY_PSG0, AY_CHB_AMPL, $00
        +ayWrite AY_PSG0, AY_CHC_AMPL, $00
        +ayWrite AY_PSG0, AY_CHA_TONE_H, $00
        +ayWrite AY_PSG0, AY_CHA_TONE_L, $00
        +ayWrite AY_PSG0, AY_CHB_TONE_H, $00
        +ayWrite AY_PSG0, AY_CHB_TONE_L, $00
        +ayWrite AY_PSG0, AY_CHC_TONE_H, $00
        +ayWrite AY_PSG0, AY_CHC_TONE_L, $00
        +ayWrite AY_PSG0, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG0, AY_ENV_PERIOD_H, $00
        +ayWrite AY_PSG0, AY_ENV_SHAPE, $00
        +ayWrite AY_PSG0, AY_NOISE_GEN, $00

        +ayWrite AY_PSG1, AY_CHA_AMPL, $00
        +ayWrite AY_PSG1, AY_CHB_AMPL, $00
        +ayWrite AY_PSG1, AY_CHC_AMPL, $00
        +ayWrite AY_PSG1, AY_CHA_TONE_H, $00
        +ayWrite AY_PSG1, AY_CHA_TONE_L, $00
        +ayWrite AY_PSG1, AY_CHB_TONE_H, $00
        +ayWrite AY_PSG1, AY_CHB_TONE_L, $00
        +ayWrite AY_PSG1, AY_CHC_TONE_H, $00
        +ayWrite AY_PSG1, AY_CHC_TONE_L, $00
        +ayWrite AY_PSG1, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG1, AY_ENV_PERIOD_H, $00
        +ayWrite AY_PSG1, AY_ENV_SHAPE, $00
        +ayWrite AY_PSG1, AY_NOISE_GEN, $00
        rts
