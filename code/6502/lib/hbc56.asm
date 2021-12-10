; 6502 - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

!cpu 6502
!initmem $FF
cputype = $6502

!src "hbc56.inc"

; -------------------------
; Zero page
; -------------------------
STR_ADDR = $18
STR_ADDR_L = STR_ADDR
STR_ADDR_H = STR_ADDR + 1

DEFAULT_HBC56_NMI_VECTOR = $FFE0
DEFAULT_HBC56_RST_VECTOR = $8000
DEFAULT_HBC56_INT_VECTOR = $FFE0

!macro hbc56Title .title {
HBC56_TITLE_TEXT:
        !text .title
HBC56_TITLE_TEXT_LEN = * - HBC56_TITLE_TEXT
        !byte 0 ; nul terminator for game name
}


*=DEFAULT_HBC56_INT_VECTOR
        rti

hbc56Delay:
	ldy #0
hbc56CustomDelay:
	ldx #0
-
	dex
	bne -
	ldx #0
	dey
	bne -
	rts


*=$FFFA
!ifdef HBC56_NMI_VECTOR { !word HBC56_NMI_VECTOR } else { !word DEFAULT_HBC56_NMI_VECTOR }
!ifdef HBC56_RST_VECTOR { !word HBC56_RST_VECTOR } else { !word DEFAULT_HBC56_RST_VECTOR }
!ifdef HBC56_INT_VECTOR { !word HBC56_INT_VECTOR } else { !word DEFAULT_HBC56_INT_VECTOR }


*=DEFAULT_HBC56_RST_VECTOR
