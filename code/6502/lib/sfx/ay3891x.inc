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
        sta IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_ADDR | .dev
        lda #.val
        sta IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_WRITE | .dev
}        

!macro ayRead .dev, .reg {
        lda #.reg
        sta IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_ADDR | .dev
        lda IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_READ | .dev
}        


!macro ayWriteX .dev, .reg {
        lda #.reg
        sta IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_ADDR | .dev
        stx IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_WRITE | .dev
}

!macro ayWriteA .dev, .reg {
        ldx #.reg
        stx IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_ADDR | .dev
        sta IO_PORT_BASE_ADDRESS | AY_IO_PORT | AY_WRITE | .dev
}

!macro ayPlayNote .dev, .chan, .freq {
        !if .freq <= 0 {
                .val = 0
        } else {
                .val = AY_CLOCK_FREQ / (16.0 * .freq)
        }
        +ayWrite .dev, AY_CHA_TONE_L + (.chan * 2), <.val
        +ayWrite .dev, AY_CHA_TONE_H + (.chan * 2), >.val
}

!macro ayToneWordPeriod .periodHz {
        !word ((AY_CLOCK_FREQ * .periodHz) / 16.0)
}

!macro ayToneWord .freq {
        !word (AY_CLOCK_FREQ / (16.0 * .freq))
}

!macro ayToneByteL .freq {
        !byte <(AY_CLOCK_FREQ / (16.0 * .freq))
}

!macro ayToneByteH .freq {
        !byte >(AY_CLOCK_FREQ / (16.0 * .freq))
}


!macro ayToneEnable .dev, .chan {
        +ayRead .dev, AY_ENABLES
        and #!($01 << .chan)
        +ayWriteA .dev, AY_ENABLES
}

!macro ayToneDisable .dev, .chan {
        +ayRead .dev, AY_ENABLES
        ora #($01 << .chan)
        +ayWriteA .dev, AY_ENABLES
}

!macro ayNoiseEnable .dev, .chan {
        +ayRead .dev, AY_ENABLES
        eor #($08 << .chan)
        +ayWriteA .dev, AY_ENABLES
}

!macro ayNoiseDisable .dev, .chan {
        +ayRead .dev, AY_ENABLES
        ora #($08 << .chan)
        +ayWriteA .dev, AY_ENABLES
}

!macro aySetVolume .dev, .chan, .vol {
        +ayWrite .dev, (AY_CHA_AMPL + .chan), (.vol >> 4)
}

!macro aySetVolumeAcc .dev, .chan {
        +ayWriteA .dev, (AY_CHA_AMPL + .chan)
}

!macro aySetVolumeEnvelope .dev, .chan {
        +ayWrite .dev, (AY_CHA_AMPL + .chan), $10
}

!macro aySetEnvelopePeriod .dev, .period {
        +ayWrite .dev, AY_ENV_PERIOD_L, <.period
        +ayWrite .dev, AY_ENV_PERIOD_H, >.period
}

!macro aySetEnvShape .dev, .shape {
        +ayWrite .dev, AY_ENV_SHAPE, .shape
}

!macro aySetNoise .dev, .freq {
        +ayWrite .dev, AY_ENV_SHAPE, .freq >> 3
}

!macro ayStop .dev, .chan {
        +ayPlayNote .dev, .chan, 0
        +ayToneDisable .dev, .chan
}
