; Troy's HBC-56 - Monitor
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; -----------------------------------------------------------------------------
; clear the screen
; -----------------------------------------------------------------------------
clearCommand:
!if UART {
        +outputStringAddr clearCommandBytes
} 
!if TMS {
        jsr tmsInitTextTable ; clear output
        jsr tmsConsoleHome
}
        jmp commandLoop


clearCommandBytes:
        !text $1b,"[2J",$1b,"[H",0