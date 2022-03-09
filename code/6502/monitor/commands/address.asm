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
; change the current address
; -----------------------------------------------------------------------------
addressCommand:
        lda COMMAND_BUFFER+1
        sta HEX_H
        lda COMMAND_BUFFER+2
        sta HEX_L
        jsr hexToAcc

        sta CURR_ADDR_H
        lda COMMAND_BUFFER+3
        sta HEX_H
        lda COMMAND_BUFFER+4
        sta HEX_L
        jsr hexToAcc
        
        sta CURR_ADDR

        lda COMMAND_LEN
        cmp #6
        bcc +
        ldx #6
        jmp nextCommand
+
        jmp commandLoop
