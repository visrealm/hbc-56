; 6502 - AY-3-819x PSG
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "sfx/ay3891x.inc"


!ifndef AY_IO_PORT { AY_IO_PORT = $40
        !warn "AY_IO_PORT not provided. Defaulting to ", AY_IO_PORT
}

HAVE_AY3891X = 1

; -------------------------
; Constants
; -------------------------
AY_PSG0 = $00
AY_PSG1 = $04

; IO Ports
AY_S0 = IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_PSG0
AY_S1 = IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_PSG1

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

AY_ENV_SHAPE_CONTINUE  = $08
AY_ENV_SHAPE_ATTACK    = $04
AY_ENV_SHAPE_ALTERNATE = $02
AY_ENV_SHAPE_HOLD      = $01

;  /\  /\  /\  /\  /\ 
; /  \/  \/  \/  \/  \
AY_ENV_SHAPE_TRIANGLE     = (AY_ENV_SHAPE_CONTINUE | AY_ENV_SHAPE_ATTACK | AY_ENV_SHAPE_ALTERNATE)

;  /------------------
; /
AY_ENV_SHAPE_FADE_IN      = (AY_ENV_SHAPE_CONTINUE | AY_ENV_SHAPE_ATTACK | AY_ENV_SHAPE_HOLD)

; \
;  \__________________
AY_ENV_SHAPE_FADE_OUT     = (AY_ENV_SHAPE_CONTINUE | AY_ENV_SHAPE_HOLD)

; \ |\ |\ |\ |\ |\ |\ |
;  \| \| \| \| \| \| \|
AY_ENV_SHAPE_SAW1         = (AY_ENV_SHAPE_CONTINUE)

;  /| /| /| /| /| /| /|
; / |/ |/ |/ |/ |/ |/ |
AY_ENV_SHAPE_SAW2         = (AY_ENV_SHAPE_CONTINUE | AY_ENV_SHAPE_ATTACK)

;  /|
; / |__________________
AY_ENV_SHAPE_FADE_IN_STOP = (AY_ENV_SHAPE_ATTACK)


AY_CLOCK_FREQ   = 2000000

ayInit:
        ; disable everything
        +ayWrite AY_PSG0, AY_ENABLES, $ff
        +ayWrite AY_PSG1, AY_ENABLES, $ff

        +aySetVolume AY_PSG0, AY_CHA, 0
        +aySetVolume AY_PSG0, AY_CHB, 0
        +aySetVolume AY_PSG0, AY_CHC, 0

        +ayPlayNote AY_PSG0, AY_CHA, 0
        +ayPlayNote AY_PSG0, AY_CHB, 0
        +ayPlayNote AY_PSG0, AY_CHC, 0

        +aySetEnvelopePeriod AY_PSG0, 0
        +aySetEnvShape AY_PSG0, 0
        +aySetNoise  AY_PSG0, 0

        +aySetVolume AY_PSG1, AY_CHA, 0
        +aySetVolume AY_PSG1, AY_CHB, 0
        +aySetVolume AY_PSG1, AY_CHC, 0

        +ayPlayNote AY_PSG1, AY_CHA, 0
        +ayPlayNote AY_PSG1, AY_CHB, 0
        +ayPlayNote AY_PSG1, AY_CHC, 0

        +aySetEnvelopePeriod AY_PSG1, 0
        +aySetEnvShape AY_PSG1, 0
        +aySetNoise  AY_PSG1, 0

        rts


 NOTE_B0  = 31
 NOTE_C1  = 33
 NOTE_CS1 = 35
 NOTE_D1  = 37
 NOTE_DS1 = 39
 NOTE_E1  = 41
 NOTE_F1  = 44
 NOTE_FS1 = 46
 NOTE_G1  = 49
 NOTE_GS1 = 52
 NOTE_A1  = 55
 NOTE_AS1 = 58
 NOTE_B1  = 62
 NOTE_C2  = 65
 NOTE_CS2 = 69
 NOTE_D2  = 73
 NOTE_DS2 = 78
 NOTE_E2  = 82
 NOTE_F2  = 87
 NOTE_FS2 = 93
 NOTE_G2  = 98
 NOTE_GS2 = 104
 NOTE_A2  = 110
 NOTE_AS2 = 117
 NOTE_B2  = 123
 NOTE_C3  = 131
 NOTE_CS3 = 139
 NOTE_D3  = 147
 NOTE_DS3 = 156
 NOTE_E3  = 165
 NOTE_F3  = 175
 NOTE_FS3 = 185
 NOTE_G3  = 196
 NOTE_GS3 = 208
 NOTE_A3  = 220
 NOTE_AS3 = 233
 NOTE_B3  = 247
 NOTE_C4  = 262
 NOTE_CS4 = 277
 NOTE_D4  = 294
 NOTE_DS4 = 311
 NOTE_E4  = 330
 NOTE_F4  = 349
 NOTE_FS4 = 370
 NOTE_G4  = 392
 NOTE_GS4 = 415
 NOTE_A4  = 440
 NOTE_AS4 = 466
 NOTE_B4  = 494
 NOTE_C5  = 523
 NOTE_CS5 = 554
 NOTE_D5  = 587
 NOTE_DS5 = 622
 NOTE_E5  = 659
 NOTE_F5  = 698
 NOTE_FS5 = 740
 NOTE_G5  = 784
 NOTE_GS5 = 831
 NOTE_A5  = 880
 NOTE_AS5 = 932
 NOTE_B5  = 988
 NOTE_C6  = 1047
 NOTE_CS6 = 1109
 NOTE_D6  = 1175
 NOTE_DS6 = 1245
 NOTE_E6  = 1319
 NOTE_F6  = 1397
 NOTE_FS6 = 1480
 NOTE_G6  = 1568
 NOTE_GS6 = 1661
 NOTE_A6  = 1760
 NOTE_AS6 = 1865
 NOTE_B6  = 1976
 NOTE_C7  = 2093
 NOTE_CS7 = 2217
 NOTE_D7  = 2349
 NOTE_DS7 = 2489
 NOTE_E7  = 2637
 NOTE_F7  = 2794
 NOTE_FS7 = 2960
 NOTE_G7  = 3136
 NOTE_GS7 = 3322
 NOTE_A7  = 3520
 NOTE_AS7 = 3729
 NOTE_B7  = 3951
 NOTE_C8  = 4186
 NOTE_CS8 = 4435
 NOTE_D8  = 4699
 NOTE_DS8 = 4978

