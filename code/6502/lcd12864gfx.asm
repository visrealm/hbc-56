!to "lcd12864gfx.o", plain

!source "hbc56.asm"
!source "gfx/bitmap.asm"
!source "lcd/lcd.asm"
!source "lcd/lcd12864b.asm"

LCD_INITIALIZE      = LCD_CMD_FUNCTIONSET | LCD_CMD_8BITMODE | LCD_CMD_2LINE
LCD_BASIC           = LCD_INITIALIZE
LCD_EXTENDED        = LCD_INITIALIZE | LCD_CMD_12864B_EXTENDED

DISPLAY_MODE  = <(LCD_CMD_DISPLAY | LCD_CMD_DISPLAY_ON) ; | LCD_CMD_DISPLAY_CURSOR | LCD_CMD_DISPLAY_CURSOR_BLINK)

BUFFER_ADDR = $1000

main:

	jsr lcdWait
	lda #LCD_INITIALIZE
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_CMD_CLEAR
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_CMD_HOME
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_EXTENDED
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_EXTENDED | LCD_CMD_EXT_GRAPHICS_ENABLE
	sta LCD_CMD

start:

	lda #0
	sta PIX_ADDR_L
	
	lda #>BUFFER_ADDR
	sta BITMAP_ADDR_H
	
mainLoop:
	jsr bitmapClear
	jsr lcdImage
	
	lda #1
	sta BITMAP_X1
	lda #6
	sta BITMAP_X2
	lda #1
	sta BITMAP_Y
	jsr bitmapHline
	jsr lcdImage
	

	lda #3
	sta BITMAP_X1
	lda #12
	sta BITMAP_X2
	lda #3
	sta BITMAP_Y
	jsr bitmapHline
	jsr lcdImage


	lda #8
	sta BITMAP_X1
	lda #12
	sta BITMAP_X2
	lda #5
	sta BITMAP_Y
	jsr bitmapHline
	jsr lcdImage


	lda #12
	sta BITMAP_X1
	lda #92
	sta BITMAP_X2
	lda #7
	sta BITMAP_Y
	jsr bitmapHline
	jsr lcdImage

	lda #1
	sta BITMAP_X1
	lda #126
	sta BITMAP_X2
	lda #7
	sta BITMAP_Y
	jsr bitmapHline
	jsr lcdImage

	
	jmp mainLoop


longDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	; flow through


delay:
	ldx #255
	ldy #255
.loop:
	dex
	bne .loop 
	ldx #255
	dey
	bne .loop
	rts

