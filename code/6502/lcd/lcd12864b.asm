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


LCD_BASIC           = LCD_INITIALIZE
LCD_EXTENDED        = LCD_INITIALIZE | LCD_CMD_12864B_EXTENDED

;---------------------------


; -----------------------------------------------------------------------------
; lcdGraphicsMode: Initialise the LCD graphics mode
; -----------------------------------------------------------------------------
lcdGraphicsMode:
	jsr lcdWait
	lda #LCD_EXTENDED
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_EXTENDED | LCD_CMD_EXT_GRAPHICS_ENABLE
	sta LCD_CMD
	rts



; -----------------------------------------------------------------------------
; lcdSetRow: Set LCD address to graphics row
; -----------------------------------------------------------------------------
; Inputs:
;  Y: Row of the LCD (0 - 63)
; -----------------------------------------------------------------------------
lcdGraphicsSetRow:
	pha

	; set y address (0 - 31)
	jsr lcdWait
	tya
	and #$1f  ; only want 0-31
	ora #LCD_CMD_EXT_GRAPHICS_ADDR
	sta LCD_CMD

	; set x address - either 0 or 8
	jsr lcdWait
	tya
	and #$20
	lsr
	lsr
	ora #LCD_CMD_EXT_GRAPHICS_ADDR
	sta LCD_CMD

	pla
	rts


!ifdef _GFX_BITMAP_A {


; -----------------------------------------------------------------------------
; lcdImage: Output a full-screen image from memory (XY upper-left)
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
	
	
; -----------------------------------------------------------------------------
; lcdImageVflip: Output a full-screen image from memory (XY lower-left)
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
; -----------------------------------------------------------------------------
lcdImageVflip:

	lda BITMAP_ADDR_H
	clc
	adc #3
	sta PIX_ADDR_H
	ldx #240
	stx PIX_ADDR_L
	ldx #0

.imageLoopV:

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
.imgRowLoopV
	jsr lcdWait
	
	lda (PIX_ADDR), y
	sta LCD_DATA
	
	iny
	cpy #16
	bne .imgRowLoopV
	
	lda PIX_ADDR_L
	sec
	sbc #16
	bcs +
	lda #240
	dec PIX_ADDR_H
+
	sta PIX_ADDR_L

	inx
	cpx #64
	bne .imageLoopV

	rts
	
} ; _GFX_BITMAP_A