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
BASIC_COLOR = HBC56_USER_ZP_START + 6
BASIC_MODE = HBC56_USER_ZP_START + 7

LOAD_BYTE  = HBC56_USER_ZP_START + 8

; put the IRQ and NMI code in RAM so that it can be changed
IRQ_vec         = VEC_SV+2      ; IRQ code vector
NMI_vec         = IRQ_vec+$0A   ; NMI code vector

FG     = TMS_DK_BLUE
BG     = TMS_WHITE
BORDER = TMS_DK_BLUE

; -----------------------------------------------------------------------------
; main entry point
; -----------------------------------------------------------------------------
hbc56Main:
RES_vec:
!ifdef HAVE_TMS9918 {
        +tmsColorFgBg FG, BG
        sta BASIC_COLOR
}
        lda #1
        sta BASIC_MODE

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

hbc56OpenFile:
	JSR	LAB_EVEX		; evaluate string, get length in A (and Y)
        lda     Dtypef
	bne +
        ldx #$02
        jmp LAB_XERR
+
        JSR	LAB_22B6        ; pop string off descriptor stack, or from top of string
                                ; space returns with A = length, X=pointer low byte,
                                ; Y=pointer high byte
        stx SAVE_X
        sty SAVE_Y
        tay
        lda #0
        sta (SAVE_X), y

        lda #SAVE_X
        sta $7f04               ; open file by name
        rts

; -----------------------------------------------------------------------------
; hybc56Load - EhBASIC load subroutine (for HBC-56)   (TBA)
; -----------------------------------------------------------------------------
hbc56Load
        jsr hbc56OpenFile

        ; save stack since NEW destroys it
        tsx
        inx
        lda $100,x
        sta SAVE_A
        inx
        lda $100,x
        sta SAVE_Y

        jsr LAB_1463    ; NEW

        ; restore stack
        lda SAVE_Y
        pha
        lda SAVE_A
        pha

        lda #3                          ;; how many newlines
        sta SAVE_A

        ; change input vector
        lda #<fread
        sta VEC_IN
        lda #>fread
        sta VEC_IN + 1

        ; change output vector
        lda #<nullOut
        sta VEC_OUT
        lda #>nullOut
        sta VEC_OUT + 1

        rts


; -----------------------------------------------------------------------------
; hybc56Save - EhBASIC save subroutine (for HBC-56)   (TBA)
; -----------------------------------------------------------------------------
hbc56Save
        jsr hbc56OpenFile

        ; change output vector
        lda #<fwrite
        sta VEC_OUT
        lda #>fwrite
        sta VEC_OUT + 1

        jsr     LAB_14BD        ; call list function


        lda $7f04               ; close file

        ; revert output vector
        lda #<hbc56Out
        sta VEC_OUT
        lda #>hbc56Out
        sta VEC_OUT + 1

        rts

nullOut:
        rts

fwrite:
        cmp #$0a
        bne +
        lda #$0d
        sta $7f05
        lda #$0a
+
        sta $7f05
        rts

fread:
        lda SAVE_A
        beq +
        dec SAVE_A
        lda #$0d
        sec
        rts
+

        lda $7f05               ; read byte from file
        bne +

        lda $7f04               ; close file

        +tmsConsolePrint "\n Ready\n"

        ; revert input vector
        lda #<hbc56In
        sta VEC_IN
        lda #>hbc56In
        sta VEC_IN + 1

        ; revert output vector
        lda #<hbc56Out
        sta VEC_OUT
        lda #>hbc56Out
        sta VEC_OUT + 1

        lda #$0d
+
        sec
        rts

; -----------------------------------------------------------------------------
; vector table - gets copied to VEC_CC in RAM
; -----------------------------------------------------------------------------
LAB_vec
    !word    hbc56In         ; check for break (Ctrl+C)
    !word    hbc56In            ; byte in from keyboard
    !word    hbc56Out           ; byte out to screen
    !word    hbc56Load          ; load vector for EhBASIC
    !word    hbc56Save          ; save vector for EhBASIC

END_CODE        ; so we know when to stop copying
