; 6502 - MC68B50 UART Macros
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

; -----------------------------------------------------------------------------
; uartOutStringAddr: Output a string to the uart
; -----------------------------------------------------------------------------
; Inputs:
;  .addr: Address of null-terminated string to print
; -----------------------------------------------------------------------------
!macro uartOutStringAddr .addr {
        lda #<.addr
        sta STR_ADDR_L
        lda #>.addr
        sta STR_ADDR_H
        jsr uartOutString        
}


; -----------------------------------------------------------------------------
; uartOutString: Output an immediate string to the uart
; -----------------------------------------------------------------------------
; Inputs:
;  .str: String to output
; -----------------------------------------------------------------------------
!macro uartOutString .str {
	jmp @afterText
@textAddr
	!text .str,0
@afterText        
        +uartOutStringAddr @textAddr
}

