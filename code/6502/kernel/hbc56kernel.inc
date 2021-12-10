; 6502 - HBC-56 Kernel Include file for user code
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
!src "ut/memory_macros.asm"
!src "gfx/tms9918_macros.asm"
!src "inp/nes_macros.asm"
!src "inp/keyboard_macros.asm"
!src "kernel_macros.asm"

*=HBC56_META_VECTOR
!ifdef hbc56Meta {
        jmp hbc56Meta
} else {
        rts
}

*=$f000
!bin "kernel.o"

*=DEFAULT_HBC56_RST_VECTOR
jmp hbc56Main
