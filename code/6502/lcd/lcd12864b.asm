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
;  IMG_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
; -----------------------------------------------------------------------------
lcdImage:

	lda IMG_ADDR_H
	sta PIX_ADDR_H
	ldx #0
	stx PIX_ADDR_L

.imageLoop:

	; x in the range 0-63

	; set y address
	jsr lcdWait
	txa
	and #$1f  ; only want 0-31
	ora #LCD_CMD_EXT_GRAPHICS_ADDR
	sta LCD_CMD

	; set x address - either 0 or 8
	jsr lcdWait
	txa
	and #$20
	lsr
	lsr
	ora #LCD_CMD_EXT_GRAPHICS_ADDR
	sta LCD_CMD


	ldy #0
.imgRowLoop
	jsr lcdWait
	
	lda (PIX_ADDR), y
	sta LCD_DATA
	
	iny
	cpy #16
	bne .imgRowLoop
	
	lda PIX_ADDR_L
	clc
	adc #16
	bcc +
	inc PIX_ADDR_H
+
	sta PIX_ADDR_L

	inx
	cpx #64
	bne .imageLoop

	rts
	
	