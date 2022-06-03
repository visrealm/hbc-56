; HBC-56: Mandelbrot (64 x 192 GFXII split mode)
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
MAND_HEIGHT = 192
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
        +setHbcMetaTitle "MANDELBROT GFX2H"
        rts

; -----------------------------------------------------------------------------
; HBC-56 Program Entry
; -----------------------------------------------------------------------------
hbc56Main:
   sei

   jsr tmsModeGraphicsII

   stz TMP_X - 1
   stz TMP_X
   stz TMP_X + 1
   stz TMP_Y - 1
   stz TMP_Y
   stz TMP_Y + 1

   +tmsSetColorFgBg TMS_BLACK, TMS_BLACK

   +tmsSetAddrNameTable
   +tmsSendDataRpt TMS_NAME_DATA, $100, 3

   +tmsSetAddrPattTable
   +tmsSendDataRpt patt, 8, 256
   +tmsSendDataRpt patt, 8, 256
   +tmsSendDataRpt patt, 8, 256

   +tmsSetAddrColorTable
   +tmsSendDataRpt col, 8, 256
   +tmsSendDataRpt col, 8, 256
   +tmsSendDataRpt col, 8, 256

   +tmsEnableOutput
   +tmsDisableInterrupts

   +tmsSetAddrColorTable


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
   stz MAND_X
   stz MAND_X + 2
   lda TMP_X
   sta MAND_X + 1

   stz MAND_Y
   stz MAND_Y + 2
   lda TMP_Y
   sta MAND_Y + 1
   rts

TMS_NAME_DATA:
!for i, 0, 255 {
         !byte i
}

patt:
!byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
col:
!byte $00,$00,$00,$00,$00,$00,$00,$00
