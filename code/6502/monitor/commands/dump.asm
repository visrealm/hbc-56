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
; dump a page of data from the current address
; -----------------------------------------------------------------------------
dumpCommand:
        phx
        +outputStringAddr dumpHeader
        plx

        ldy #0
        stz TMP_C

        lda CURR_ADDR
        and #$f8
        sta DUMP_ROW_START_L
        lda CURR_ADDR_H
        sta DUMP_ROW_START_H

        ldx #1
        cpx COMMAND_LEN
        beq @newLine
        jsr readHexByte
        jsr hexToAcc
        sta TMP_C        

@newLine
        lda #$0d
        +outputA
        lda #'$'
        +outputA
        tya
        clc
        adc CURR_ADDR
        sta TEMP_ADDR
        lda CURR_ADDR_H
        bcc +
        inc 
        sta TEMP_ADDR_H
+
        jsr outHex8
        lda TEMP_ADDR
        jsr outHex8
        lda #':'
        +outputA
        ldx #0

@nextByte
        lda #' '
        +outputA
        lda (CURR_ADDR),y
        sta COMMAND_BUFFER,x
        inx
        jsr outHex8
        iny
        cpy TMP_C
        beq @doRaw
        tya
        and #$07
        bne @nextByte

@doRaw
        lda #' '
        +outputA
        ldx #0
-
        lda COMMAND_BUFFER,x
        cmp #' '
        bcs +
        lda #'.'
+
        cmp #'~'
        bcc +
        lda #'.'
+
        +outputA
        inx
        cpx #8
        bne -
        cpy TMP_C
        bne @newLine

@endDump
        lda #$0d
        +outputA
        jmp commandLoop

