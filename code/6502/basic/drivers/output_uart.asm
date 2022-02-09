; Troy's HBC-56 - BASIC - Output (UART)
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

; -----------------------------------------------------------------------------
; hbc56SetupDisplay - Setup the display (UART)
; -----------------------------------------------------------------------------
hbc56SetupDisplay:
        sei
        jsr uartInit
        +tmsDisableInterrupts
        +setIntHandler uartIrq
        rts

; -----------------------------------------------------------------------------
; hbc56Out - EhBASIC output subroutine (for HBC-56 TMS9918)
; -----------------------------------------------------------------------------
; Inputs:       A - ASCII character (or code) to output
; Outputs:      A - must be maintained
; -----------------------------------------------------------------------------
hbc56Out:
        jmp uartOut

