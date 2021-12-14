; Troy's HBC-56 - BASIC - Output (TMS9918)
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

; -----------------------------------------------------------------------------
; hbc56SetupDisplay - Setup the display (TMS9918)
; -----------------------------------------------------------------------------
hbc56SetupDisplay:
        jsr tmsModeText         ; set display to text mode

        +tmsSetAddrNameTable    ; clear the display
        lda #' '
        ldx #(40 * 25 / 8)
        jsr _tmsSendX8

        +tmsSetColorFgBg TMS_CYAN,TMS_BLACK

        +tmsEnableInterrupts    ; gives us the console cursor, etc.
        +tmsEnableOutput

        +consoleEnableCursor
        rts

; -----------------------------------------------------------------------------
; hbc56Out - EhBASIC output subroutine (for HBC-56 TMS9918)
; -----------------------------------------------------------------------------
; Inputs:       A - ASCII character (or code) to output
; Outputs:      A - must be maintained
; -----------------------------------------------------------------------------
hbc56Out:
        sei                     ; disable interrupts during output
        stx SAVE_X              ; save registers
        sty SAVE_Y
        sta SAVE_A

        cmp #ASCII_RETURN       ; return?
        beq .newline

        cmp #ASCII_BACKSPACE    ; backspace?
        beq .backspace

        jsr tmsSetPosConsole    ; regular character
        lda SAVE_A

        cmp #$07        ; bell (end of buffer)
        beq .bellOut

        +tmsPut
        jsr tmsIncPosConsole    ; increment display position

.endOut:
        ldx SAVE_X              ; restore registers
        ldy SAVE_Y
        lda SAVE_A
        cli                     ; enable interrupts
        rts

.bellOut
        jsr hbc56Bell
        jmp .endOut

.newline                        ; handle newline character
        +tmsConsoleOut ' '
        lda #39
        sta TMS9918_CONSOLE_X
        jsr tmsIncPosConsole
        jmp .endOut

.backspace                      ; handle newline character
        +tmsConsoleOut ' '      ; clear cursor
        jsr tmsDecPosConsole
        jsr tmsDecPosConsole
        +tmsConsoleOut ' '
        jsr tmsDecPosConsole
        jmp .endOut

