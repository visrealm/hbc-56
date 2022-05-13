; 6502 - BCD subroutines
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;


!ifndef BCD_RAM_START { BCD_RAM_START = $7810
        !warn "BCD_RAM_START not provided. Defaulting to ", BCD_RAM_START
}

; -------------------------
; High RAM
; -------------------------
BCD_TMP1	= BCD_RAM_START
BCD_TMP2	= BCD_RAM_START + 1
BCD_TMP3	= BCD_RAM_START + 2
.BCD_RAM_SIZE	= 3

!if BCD_RAM_END < (BCD_RAM_START + .BCD_RAM_SIZE) {
	!error "BCD_RAM requires ",BCD_RAM_SIZE," bytes. Allocated ",BCD_RAM_END - BCD_RAM_START
}


; -----------------------------------------------------------------------------
; bin2bcd8: convert an unsigned byte to a 2-digit bcd value
; -----------------------------------------------------------------------------
; Inputs:
;   A: value
; Outputs:
;   BCD value in R8
; -----------------------------------------------------------------------------
bin2bcd8:
  sta BCD_TMP1
  lda #0
  sta BCD_TMP2
  sta BCD_TMP3
  ldx #8 
  sed    
.loop:
  asl BCD_TMP1
  lda BCD_TMP2
  adc BCD_TMP2
  sta BCD_TMP2
  lda BCD_TMP3
  adc BCD_TMP3
  sta BCD_TMP3
  dex
  bne .loop
  cld   
  rts

