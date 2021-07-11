; 6502 - Bitmap
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; Bitmap object has the following structure
;
; Width
; Height

; -------------------------
; Zero page
; -------------------------
PIX_ADDR   = $20
PIX_ADDR_L = PIX_ADDR
PIX_ADDR_H = PIX_ADDR + 1

BITMAP_ADDR_H   = $22

BITMAP_X       = $24
BITMAP_Y       = $25
BITMAP_X1      = BITMAP_X
BITMAP_Y1      = BITMAP_Y
BITMAP_X2      = $26
BITMAP_Y2      = $27
BITMAP_TMP1    = $28
BITMAP_TMP2    = $29



; -----------------------------------------------------------------------------
; bitmapClear: Clear the bitmap
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
; -----------------------------------------------------------------------------
bitmapClear:
	lda #0
	
	; flow through.... danger?
	
	
; -----------------------------------------------------------------------------
; bitmapFill: Fill the bitmap with value in A
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
; -----------------------------------------------------------------------------
bitmapFill:
	sta BITMAP_TMP1
	lda BITMAP_ADDR_H
	sta PIX_ADDR_H
	ldx #0
	stx PIX_ADDR_L

.fillLoop	
	ldy #0
	lda BITMAP_TMP1
	
.fillRowLoop

	sta (PIX_ADDR), y
	
	iny
	bne .fillRowLoop
	
	inc PIX_ADDR_H
	
	inx
	cpx #4
	bne .fillLoop
	
	rts
	


; -----------------------------------------------------------------------------
; bitmapLineH: Output a horizontal line
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X1: Start X position (0 to 127)
;  BITMAP_X2: End X position (0 to 127)
;  BITMAP_Y:  Y position (0 to 63)
; -----------------------------------------------------------------------------
bitmapHline:

	END_OFFSET   = BITMAP_Y2
	START_BYTE   = BITMAP_TMP1
	END_BYTE     = BITMAP_TMP2

	lda BITMAP_ADDR_H
	sta PIX_ADDR_H
	ldx #0
	stx PIX_ADDR_L
	
	lda BITMAP_Y
	lsr
	lsr
	lsr
	lsr
	clc
	adc PIX_ADDR_H
	sta PIX_ADDR_H
	
	lda BITMAP_Y
	and #$0f
	asl
	asl
	asl
	asl
	sta PIX_ADDR_L
	
	lda BITMAP_X1
	lsr
	lsr
	lsr
	tay	  ; Y contains start byte offset in row
	
	lda BITMAP_X2
	lsr
	lsr
	lsr
	sta END_OFFSET  ; END_OFFSET contains end byte offset within the row
	
	lda BITMAP_X1
	and #$07
	tax   ; X contains bit offset within byte (0 - 7)	
	
	lda #$ff
	
; shift the bits to the right for the pixel offset
-
	cpx #0
	beq +
	dex
	lsr    
	bcs -  ; carry is always set
+
	sta START_BYTE

	lda BITMAP_X2
	and #$07
	
	tax   ; X contains bit offset within byte (0 - 7)	
	
	lda #$ff
	
; shift the bits to the left for the pixel offset
-
	cpx #7
	beq +
	inx
	asl    
	bcs -  ; carry is always set
+
	sta END_BYTE
	
	lda START_BYTE
	cpy END_OFFSET
	bne +
	and END_BYTE  ; combine if within the same byte
	ora (PIX_ADDR), y
	sta (PIX_ADDR), y
	rts
+
	ora (PIX_ADDR), y
	sta (PIX_ADDR), y

-
	lda #$ff
	iny
	cpy END_OFFSET
	bne +
	and END_BYTE  ; combine if within the same byte
+
	ora (PIX_ADDR), y
	sta (PIX_ADDR), y
	cpy END_OFFSET
	bne -	
	
	rts