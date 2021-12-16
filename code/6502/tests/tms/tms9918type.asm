; Troy's HBC-56 - TMS9918 Console mode test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

hbc56Meta:
        +setHbcMetaTitle "CONSOLE TEST"
        rts

hbc56Main:
        sei
        jsr kbInit

        jsr tmsModeText

        +tmsSetColorFgBg TMS_LT_GREEN, TMS_BLACK
        +tmsEnableOutput
        cli

        +tmsEnableInterrupts

        +consoleEnableCursor


.consoleLoop:
        jsr kbReadAscii
        bcc .consoleLoop

        ; output 'A' to console
        jsr tmsConsoleOut

        jmp .consoleLoop
