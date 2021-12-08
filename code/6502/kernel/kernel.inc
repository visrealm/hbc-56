; 6502 - HBC-56 Kernel
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

!src "kernel.o.lmap"

!src "ut/math_macros.asm"
!src "gfx/tms9918macros.asm"

!macro setIntHandler .address {
        lda #<.address
        sta HBC56_INT_VECTOR + 1
        lda #>.address
        sta HBC56_INT_VECTOR + 2
        lda #JMP_OPCODE
        sta HBC56_INT_VECTOR
}

!macro setNmiHandler .address {
        lda #<.address
        sta HBC56_NMI_VECTOR + 1
        lda #>.address
        sta HBC56_NMI_VECTOR + 2
        lda #JMP_OPCODE
        sta HBC56_NMI_VECTOR
}


*=$f000
!bin "kernel.o"

*=DEFAULT_HBC56_RST_VECTOR
jmp main
