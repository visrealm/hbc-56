; 6502 - HBC-56 Kernel Include file for user code
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

!cpu w65c02
!initmem $FF
cputype = $65c02

!src "kernel.o.lmap"

!src "ut/math.inc"
!src "ut/memory.inc"
!src "gfx/tms9918.inc"
!src "gfx/tilemap.inc"
!src "lcd/lcd.inc"
!src "inp/nes.inc"
!src "inp/keyboard.inc"
!src "sfx/ay3891x.inc"
!src "ser/uart.inc"
!src "kernel.inc"

!ifndef HBC_56_EXCLUDE_KERNEL_ROM {

        ; if the program requires the kernal image
        ; then... include it

        *=HBC56_META_VECTOR
        !ifdef hbc56Meta {
                jmp hbc56Meta
        } else {
                rts
        }

        *=HBC56_KERNEL_START
        !bin "kernel.o"

        *=DEFAULT_HBC56_RST_VECTOR
        jmp hbc56Main

} else {

        ; otherwise, place the program in RAM

        *=$0400
}