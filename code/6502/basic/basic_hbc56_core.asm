; Troy's HBC-56 - BASIC
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

!src "ehbasic/basic.asm"        ; EhBASIC

; For saving registers
SAVE_X          = HBC56_USER_ZP_START
SAVE_Y          = HBC56_USER_ZP_START + 1
SAVE_A          = HBC56_USER_ZP_START + 2

BASIC_XPOS = HBC56_USER_ZP_START + 4
BASIC_YPOS = HBC56_USER_ZP_START + 5

; put the IRQ and NMI code in RAM so that it can be changed
IRQ_vec         = VEC_SV+2      ; IRQ code vector
NMI_vec         = IRQ_vec+$0A   ; NMI code vector

; -----------------------------------------------------------------------------
; main entry point
; -----------------------------------------------------------------------------
hbc56Main:
RES_vec:
        jsr hbc56SetupDisplay

        ; copy I/O vectors
        ldy #END_CODE - LAB_vec - 1    ; set index/count
LAB_stlp
        lda LAB_vec, Y         ; get byte from interrupt code
        sta VEC_CC, Y            ; save to RAM
        dey
        bpl LAB_stlp

        cli                        ; enable interrupts

        jmp LAB_COLD

; -----------------------------------------------------------------------------
; hybc56Load - EhBASIC load subroutine (for HBC-56)   (TBA)
; -----------------------------------------------------------------------------
hbc56Load
        rts

; -----------------------------------------------------------------------------
; hybc56Save - EhBASIC save subroutine (for HBC-56)   (TBA)
; -----------------------------------------------------------------------------
hbc56Save
        rts

; -----------------------------------------------------------------------------
; vector table - gets copied to VEC_IN in RAM
; -----------------------------------------------------------------------------
LAB_vec
    !word    hbc56In         ; check for break (Ctrl+C)
    !word    hbc56In            ; byte in from keyboard
    !word    hbc56Out           ; byte out to screen
    !word    hbc56Load          ; load vector for EhBASIC
    !word    hbc56Save          ; save vector for EhBASIC

END_CODE        ; so we know when to stop copying
