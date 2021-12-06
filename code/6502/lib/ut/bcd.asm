; 6502 - BCD subroutines
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;


; -----------------------------------------------------------------------------
; bin2bcd8: convert an unsigned byte to a 2-digit bcd value
; -----------------------------------------------------------------------------
; Inputs:
;   A: value
; Outputs:
;   BCD value in R8
; -----------------------------------------------------------------------------
bin2bcd8:
  sta R7L
  lda #0
  sta R8L
  sta R8H
  ldx #8 
  sed    
.loop:
  asl R7L
  lda R8L
  adc R8L
  sta R8L
  lda R8H
  adc R8H
  sta R8H
  dex
  bne .loop
  cld   
  rts

