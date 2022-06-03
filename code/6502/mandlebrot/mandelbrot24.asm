; HBC-56: Mandelbrot compute function
;
; Originally from https://github.com/SlithyMatt/multi-mandlebrot
;
; Modified for ACME assembler
;

!src "fixedpt24.asm"

MAND_X0     = HBC56_USER_ZP_START + 40
MAND_Y0     = HBC56_USER_ZP_START + 43
MAND_X      = HBC56_USER_ZP_START + 46
MAND_Y      = HBC56_USER_ZP_START + 49
MAND_X2     = HBC56_USER_ZP_START + 52
MAND_Y2     = HBC56_USER_ZP_START + 55
MAND_XTEMP  = HBC56_USER_ZP_START + 58

mand_get:   ; Input:
            ;  mand_x,mand_y - bitmap coordinates
            ; Output: A - # iterations executed (0 to mand_max_it-1)
   +FP_LDA MAND_X              ; A = X coordinate
   +FP_LDB_IMM MAND_XMAX       ; B = max scaled X - min scaled X
   jsr fp_multiply            ; C = A*B
   +FP_TCA                     ; A = C (X*Xmax)
   +FP_LDB_IMM_INT MAND_WIDTH  ; B = width
   jsr fp_divide              ; C = A/B
   +FP_TCA                     ; A = C (scaled X with zero min)
   +FP_LDB_IMM MAND_XMIN       ; B = min scaled X
   jsr fp_add                 ; C = A+B (scaled X)
   +FP_STC MAND_X0             ; x0 = C
   +FP_LDA MAND_Y              ; A = Y coordinate
   +FP_LDB_IMM MAND_YMAX       ; B = max scaled Y - min scaled Y
   jsr fp_multiply            ; C = A*B
   +FP_TCA                     ; A = C (Y*Ymax)
   +FP_LDB_IMM_INT MAND_HEIGHT ; B = height
   jsr fp_divide              ; C = A/B
   +FP_TCA                     ; A = C (scaled Y with zero min)
   +FP_LDB_IMM MAND_YMIN       ; B = min scaled Y
   jsr fp_add                 ; C = A+B (scaled Y)
   +FP_STC MAND_Y0             ; y0 = C

   stz MAND_X
   stz MAND_X+1
   stz MAND_X+2
   stz MAND_Y
   stz MAND_Y+1
   stz MAND_Y+2

   ldx #0            ; X = I (init to 0)
@loop:
   +FP_LDA MAND_X     ; A = X
   +FP_LDB MAND_X     ; B = X
   jsr fp_multiply   ; C = X^2
   +FP_STC MAND_X2
   +FP_LDA MAND_Y     ; A = Y
   +FP_LDB MAND_Y     ; B = Y
   jsr fp_multiply   ; C = Y^2
   +FP_STC MAND_Y2
   +FP_LDA MAND_X2    ; A = X^2
   +FP_TCB            ; B = Y^2
   jsr fp_add        ; C = X^2+Y^2
   lda FP_C+2
   beq @check4
   jmp @dec_i
@check4:
   lda FP_C+1
   sec
   sbc #4
   beq @check_fraction
   bmi @do_it
   jmp @dec_i
@check_fraction:
   lda FP_C
   beq @do_it
   jmp @dec_i
@do_it:
   jsr fp_subtract   ; C = X^2 - Y^2
   +FP_TCA            ; A = C (X^2 - Y^2)
   +FP_LDB MAND_X0    ; B = X0
   jsr fp_add        ; C = X^2 - Y^2 + X0
   +FP_STC MAND_XTEMP ; Xtemp = C
   +FP_LDA MAND_X     ; A = X
   asl FP_A
   rol FP_A+1
   rol FP_A+2        ; A = 2*X
   +FP_LDB MAND_Y     ; B = Y
   jsr fp_multiply   ; C = 2*X*Y
   +FP_TCA            ; A = C (2*X*Y)
   +FP_LDB MAND_Y0    ; B = Y0
   jsr fp_add        ; C = 2*X*Y + Y0
   +FP_STC MAND_Y     ; Y = C (2*X*Y + Y0)
   lda MAND_XTEMP
   sta MAND_X
   lda MAND_XTEMP+1
   sta MAND_X+1      ; X = Xtemp
   lda MAND_XTEMP+2
   sta MAND_X+2
   inx
   cpx #MAND_MAX_IT
   beq @dec_i
   jmp @loop
@dec_i:
   dex
   txa
   rts
