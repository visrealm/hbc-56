; Troy's HBC-56 - Monitor
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

!src "kernel.o.lmap"

*=$1000
        ldx #8
-
        lda #<mystring
        sta STR_ADDR_L
        lda #>mystring
        sta STR_ADDR_H
        jsr uartOutString
        dex
        bne -
        rts

mystring:
!text "Hello HBC-56 Monitor\n",0