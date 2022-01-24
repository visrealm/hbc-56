; 6502 - MC68B50 UART Macros
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!macro uartOutStringAddr .addr {
        lda #<.addr
        sta STR_ADDR_L
        lda #>.addr
        sta STR_ADDR_H
        jsr uartOutString        
}


!macro uartOutString .str {
	jmp @afterText
@textAddr
	!text .str,0
@afterText        
        +uartOutStringAddr @textAddr
}

