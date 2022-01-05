; Troy's HBC-56 - BASIC - Output (TMS9918)
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

FG     = TMS_WHITE
BG     = TMS_DK_BLUE
BORDER = TMS_LT_BLUE

; -----------------------------------------------------------------------------
; hbc56SetupDisplay - Setup the display (TMS9918)
; -----------------------------------------------------------------------------
hbc56SetupDisplay:
        +tmsColorFgBg FG, BORDER
        jsr tmsSetBackground
        +tmsColorFgBg FG, BG
        jsr tmsInitEntireColorTable

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
        stx SAVE_X              ; save registers
        sty SAVE_Y
        sta SAVE_A

        cmp #$07        ; bell (error beep)
        beq .bellOut

        ; output 'A' to console
        jsr tmsConsoleOut

.endOut:
        ldx SAVE_X              ; restore registers
        ldy SAVE_Y
        lda SAVE_A
        rts

.bellOut
        jsr hbc56Bell
        jmp .endOut