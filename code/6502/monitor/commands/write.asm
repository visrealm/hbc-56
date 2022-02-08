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
; write contiguous bytes to a range of addresses
; -----------------------------------------------------------------------------
writeCommand:
        lda CURR_ADDR
        sta TEMP_ADDR
        lda CURR_ADDR + 1
        sta TEMP_ADDR + 1
@nextByte
        lda #'+'
        cmp COMMAND_BUFFER,x
        beq @updateCurrent

        jsr readHexByte

        jsr hexToAcc
        sta (TEMP_ADDR)
        +inc16 TEMP_ADDR        
        cpx COMMAND_LEN
        bcc @nextByte
        jmp commandLoop

@updateCurrent
        lda TEMP_ADDR
        sta CURR_ADDR
        lda TEMP_ADDR + 1
        sta CURR_ADDR + 1
        jmp commandLoop


; -----------------------------------------------------------------------------
; send bytes to a single address (port)
; -----------------------------------------------------------------------------
sendCommand:
        jsr readHexByte
        jsr hexToAcc
        sta (CURR_ADDR)
        cpx COMMAND_LEN
        bcc sendCommand
        jmp commandLoop
