; HBC-56: Mandelbrot (32 x 24 character mode)
;
; Originally from https://github.com/SlithyMatt/multi-mandlebrot
;
; Modified for ACME assembler and the HBC-56
;

!src "hbc56kernel.inc"

MAND_XMIN = $FD80 ; -2.5
MAND_XMAX = $0380 ; 3.5
MAND_YMIN = $FF00 ; -1
MAND_YMAX = $0200 ; 2

MAND_WIDTH = 32
MAND_HEIGHT = 24
MAND_MAX_IT = 16
MAND_MAX_PAL = MAND_MAX_IT + 1

TMP         = HBC56_USER_ZP_START

!src "mandelbrot.asm"
!src "palette.asm"

; -----------------------------------------------------------------------------
; HBC-56 Program Metadata
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "MANDELBROT 32X24"
        rts

; -----------------------------------------------------------------------------
; HBC-56 Program Entry
; -----------------------------------------------------------------------------
hbc56Main:
   sei

   jsr tmsModeGraphicsI

   +tmsSetColorFgBg TMS_BLACK, TMS_BLACK

   +tmsSetAddrColorTable
   lda #0
-
   +tmsPut
   adc #$11
   bcc -
   lda #0
-
   +tmsPut
   adc #$11
   bcc -

   +tmsSetAddrPattTable
   +tmsSendDataRpt char, 8, 255


   +tmsEnableOutput
   +tmsDisableInterrupts

   +tmsSetAddrNameTable

   ldx #0
   ldy #0


@plot_loop:
   jsr mand_get
   inc
   cmp #MAND_MAX_PAL
   bmi @plot
   lda #0
@plot:
   phx
   tax
   lda palette,x
   plx
   asl
   asl
   asl
   sta TMS9918_RAM

   inx
   cpx #MAND_WIDTH
   bne @plot_loop
   ldx #0
   iny
   cpy #MAND_HEIGHT
   bne @plot_loop

@loop:
   ; do something
   jmp @loop

char:
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
