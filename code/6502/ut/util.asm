; 6502
;
; Utility subroutines and macros
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;


CMN_UTIL_ASM_ = 1


; -----------------------------------------------------------------------------
; +dec16: decement a 16-bit value
; -----------------------------------------------------------------------------
; Inputs:
;  addr: address containing LSB of value to decrement
; -----------------------------------------------------------------------------
!macro dec16 addr {
  lda addr
  bne +
  dec addr + 1
+
  dec addr
}

; -----------------------------------------------------------------------------
; +inc16: increment a 16-bit value
; -----------------------------------------------------------------------------
; Inputs:
;  addr: address containing LSB of value to increment
; -----------------------------------------------------------------------------
!macro inc16 addr {
  inc addr
  bne +
  inc addr + 1
+
}

; -----------------------------------------------------------------------------
; +cmp16: compare two 16-bit values in memory
; -----------------------------------------------------------------------------
; Inputs:
;  left:  address containing LSB of left value to comapre
;  right: address containing LSB of right value to comapre
; -----------------------------------------------------------------------------
!macro cmp16 left, right {
  lda left + 1
  cmp right + 1
	bne +
	lda left
	cmp right
+
}

; -----------------------------------------------------------------------------
; +cmp16: compare two 16-bit values in memory
; -----------------------------------------------------------------------------
; Inputs:
;  value: immediate value to compare
;  x:     msb
;  a:     lsb
; -----------------------------------------------------------------------------
!macro cmp16xa value {
  cpx #>value
	bne +
	cmp #<value
+
}

; -----------------------------------------------------------------------------
; +sub16: subtract 16 bit numbers
; -----------------------------------------------------------------------------
; Inputs:
;  left:  address containing LSB of left value
;  right: address containing LSB of right value
; Outputs:
;  res:   address containing LSB of result
; -----------------------------------------------------------------------------
!macro sub16 left, right, res {
  sec
  lda left
  sbc right
  sta res
  lda left + 1
  sbc right + 1
  sta res + 1
}

; -----------------------------------------------------------------------------
; +sub16: subtract 16 bit numbers - result in ax registers
; -----------------------------------------------------------------------------
; Inputs:
;  left:  address containing LSB of left value
;  right: address containing LSB of right value
; Outputs:
;  a:     result msb
;  x:     result lsb
; -----------------------------------------------------------------------------
!macro sub16 left, right {
  sec
  lda left
  sbc right
  tax
  lda left + 1
  sbc right + 1
}


; -----------------------------------------------------------------------------
; +subImm8From16: subtract an 8 bit number from a 16 bit number
; -----------------------------------------------------------------------------
; Inputs:
;  left:  address containing LSB of left value
;  right: immediate 8-bit value
; Outputs:
;  res:   address containing LSB of result
; -----------------------------------------------------------------------------
!macro subImm8From16 left, right, res {
  sec
  lda left
  sbc #right
  sta res
  lda left + 1
  sbc #0
  sta res + 1
}

; -----------------------------------------------------------------------------
; +incBcd: increment a BCD byte (inc instruction doesn't work in bcd mode)
; -----------------------------------------------------------------------------
; Inputs:
;  addr:  address containing BCD value
; -----------------------------------------------------------------------------
!macro incBcd addr {
  lda addr
  sed
  clc
  adc #1
  cld
  sta addr
}

; -----------------------------------------------------------------------------
; +decBcd: decrement a BCD byte (inc instruction doesn't work in bcd mode)
; -----------------------------------------------------------------------------
; Inputs:
;  addr:  address containing BCD value
; -----------------------------------------------------------------------------
!macro decBcd addr {
  lda addr
  sed
  sec
  sbc #1
  cld
  sta addr
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
  sta R7L
  stz R8L
  stz R8H
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

