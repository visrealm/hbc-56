; HBC-56: Mandelbrot (64 x 48 multicolor mode)
;
; Originally from https://github.com/SlithyMatt/multi-mandlebrot
;
; Modified for ACME assembler and the HBC-56
;

!src "hbc56kernel.inc"

MAND_XMIN = $FFFD80 ; -2.5
MAND_XMAX = $000380 ; 3.5
MAND_YMIN = $FFFEB0 ; -1.3125
MAND_YMAX = $0002A0 ; 2.625

;MAND_XMIN = $000000 ; -2.5
;MAND_XMAX = $0000ff ; 3.5
;MAND_YMIN = $FFFF10 ; -1.3125
;MAND_YMAX = $0000ff ; 2.625

MAND_WIDTH = 64
MAND_HEIGHT = 48
MAND_MAX_IT = 16
MAND_MAX_PAL = MAND_MAX_IT + 1

TMP_COLOR = HBC56_USER_ZP_START
TMP_X     = HBC56_USER_ZP_START + 2
TMP_Y     = HBC56_USER_ZP_START + 5


!src "mandelbrot24.asm"
!src "palette.asm"

; -----------------------------------------------------------------------------
; HBC-56 Program Metadata
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "MANDELBROT 64X48"
        rts

; -----------------------------------------------------------------------------
; HBC-56 Program Entry
; -----------------------------------------------------------------------------
hbc56Main:
   sei

   jsr tmsModeMulticolor

   stz TMP_X - 1
   stz TMP_X
   stz TMP_X + 1
   stz TMP_Y - 1
   stz TMP_Y
   stz TMP_Y + 1

   +tmsSetColorFgBg TMS_BLACK, TMS_BLACK

   +tmsSetAddrNameTable
   +tmsSendData TMS_NAME_DATA, $300

   +tmsSetAddrPattTable
   +tmsSendDataRpt char, 8, 255

   +tmsEnableOutput
   +tmsDisableInterrupts

   +tmsSetAddrPattTable


@plot_loop:
   ;!byte $db
   jsr setPos
   jsr mand_get
   inc
   cmp #MAND_MAX_PAL
   bne @plotl
   lda #0
@plotl:
   tax
   lda palette,x
   asl
   asl
   asl
   asl
   sta TMP_COLOR
   inc TMP_X
   ;!byte $db
   jsr setPos
   jsr mand_get
   inc
   cmp #MAND_MAX_PAL
   bne @plot2
   lda #0
@plot2:
   tax
   lda palette,x
   ora TMP_COLOR

   sta TMS9918_RAM

   inc TMP_Y
   dec TMP_X
   lda TMP_Y
   and #$07
   bne +
   inc TMP_X
   inc TMP_X
   lda TMP_Y
   sec
   sbc #8
   sta TMP_Y
+
   ldx TMP_X
   cpx #MAND_WIDTH
   bne @plot_loop
   stz TMP_X
   lda TMP_Y
   clc
   adc #8
   sta TMP_Y

   cmp #MAND_HEIGHT
   bne @plot_loop

@loop:
   ; do something
   jmp @loop

setPos:
   lda TMP_X - 1
   sta MAND_X
   lda TMP_X
   sta MAND_X + 1
   lda TMP_X + 1
   sta MAND_X + 2
   lda TMP_Y - 1
   sta MAND_Y
   lda TMP_Y
   sta MAND_Y + 1
   lda TMP_Y + 1
   sta MAND_Y + 2
   rts

TMS_NAME_DATA:
!for .y, 0, 23 {
!for .x, 0, 31 {
        !byte .x + ((.y & $fc) << 3)
}
}

char:
!byte $00,$00,$00,$00,$00,$00,$00,$00
