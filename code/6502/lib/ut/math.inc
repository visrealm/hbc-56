; 6502
;
; Math macros
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

HAVE_MATH_INC = 1

!macro lsr2 {
        lsr
        lsr
}

!macro lsr3 {
        +lsr2
        lsr
}

!macro lsr4 {
        +lsr3
        lsr
}

!macro lsr5 {
        +lsr4
        lsr
}

!macro lsr6 {
        +lsr5
        lsr
}

!macro lsr7 {
        +lsr6
        lsr
}

!macro div2   { lsr }
!macro div4   { +lsr2 }
!macro div8   { +lsr3 }
!macro div16  { +lsr4 }
!macro div32  { +lsr5 }
!macro div64  { +lsr6 }
!macro div128 { +lsr7 }

!macro asl2 {
        asl
        asl
}

!macro asl3 {
        +asl2
        asl
}

!macro asl4 {
        +asl3
        asl
}

!macro asl5 {
        +asl4
        asl
}

!macro asl6 {
        +asl5
        asl
}

!macro asl7 {
        +asl6
        asl
}

!macro mul2   { asl }
!macro mul4   { +asl2 }
!macro mul8   { +asl3 }
!macro mul16  { +asl4 }
!macro mul32  { +asl5 }
!macro mul64  { +asl6 }
!macro mul128 { +asl7 }



; -----------------------------------------------------------------------------
; +dec16: decement a 16-bit value
; -----------------------------------------------------------------------------
; Inputs:
;  addr: address containing LSB of value to decrement
; -----------------------------------------------------------------------------
!macro dec16 .addr {
  lda .addr
  bne +
  dec .addr + 1
+
  dec .addr
}

; -----------------------------------------------------------------------------
; +inc16: increment a 16-bit value
; -----------------------------------------------------------------------------
; Inputs:
;  addr: address containing LSB of value to increment
; -----------------------------------------------------------------------------
!macro inc16 .addr {
  inc .addr
  bne +
  inc .addr + 1
+
}

; -----------------------------------------------------------------------------
; +cmp16: compare two 16-bit values in memory
; -----------------------------------------------------------------------------
; Inputs:
;  left:  address containing LSB of left value to comapre
;  right: address containing LSB of right value to comapre
; Outputs:
;  C set if right < left
;  Z set if right == left
; -----------------------------------------------------------------------------
!macro cmp16 .left, .right {
  lda .left + 1
  cmp .right + 1
  bne +
  lda .left
  cmp .right
+
}

; -----------------------------------------------------------------------------
; +cmp16i: compare a 16-bit values in memory with an immediate value
; -----------------------------------------------------------------------------
; Inputs:
;  .addr: address containing LSB
;  .imm:  immediate value to compare to
; Outputs:
;  C set if right < left
;  Z set if right == left
; -----------------------------------------------------------------------------
!macro cmp16i .addr, .imm {
  lda .addr + 1
  cmp #>.imm
  bne +
  lda .addr
  cmp #<.imm
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
!macro cmp16xa .value {
  cpx #>.value
  bne +
  cmp #<.value
+
}


; -----------------------------------------------------------------------------
; +beq16: Branch if a 16-bit value is zero
; -----------------------------------------------------------------------------
; Inputs:
;  addr:     address to check
;  location: branch address if value is zero
; -----------------------------------------------------------------------------
!macro beq16 .addr, .location {
  lda .addr
  bne +
  lda .addr + 1
  beq .location
+
}


; -----------------------------------------------------------------------------
; +bne16: Branch if a 16-bit value is not zero
; -----------------------------------------------------------------------------
; Inputs:
;  addr:     address to check
;  location: branch address if value is not zero
; -----------------------------------------------------------------------------
!macro bne16 .addr, .location {
  lda .addr
  bne .location
  lda .addr + 1
  bne .location
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
!macro sub16 .left, .right, .res {
  sec
  lda .left
  sbc .right
  sta .res
  lda .left + 1
  sbc .right + 1
  sta .res + 1
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
!macro sub16 .left, .right {
  sec
  lda .left
  sbc .right
  tax
  lda .left + 1
  sbc .right + 1
}


; -----------------------------------------------------------------------------
; +add16: add 16 bit numbers - result in ax registers
; -----------------------------------------------------------------------------
; Inputs:
;  left:  address containing LSB of left value
;  right: address containing LSB of right value
; Outputs:
;  a:     result msb
;  x:     result lsb
; -----------------------------------------------------------------------------
!macro add16 .left, .right {
  clc
  lda .left
  adc .right
  tax
  lda .left + 1
  adc .right + 1
}


; -----------------------------------------------------------------------------
; +add16Imm: add 16 bit numbers - result stored to res
; -----------------------------------------------------------------------------
; Inputs:
;  left:  address containing LSB of left value
;  imm:   immediate value to add
; Outputs:
;  res: address to store result
; -----------------------------------------------------------------------------
!macro add16Imm .left, .imm, .res {
  clc
  lda .left
  adc #<.imm
  sta .res
  lda .left + 1
  adc #>.imm
  sta .res + 1
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
!macro subImm8From16 .left, .right, .res {
  sec
  lda .left
  sbc #.right
  sta .res
  lda .left + 1
  sbc #0
  sta .res + 1
}

; -----------------------------------------------------------------------------
; +incBcd: increment a BCD byte (inc instruction doesn't work in bcd mode)
; -----------------------------------------------------------------------------
; Inputs:
;  addr:  address containing BCD value
; -----------------------------------------------------------------------------
!macro incBcd .addr {
  lda .addr
  sed
  clc
  adc #1
  cld
  sta .addr
}

; -----------------------------------------------------------------------------
; +decBcd: decrement a BCD byte (inc instruction doesn't work in bcd mode)
; -----------------------------------------------------------------------------
; Inputs:
;  addr:  address containing BCD value
; -----------------------------------------------------------------------------
!macro decBcd .addr {
  lda .addr
  sed
  sec
  sbc #1
  cld
  sta .addr
}