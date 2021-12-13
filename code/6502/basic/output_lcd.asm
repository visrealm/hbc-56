; Troy's HBC-56 - BASIC - Output (LCD)
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


LCD_BUFFER_ADDR  = $7d00                ; temp buffer for copies

!src "lcd/lcd.asm"                      ; lcd library


; -----------------------------------------------------------------------------
; hbc56SetupDisplay - Setup the display (LCD)
; -----------------------------------------------------------------------------
hbc56SetupDisplay:
        jsr lcdInit
        jsr lcdDisplayOn
        jsr lcdCursorBlinkOn
        rts

; -----------------------------------------------------------------------------
; hbc56Out - EhBASIC output subroutine (for HBC-56 LCD)
; -----------------------------------------------------------------------------
; Inputs:       A - ASCII character (or code) to output
; Outputs:      A - must be maintained
; -----------------------------------------------------------------------------
hbc56Out:
        sei     ; disable interrupts during output
        stx SAVE_X
        sty SAVE_Y
        sta SAVE_A
        cmp #ASCII_RETURN
        beq .newline
        cmp #ASCII_BACKSPACE
        beq .backspace

        cmp #ASCII_BELL ; bell (end of buffer)
        beq .bellOut

        cmp #ASCII_CR   ; omit these
        beq .endOut

        ; regular character
        jsr lcdCharScroll ; outputs A to the LCD - auto-scrolls too :)


.endOut:
        ldx SAVE_X
        ldy SAVE_Y
        lda SAVE_A
        cli
        rts

.bellOut
        jsr hbc56Bell
        jmp .endOut


.newline
        jsr lcdNextLine ; scroll to the next line... scroll screen if on last line
        jmp .endOut

.backspace
        jsr lcdBackspace 
        jmp .endOut
	rts
