; 6502 - Sound manager
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!macro sfxManSetTimeout ticks, timeout {
        +add16Imm SFXMAN_TICKS, ticks, timeout
}

!macro sfxManSetChannelTimeout  .dev, .chan, .seconds {
        .ticks = (.seconds * TMS_FPS)

        !if .dev = AY_PSG0 {                
                !if .chan = AY_CHA {
                        +sfxManSetTimeout .ticks, CH0_TIMEOUT
                }
                !if .chan = AY_CHB {
                        +sfxManSetTimeout .ticks, CH1_TIMEOUT
                }
                !if .chan = AY_CHC {
                        +sfxManSetTimeout .ticks, CH2_TIMEOUT
                }
                !if .chan = AY_CHN {
                        +sfxManSetTimeout .ticks, NOISE0_TIMEOUT
                }
        }

        !if .dev = AY_PSG1 {                
                !if .chan = AY_CHA {
                        +sfxManSetTimeout .ticks, CH3_TIMEOUT
                }
                !if .chan = AY_CHB {
                        +sfxManSetTimeout .ticks, CH4_TIMEOUT
                }
                !if .chan = AY_CHC {
                        +sfxManSetTimeout .ticks, CH5_TIMEOUT
                }
                !if .chan = AY_CHN {
                        +sfxManSetTimeout .ticks, NOISE1_TIMEOUT
                }
        }
}
