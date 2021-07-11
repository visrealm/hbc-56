; 6502 12864B LCD - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Prerequisites:
;  - lcd.asm


; -------------------------
; Constants
; -------------------------
LCD_CMD_12864B_EXTENDED 	 = $04

LCD_CMD_EXT_GRAPHICS_ENABLE  = $02

LCD_CMD_EXT_GRAPHICS_ADDR    = $80


; -------------------------
; Zero page
; -------------------------
PIX_ADDR   = $20
PIX_ADDR_L = PIX_ADDR
PIX_ADDR_H = PIX_ADDR + 1

IMG_ADDR_H   = $22

LCD_X       = $24
LCD_Y       = $25
LCD_X1      = LCD_X
LCD_Y1      = LCD_Y
LCD_X2      = $26
LCD_Y2      = $27
LCD_TMP1    = $28
LCD_TMP2    = $29

;---------------------------


; -----------------------------------------------------------------------------
; lcdHline: Output a horizontal line
; -----------------------------------------------------------------------------
; Inputs:
;  LCD_X1: Start X position (0 to 127)
;  LCD_X2: End X position (0 to 127)
;  LCD_Y:  Y position (0 to 63)
; -----------------------------------------------------------------------------
lcdHline:
	; if y position is in the lower half, then add 128 to X and subtract 32 from y
	lda LCD_Y
	cmp #32
	bcc +
	and #$1f	; subtract 32 from y
	sta LCD_Y
	lda LCD_X1
	ora #$80
	sta LCD_X1
	lda LCD_X2
	ora #$80
	sta LCD_X2
+
	; here, X1 and X2 are in the range 0-256 and Y 0-31
	
	
	rts
	
; -----------------------------------------------------------------------------
; lcdImage: Output a full-screen image from memory
; -----------------------------------------------------------------------------
; Inputs:
;  IMG_ADDR_H: Contains page-aligned address of 1-bit 128x64 image data
; -----------------------------------------------------------------------------
lcdImage:
	ldy #0
	ldx #0

.imageLoop:
	lda IMG_ADDR_H
	sta PIX_ADDR_H

	; set y address
	jsr lcdWait
	tya
	ora #LCD_CMD_EXT_GRAPHICS_ADDR
	sta LCD_CMD

	; set x address
	jsr lcdWait
	txa
	ora #LCD_CMD_EXT_GRAPHICS_ADDR
	sta LCD_CMD

	; first byte
	jsr lcdWait

!if cputype = $65c02 {
	phx
	phy
} else {
	txa
	pha
	tya
	pha
}
	cpx #8
	bcs +
	; upper half

	cpy #16
	bcc ++
	inc PIX_ADDR_H
	jmp ++

+

	; lower half
	inc PIX_ADDR_H
	inc PIX_ADDR_H

	cpy #16
	bcc ++
	inc PIX_ADDR_H

++

	; generate offset into image data based on lcd X/Y address
	tya
	and #$0f
	asl
	asl
	asl
	asl
	pha
	txa
	and #$07
	asl
	sta $02
	pla
	ora $02
	tay

	ldx #16
-
	lda (PIX_ADDR), y
	sta LCD_DATA

	jsr lcdWait

	iny
	dex
	bne -

!if cputype = $65c02 {
	plx
	ply
} else {
	pla
	tay
	pla
	tax
}

	txa
	clc
	adc #8
	tax
	
	cpx #16
	bne .imageLoop
	ldx #0
	iny
	cpy #32
	bne .imageLoop

	rts
	
	