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
;  - bitmap.asm


; -------------------------
; Constants
; -------------------------
LCD_CMD_12864B_EXTENDED 	 = $04

LCD_CMD_EXT_GRAPHICS_ENABLE  = $02

LCD_CMD_EXT_GRAPHICS_ADDR    = $80


;---------------------------

	
; -----------------------------------------------------------------------------
; lcdImage: Output a full-screen image from memory
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
; -----------------------------------------------------------------------------
lcdImage:

	lda BITMAP_ADDR_H
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
	
	