; HBC-56: Mandelbrot (256 x 192 GFXII)
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

MAND_WIDTH = 256
MAND_HEIGHT = 192
MAND_MAX_IT = 16
MAND_MAX_PAL = MAND_MAX_IT + 1

TMP_COLOR  = HBC56_USER_ZP_START
TMP_X      = HBC56_USER_ZP_START + 2
TMP_Y      = HBC56_USER_ZP_START + 5
TMP_COLORS = HBC56_USER_ZP_START + 8   ; 8 of these
TMP_I      = HBC56_USER_ZP_START + 16


!src "mandelbrot24.asm"
!src "palette.asm"

; -----------------------------------------------------------------------------
; HBC-56 Program Metadata
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "MANDELBROT GFXII"
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

   stz TMS_TMP_ADDRESS
   stz TMS_TMP_ADDRESS + 1

@plot_loop:
   stz TMP_I
@pixelLoop
   jsr setPos
   jsr mand_get
   inc
   cmp #MAND_MAX_PAL
   bne @plot
   lda #0
@plot:
   ldx TMP_I
   sta TMP_COLORS,x
   inc TMP_X
   inc TMP_I
   lda TMP_I
   cmp #8
   bne @pixelLoop

   ; TMP_COLORS contains 8 indexes
   ; we want to count the last position of the first color
   ; and use the last index as the rest
   ldx #0
   stx TMP_I
   lda TMP_COLORS
-
   cmp TMP_COLORS,x
   bne +
   stx TMP_I
+
   inx
   cpx #8
   bne -

   ; pattern address
   lda #$20
   tsb TMS_TMP_ADDRESS + 1
   jsr tmsSetAddressWrite

   ldx TMP_I
   lda tableBitsFromLeft,x
   ;lda #$f0
   +tmsPut

   ; color address
   lda #$20
   trb TMS_TMP_ADDRESS + 1
   jsr tmsSetAddressWrite

   ldx TMP_COLORS
   lda palette,x
   asl
   asl
   asl
   asl
   sta TMP_COLOR
   ldx TMP_COLORS + 7   
   lda palette,x
   ora TMP_COLOR

   ;!byte $db
   +tmsPut

   +inc16 TMS_TMP_ADDRESS

   inc TMP_Y
   lda TMP_Y
   and #$07

   ; end of block?
   beq .endOfBlock

   lda TMP_X
   sec
   sbc #8
   sta TMP_X

   jmp @plot_loop

.endOfBlock
   
   lda TMP_X
   beq .endOfRow

   lda TMP_Y
   sec
   sbc #8
   sta TMP_Y

   jmp @plot_loop

.endOfRow
   lda #0
   sta TMP_X
   lda TMP_Y
   cmp #MAND_HEIGHT
   beq @loop
   jmp @plot_loop

.notEndOfBlock
   lda TMP_X
   sec
   sbc #8
   sta TMP_X
   jmp @plot_loop

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
