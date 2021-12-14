; 6502 - AY-3-819x PSG
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;



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

!macro ayPlayNoteDur .dev, .chan, .freq, .duration {
        .val = AY_CLOCK_FREQ / (16.0 * .freq)
        +ayWrite AY_PSG0, AY_CHA_AMPL, $00
        +ayWrite AY_PSG0, AY_CHB_AMPL, $00
        +ayWrite AY_PSG0, AY_CHC_AMPL, $0f
        +ayWrite AY_PSG0, AY_ENV_PERIOD_L, $00
        +ayWrite AY_PSG0, AY_ENV_PERIOD_H, $80;.duration
        +ayWrite AY_PSG0, AY_ENV_SHAPE, $0e

        +ayWrite .dev, AY_CHA_TONE_L + (.chan * 2), <.val
        +ayWrite .dev, AY_CHA_TONE_H + (.chan * 2), >.val
        +ayWrite AY_PSG0, AY_ENABLES, $3b
}


!macro ayStop .dev, .chan {
        +ayWrite .dev, AY_CHA_TONE_L + (.chan * 2), 0
        +ayWrite .dev, AY_CHA_TONE_H + (.chan * 2), 0
}
