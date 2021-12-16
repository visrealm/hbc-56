; 6502 LCD Macros - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

; -----------------------------------------------------------------------------
; lcdPrint: Print immediate text
; -----------------------------------------------------------------------------
; Inputs:
;  str: String to print
; -----------------------------------------------------------------------------
!macro lcdPrint str {
	jmp +
.textAddr
	!text str,0
+
	lda #<.textAddr
	sta STR_ADDR_L
	lda #>.textAddr
	sta STR_ADDR_H
	jsr lcdPrint
}


; -----------------------------------------------------------------------------
; lcdChar: Print immediate character
; -----------------------------------------------------------------------------
; Inputs:
;  c: Character to print
; -----------------------------------------------------------------------------
!macro lcdChar c {
	pha
	lda #c
	jsr lcdChar
	pla
}


; -----------------------------------------------------------------------------
; lcdConsolePrint: Print immediate text to console
; -----------------------------------------------------------------------------
; Inputs:
;  str: String to print
; -----------------------------------------------------------------------------
!macro lcdConsolePrint .str {
	jmp .afterText
.textAddr
	!text .str,0
.afterText        

        lda #<.textAddr
        sta STR_ADDR_L
        lda #>.textAddr
        sta STR_ADDR_H
        jsr lcdConsolePrint        
}